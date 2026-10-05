#include <cstdio>
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include "WE2_device.h"
#include "board.h"
#include "WE2_core.h"


#include "ethosu_driver.h"
#include "cvapp_kws.h"
#include "WE2_debug.h"

#include "TensorFlowLiteMicro.hpp"
#include "MicroNetKwsMfcc.hpp"
#include "AudioUtils.hpp"
#include "common_config.h"

#include "tensorflow/lite/micro/micro_mutable_op_resolver.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "tensorflow/lite/c/common.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"


#include "xprintf.h"
#include "spi_master_protocol.h"
#include "hx_drv_scu.h"
#include "csp4cmsis_spn.h"

#include "cmsis_os2.h"

#include <vector>
#include <functional>

#if KWS_MODEL_VELA

    #define frameLength 480
    #define frameStride 160
    #define threshold 0.7

    /*
    Model input is batch_size x kNumRows x kNumCols where 
        kNumRows = num of audio windows
        kNumCols = num of DCTFeatures
    */
    #define kNumCols 40
    #define kNumRows 98

#endif

#define KWS_DBG_APP_LOG 0

// #define EACH_STEP_TICK
#define TOTAL_STEP_TICK
uint32_t systick_1, systick_2;
uint32_t loop_cnt_1, loop_cnt_2;
#define CPU_CLK	0xffffff+1

static uint32_t capture_audio_tick = 0;
uint32_t g_kws_algo_tick = 0;
uint32_t g_kws_mfcc_ms = 0;
uint32_t g_kws_copy_ms = 0;
uint32_t g_kws_invoke_ms = 0;
uint32_t g_kws_postproc_ms = 0;

#ifdef TRUSTZONE_SEC
#define U55_BASE	BASE_ADDR_APB_U55_CTRL_ALIAS
#else
#ifndef TRUSTZONE
#define U55_BASE	BASE_ADDR_APB_U55_CTRL_ALIAS
#else
#define U55_BASE	BASE_ADDR_APB_U55_CTRL
#endif
#endif

using namespace std;

namespace {

// constexpr int tensor_arena_size = 134244;
constexpr int tensor_arena_size = 135244;

uint8_t tensor_arena[tensor_arena_size];

struct ethosu_driver ethosu_drv; /* Default Ethos-U device driver */
tflite::MicroInterpreter *kws_int_ptr=nullptr;
TfLiteTensor *kws_input, *kws_output;
};

struct MyClassificationResult {
    float normalisedVal = 0.f;
    std::string label;
    uint32_t labelIdx = 0;
};

std::vector<std::string> kwtLabels = {"_silence_", "_unknown_", "yes", "no", "up", "down", "left", "right", "on", "off", "stop", "go"};


static void _arm_npu_irq_handler(void)
{
    /* Call the default interrupt handler from the NPU driver */
    ethosu_irq_handler(&ethosu_drv);
}

/**
 * @brief  Initialises the NPU IRQ
 **/
static void _arm_npu_irq_init(void)
{
    const IRQn_Type ethosu_irqnum = (IRQn_Type)U55_IRQn;

    /* Register the EthosU IRQ handler in our vector table.
     * Note, this handler comes from the EthosU driver */
    EPII_NVIC_SetVector(ethosu_irqnum, (uint32_t)_arm_npu_irq_handler);

    /* Enable the IRQ */
    // An ISR that calls CSP4CMSIS or FreeRTOS must run at priority 5..7: at or
    // below CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY (5; 3 priority bits), so that
    // the RTOS's and the library's critical sections mask it. The SDK leaves it
    // at 0 (the highest). The NPU interrupt gives the FreeRTOS semaphore of the
    // Ethos-U override (ethosu_rtos_semaphore.c), so set it before enabling.
    NVIC_SetPriority(ethosu_irqnum, CSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY);
    NVIC_EnableIRQ(ethosu_irqnum);

}

static int _arm_npu_init(bool security_enable, bool privilege_enable)
{
    int err = 0;

    /* Initialise the IRQ */
    _arm_npu_irq_init();

    /* Initialise Ethos-U55 device */
#if TFLM2209_U55TAG2205
	const void * ethosu_base_address = (void *)(U55_BASE);
#else 
	void * const ethosu_base_address = (void *)(U55_BASE);
#endif

    if (0 != (err = ethosu_init(
                            &ethosu_drv,             /* Ethos-U driver device pointer */
                            ethosu_base_address,     /* Ethos-U NPU's base address. */
                            NULL,       /* Pointer to fast mem area - NULL for U55. */
                            0, /* Fast mem region size. */
							security_enable,                       /* Security enable. */
							privilege_enable))) {                   /* Privilege enable. */
    	xprintf("failed to initalise Ethos-U device\n");
            return err;
        }

    xprintf("Ethos-U55 device initialised\n");

    return 0;
}

int cv_kws_init(bool security_enable, bool privilege_enable, uint32_t model_addr) {

	int ercode = 0;

	//set memory allocation to tensor_arena
    // reserves block of memory and aligns it using a 32 bit uint for the memory block
	// tensor_arena = mm_reserve_align(tensor_arena_size,0x20); //1mb
	xprintf("TA[%x]\r\n",tensor_arena);


	if(_arm_npu_init(security_enable, privilege_enable)!=0)
		return -1;

	if (model_addr != 0) {
		static const tflite::Model*kws_model = tflite::GetModel((const void *)model_addr);

		if (kws_model->version() != TFLITE_SCHEMA_VERSION) {
			xprintf(
				"[ERROR] kws_model's schema version %d is not equal "
				"to supported version %d\n",
				kws_model->version(), TFLITE_SCHEMA_VERSION);
			return -1;
		}
		else {
			xprintf("kws model's schema version %d\n", kws_model->version());
		}

		static tflite::MicroErrorReporter kws_micro_error_reporter;
		static tflite::MicroMutableOpResolver<3> kws_op_resolver; //Change the number of operators based on what you add +1 for ethos-U

        kws_op_resolver.AddFullyConnected();
        kws_op_resolver.AddMul();
		if (kTfLiteOk != kws_op_resolver.AddEthosU()){
			xprintf("Failed to add Arm NPU support to op resolver.");
			return false;
		}
        else{
            xprintf("Arm NPU support added to op resolver.\n");
        }
		#if TFLM2209_U55TAG2205
            xprintf("MicroInterpreter kws_static_interpreter 1\n");
			static tflite::MicroInterpreter kws_static_interpreter(kws_model, kws_op_resolver,
					(uint8_t*)tensor_arena, tensor_arena_size, &kws_micro_error_reporter);
		#else
            xprintf("MicroInterpreter kws_static_interpreter 2\n");
			static tflite::MicroInterpreter kws_static_interpreter(kws_model, kws_op_resolver,
					(uint8_t*)tensor_arena, tensor_arena_size);  
		#endif  

		if(kws_static_interpreter.AllocateTensors()!= kTfLiteOk) {
			return false;
		}


		kws_int_ptr = &kws_static_interpreter;
		kws_input = kws_static_interpreter.input(0);
        kws_output = kws_static_interpreter.output(0);
	}

	xprintf("initial done\n");
	return ercode;
}

template<class T>
std::function<void (std::vector<int16_t>&, size_t, bool, size_t)>
FeatureCalc(TfLiteTensor* inputTensor, size_t cacheSize,
            std::function<std::vector<T> (std::vector<int16_t>& )> compute)
{
    /* Feature cache to be captured by lambda function. */
    static std::vector<std::vector<T>> featureCache = std::vector<std::vector<T>>(cacheSize);

    return [=](std::vector<int16_t>& audioDataWindow,
                                    size_t index,
                                    bool useCache,
                                    size_t featuresOverlapIndex)
    {
        T *tensorData = tflite::GetTensorData<T>(inputTensor);
        std::vector<T> features;

        /* Reuse features from cache if cache is ready and sliding windows overlap.
            * Overlap is in the beginning of sliding window with a size of a feature cache. */
        if (useCache && index < featureCache.size()) {
            features = std::move(featureCache[index]);
        } else {
            features = std::move(compute(audioDataWindow));
        }
        auto size = features.size();
        auto sizeBytes = sizeof(T) * size;
        std::memcpy(tensorData + (index * size), features.data(), sizeBytes);

        /* Start renewing cache as soon iteration goes out of the windows overlap. */
        if (index >= featuresOverlapIndex) {
            featureCache[index - featuresOverlapIndex] = std::move(features);
        }
    };
}

template std::function<void (std::vector<int16_t>&, size_t , bool, size_t)>
    FeatureCalc<int8_t>(TfLiteTensor* inputTensor,
                        size_t cacheSize,
                        std::function<std::vector<int8_t> (std::vector<int16_t>& )> compute);

template std::function<void (std::vector<int16_t>&, size_t , bool, size_t)>
    FeatureCalc<uint8_t>(TfLiteTensor* inputTensor,
                            size_t cacheSize,
                            std::function<std::vector<uint8_t> (std::vector<int16_t>& )> compute);

template std::function<void (std::vector<int16_t>&, size_t , bool, size_t)>
    FeatureCalc<int16_t>(TfLiteTensor* inputTensor,
                            size_t cacheSize,
                            std::function<std::vector<int16_t> (std::vector<int16_t>& )> compute);

template std::function<void(std::vector<int16_t>&, size_t, bool, size_t)>
    FeatureCalc<float>(TfLiteTensor* inputTensor,
                        size_t cacheSize,
                        std::function<std::vector<float>(std::vector<int16_t>&)> compute);



static std::function<void (std::vector<int16_t>&, int, bool, size_t)>
GetFeatureCalculator(arm::app::audio::MicroNetKwsMFCC& mfcc, TfLiteTensor* inputTensor, size_t cacheSize)
{
    std::function<void (std::vector<int16_t>&, size_t, bool, size_t)> mfccFeatureCalc;

    TfLiteQuantization quant = inputTensor->quantization;

    if (kTfLiteAffineQuantization == quant.type) {

        auto *quantParams = (TfLiteAffineQuantization *) quant.params;
        const float quantScale = quantParams->scale->data[0];
        const int quantOffset = quantParams->zero_point->data[0];

        switch (inputTensor->type) {
            case kTfLiteInt8: {
                mfccFeatureCalc = FeatureCalc<int8_t>(inputTensor,
                                                        cacheSize,
                                                        [=, &mfcc](std::vector<int16_t>& audioDataWindow) {
                                                            return mfcc.MfccComputeQuant<int8_t>(audioDataWindow,
                                                                                                quantScale,
                                                                                                quantOffset);
                                                        }
                );
                break;
            }
            case kTfLiteUInt8: {
                mfccFeatureCalc = FeatureCalc<uint8_t>(inputTensor,
                                                        cacheSize,
                                                        [=, &mfcc](std::vector<int16_t>& audioDataWindow) {
                                                            return mfcc.MfccComputeQuant<uint8_t>(audioDataWindow,
                                                                                                    quantScale,
                                                                                                    quantOffset);
                                                        }
                );
                break;
            }
            case kTfLiteInt16: {
                mfccFeatureCalc = FeatureCalc<int16_t>(inputTensor,
                                                        cacheSize,
                                                        [=, &mfcc](std::vector<int16_t>& audioDataWindow) {
                                                            return mfcc.MfccComputeQuant<int16_t>(audioDataWindow,
                                                                                                    quantScale,
                                                                                                    quantOffset);
                                                        }
                );
                break;
            }
            default:
                xprintf("Tensor type %s not supported\n", TfLiteTypeGetName(inputTensor->type));
        }


    } else {
        mfccFeatureCalc = mfccFeatureCalc = FeatureCalc<float>(inputTensor,
                                                                cacheSize,
                                                                [&mfcc](std::vector<int16_t>& audioDataWindow) {
                                                                    return mfcc.MfccCompute(audioDataWindow);
                                                                });
    }
    return mfccFeatureCalc;
}

void SetVectorResults(std::set<std::pair<float, uint32_t>>& topNSet,
                          std::vector<MyClassificationResult>& vecResults,
                          const std::vector <std::string>& labels)
    {

        /* Reset the iterator to the largest element - use reverse iterator. */

        auto topNIter = topNSet.rbegin();
        for (size_t i = 0; i < vecResults.size() && topNIter != topNSet.rend(); ++i, ++topNIter) {
            vecResults[i].normalisedVal = topNIter->first;
            vecResults[i].label = labels[topNIter->second];
            vecResults[i].labelIdx = topNIter->second;
        }
    }

bool GetTopNResults(const std::vector<float>& tensor,
                                    std::vector<MyClassificationResult>& vecResults,
                                    uint32_t topNCount,
                                    const std::vector <std::string>& labels)
    {

        std::set<std::pair<float , uint32_t>> sortedSet;

        /* NOTE: inputVec's size verification against labels should be
         *       checked by the calling/public function. */

        /* Set initial elements. */
        for (uint32_t i = 0; i < topNCount; ++i) {
            sortedSet.insert({tensor[i], i});
        }

        /* Initialise iterator. */
        auto setFwdIter = sortedSet.begin();

        /* Scan through the rest of elements with compare operations. */
        for (uint32_t i = topNCount; i < labels.size(); ++i) {
            if (setFwdIter->first < tensor[i]) {
                sortedSet.erase(*setFwdIter);
                sortedSet.insert({tensor[i], i});
                setFwdIter = sortedSet.begin();
            }
        }

        /* Final results' container. */
        vecResults = std::vector<MyClassificationResult>(topNCount);
        SetVectorResults(sortedSet, vecResults, labels);

        return true;
    }

bool  GetClassificationResults(
        TfLiteTensor* outputTensor,
        std::vector<MyClassificationResult>& vecResults,
        const std::vector <std::string>& labels,
        uint32_t topNCount,
        bool useSoftmax)
    {
        if (outputTensor == nullptr) {
            xprintf("Output vector is null pointer.\n");
            return false;
        }

        uint32_t totalOutputSize = 1;
        for (int inputDim = 0; inputDim < outputTensor->dims->size; inputDim++) {
            totalOutputSize *= outputTensor->dims->data[inputDim];
        }

        /* Sanity checks. */
        if (totalOutputSize < topNCount) {
            xprintf("Output vector is smaller than %d \n", topNCount);
            return false;
        } else if (totalOutputSize != labels.size()) {
            xprintf("Output size doesn't match the labels' size\n");
            return false;
        } else if (topNCount == 0) {
            xprintf("Top N results cannot be zero\n");
            return false;
        }

        bool resultState;
        vecResults.clear();

        /* De-Quantize Output Tensor */
        arm::app::QuantParams quantParams = arm::app::GetTensorQuantParams(outputTensor);

        /* Floating point tensor data to be populated
         * NOTE: The assumption here is that the output tensor size isn't too
         * big and therefore, there's neglibible impact on heap usage. */
        std::vector<float> tensorData(totalOutputSize);

        /* Populate the floating point buffer */
        switch (outputTensor->type) {
            case kTfLiteUInt8: {
                uint8_t *tensor_buffer = tflite::GetTensorData<uint8_t>(outputTensor);
                for (size_t i = 0; i < totalOutputSize; ++i) {
                    // printf("%d\n",tensor_buffer[i]);
                    tensorData[i] = quantParams.scale *
                        (static_cast<float>(tensor_buffer[i]) - quantParams.offset);
                }
                break;
            }
            case kTfLiteInt8: {
                int8_t *tensor_buffer = tflite::GetTensorData<int8_t>(outputTensor);
                for (size_t i = 0; i < totalOutputSize; ++i) {
                    // printf("%d\n",tensor_buffer[i]);
                    tensorData[i] = quantParams.scale *
                        (static_cast<float>(tensor_buffer[i]) - quantParams.offset);
                }
                break;
            }
            case kTfLiteFloat32: {
                float *tensor_buffer = tflite::GetTensorData<float>(outputTensor);
                for (size_t i = 0; i < totalOutputSize; ++i) {
                    // printf("%d\n",tensor_buffer[i]);
                    tensorData[i] = tensor_buffer[i];
                }
                break;
            }
            default:
                xprintf("Tensor type %s not supported by classifier\n",
                    TfLiteTypeGetName(outputTensor->type));
                return false;
        }

        if (useSoftmax) {
            arm::app::math::MathUtils::SoftmaxF32(tensorData);
        }

        /* Get the top N results. */
        resultState = GetTopNResults(tensorData, vecResults, topNCount, labels);

        if (!resultState) {
            xprintf("Failed to get top N results set\n");
            return false;
        }

        return true;
    }




int cv_kws_run(struct_kws_algoResult *algoresult_kws_pdm_record, int16_t *audio_buf, int32_t audio_clip_length, void (*callback)(void)) {

    int ercode = 0;

    if(kws_int_ptr != nullptr){

        #ifdef TOTAL_STEP_TICK
			SystemGetTick(&systick_1, &loop_cnt_1);
		#endif
		#ifdef EACH_STEP_TICK
			SystemGetTick(&systick_1, &loop_cnt_1);
		#endif

        #if KWS_DBG_APP_LOG
            printf("Initialized kNumCols: %d, kNumRows: %d\n", kNumCols, kNumRows);
        #endif

        arm::app::audio::MicroNetKwsMFCC mfcc = arm::app::audio::MicroNetKwsMFCC(kNumCols, frameLength);
        mfcc.Init();
        #if KWS_DBG_APP_LOG
            printf("MFCC initialized\n");
        #endif

        auto audioDataWindowSize = kNumRows * frameStride + (frameLength - frameStride);
        auto mfccWindowSize = frameLength;
        auto mfccWindowStride = frameStride;

        #if KWS_DBG_APP_LOG
            printf("Audio window size: %d, MFCC window size: %d, MFCC window stride: %d\n", 
                audioDataWindowSize, mfccWindowSize, mfccWindowStride);
        #endif


        auto audioDataStride = audioDataWindowSize/2;
        // printf("Initial audio data stride: %d\n", audioDataStride);

        if (0 != audioDataStride % mfccWindowStride) {
            audioDataStride -= audioDataStride % mfccWindowStride;
            // printf("Adjusted audio data stride: %d\n", audioDataStride);
        }

        auto nMfccVectorsInAudioStride = audioDataStride/mfccWindowStride;
        // printf("Number of MFCC vectors in audio stride: %d\n", nMfccVectorsInAudioStride);

        const float secondsPerSample = 1.0/arm::app::audio::MicroNetKwsMFCC::ms_defaultSamplingFreq;
        // printf("Seconds per sample: %f\n", secondsPerSample);

        arm::app::audio::SlidingWindow<const int16_t> audioMFCCWindowSlider(
            // audio_clip_arrays, audioDataWindowSize, mfccWindowSize, mfccWindowStride);
            audio_buf, audioDataWindowSize, mfccWindowSize, mfccWindowStride);

        #if KWS_DBG_APP_LOG
            xprintf("cvapp - Audio element [0] = %d\n", audio_buf[0]);
            xprintf("cvapp - Audio element [1] = %d\n", audio_buf[1]);
            xprintf("cvapp - Audio element [2] = %d\n", audio_buf[2]);
        #endif

        arm::app::audio::SlidingWindow<const int16_t> audioDataSlider(
            audio_buf, audio_clip_length, audioDataWindowSize, audioDataStride);

        // printf("Sliding windows initialized\n");

        auto numberOfReusedFeatureVectors = audioMFCCWindowSlider.TotalStrides() + 1 - nMfccVectorsInAudioStride;
        auto mfccFeatureCalc = GetFeatureCalculator(mfcc, kws_input, numberOfReusedFeatureVectors);
        // printf("Number of reused feature vectors: %d\n", numberOfReusedFeatureVectors);

        if (!mfccFeatureCalc){
            printf("Error: Failed to create feature calculator\n");
            return false;
        }
        #if KWS_DBG_APP_LOG
            printf("Feature calculator created successfully\n");
        #endif

        #ifdef EACH_STEP_TICK
			SystemGetTick(&systick_1, &loop_cnt_1);
		#endif

        // --- Split-tick profiling: reset per-call accumulators -------------
        // These are summed across every audioDataSlider window processed
        // inside this single cv_kws_run() call (there can be more than one
        // window per 1-second buffer), independent of EACH_STEP_TICK/
        // TOTAL_STEP_TICK. KwsProcess reads them once after this function
        // returns and folds them into its own periodic-stats report.
        g_kws_mfcc_ms = 0;
        g_kws_invoke_ms = 0;
        g_kws_postproc_ms = 0;

        while (audioDataSlider.HasNext()) {
            const int16_t *inferenceWindow = audioDataSlider.Next();
            audioMFCCWindowSlider.Reset(inferenceWindow);
            bool useCache = audioDataSlider.Index() > 0 && numberOfReusedFeatureVectors > 0;

            #if KWS_DBG_APP_LOG
                printf("audioDataSlider.Index(): %d", audioDataSlider.Index());
                printf("Use cache: %s\n", useCache ? "true" : "false");
            #endif

            // ms-based measurement, consistent with invoke's. mfcc never blocks
            // so the raw cycle-count trick would have been fine here too, but
            // keeping the same measurement method for all three phases avoids
            // mixing units in the ledger and keeps this code simple to compare
            // against the buffer-assembly/DMA-wait timing added in KwsProcess.
            uint32_t mfccStartTick = osKernelGetTickCount();
            while (audioMFCCWindowSlider.HasNext()) {
                const int16_t *mfccWindow = audioMFCCWindowSlider.Next();
                std::vector<int16_t> mfccAudioData = std::vector<int16_t>(mfccWindow, mfccWindow + mfccWindowSize);
                mfccFeatureCalc(mfccAudioData, audioMFCCWindowSlider.Index(), useCache, nMfccVectorsInAudioStride);
            }
            uint32_t mfccEndTick = osKernelGetTickCount();
            g_kws_mfcc_ms += ticksToMs(mfccEndTick - mfccStartTick);

            #ifdef EACH_STEP_TICK						
                SystemGetTick(&systick_2, &loop_cnt_2);
                dbg_printf(DBG_LESS_INFO,"Tick for creating MFCC from audio for Keyword Transformer KWS:[%d]\r\n",(loop_cnt_2-loop_cnt_1)*CPU_CLK+(systick_1-systick_2));							
            #endif

            #ifdef EACH_STEP_TICK
                SystemGetTick(&systick_1, &loop_cnt_1);
            #endif

            // Invoke() genuinely blocks the calling task until the Ethos-U55
            // IRQ fires and gives back the semaphore -- the raw SysTick/
            // CPU_CLK cycle-counting trick used elsewhere in this function
            // is NOT safe across that kind of wait (it wrapped to ~UINT32_MAX
            // in testing, consistent with FreeRTOS tickless idle reprogramming
            // SysTick's reload value, or a torn read racing the NPU IRQ, right
            // at this exact boundary). osKernelGetTickCount() is the RTOS-
            // supported way to measure elapsed time across a blocking wait.
            uint32_t invokeStartTick = osKernelGetTickCount();
            TfLiteStatus invoke_status = kws_int_ptr->Invoke();
            if(invoke_status != kTfLiteOk) {
                printf("kws detect invoke fail\n");
                return -1;
            }
            uint32_t invokeEndTick = osKernelGetTickCount();
            g_kws_invoke_ms += ticksToMs(invokeEndTick - invokeStartTick);
            #if KWS_DBG_APP_LOG
            else {
                printf("kws detect invoke pass\n");
            }
            #endif

            #ifdef EACH_STEP_TICK
                SystemGetTick(&systick_2, &loop_cnt_2);
            #endif
            // 

            #ifdef EACH_STEP_TICK
                dbg_printf(DBG_LESS_INFO,"Tick for Invoke for KWS:[%d]\r\n\n",(loop_cnt_2-loop_cnt_1)*CPU_CLK+(systick_1-systick_2));    
            #endif

            #ifdef EACH_STEP_TICK
                SystemGetTick(&systick_1, &loop_cnt_1);
            #endif

            uint32_t postprocStartTick = osKernelGetTickCount();
            std::vector<MyClassificationResult> vecResults;

            GetClassificationResults(kws_output, vecResults, kwtLabels, 1, true);
            // printf("Classification results obtained\n");

            // xprintf("-----------------------------------------------------------------------------\n");
            
            
	if(vecResults[0].normalisedVal >= threshold)
	{
	    // Handed to the ReporterProcess over a non-blocking channel; never
	    // stalls this loop on UART speed (see csp4cmsis_spn.cpp).
	    kws_report_detection(vecResults[0].label.c_str(),
			         static_cast<int>(vecResults[0].normalisedVal * 100),
			         vecResults[0].labelIdx);
	}
	else
	{
	    kws_report_none();
	}
            uint32_t postprocEndTick = osKernelGetTickCount();
            g_kws_postproc_ms += ticksToMs(postprocEndTick - postprocStartTick);

            // xprintf("-----------------------------------------------------------------------------\n");

            #ifdef EACH_STEP_TICK
                SystemGetTick(&systick_2, &loop_cnt_2);
                dbg_printf(DBG_LESS_INFO,"Tick for getting and printing classification results:[%d]\r\n\n",(loop_cnt_2-loop_cnt_1)*CPU_CLK+(systick_1-systick_2));    
            #endif
        }
        
	#ifdef TOTAL_STEP_TICK
	    SystemGetTick(&systick_2, &loop_cnt_2);
	    if (algoresult_kws_pdm_record != nullptr) {
		g_kws_algo_tick =
			(loop_cnt_2-loop_cnt_1)*CPU_CLK+(systick_1-systick_2);
	    }
	#endif

        #if KWS_DBG_APP_LOG
            printf("Audio processing completed\n");
        #endif

        return true;

    }

    SystemGetTick(&systick_1, &loop_cnt_1);

	
	SystemGetTick(&systick_2, &loop_cnt_2);
	capture_audio_tick = (loop_cnt_2-loop_cnt_1)*CPU_CLK+(systick_1-systick_2);	
	return ercode;

    if (callback) 
    {
    callback();
    }

}

/*******************************************************************************
 * Split preprocessing/inference path (current production pipeline).
 *
 * cv_kws_run() above recomputes the full 98-frame MFCC tensor from scratch on
 * every call and runs Invoke() immediately after -- simple, but it means the
 * ~13.6 ms of MFCC work sits squarely in the critical path ahead of every NPU
 * dispatch. The functions below instead maintain a PERSISTENT feature tensor,
 * updated incrementally by 50 frames (one 0.5 s half-buffer's worth) per
 * call, so that a PreprocessingProcess can prepare the NEXT tensor while
 * InferenceProcess is still blocked inside the CURRENT Invoke() call -- the
 * same double-buffered-handoff pattern already used for whole audio windows,
 * just one level finer-grained.
 *
 * Frame arithmetic: one half-buffer is 8000 samples (0.5 s @ 16 kHz),
 * assembled from two paired 0.25 s DMA slots in AcquisitionProcess (see
 * csp4cmsis_spn.cpp) -- the PDM DMA transfer itself stays at 0.25 s per the
 * hx_drv_pdm_dma_lli_transfer <8192-byte limit.
 * With frameLength=480 and frameStride=160, that yields exactly
 * (320 + 8000 - 480) / 160 + 1 = 50 new frames per step, and 8000/160 = 50
 * exactly -- no remainder in either case, confirming the half-buffer sizing
 * lines up cleanly with the model's frame stride. The 320-sample tail is the
 * (frameLength - frameStride) samples of lookback the newest frames need from
 * the END of the PREVIOUS half-buffer; it is carried explicitly in
 * g_pp_tail rather than read across ring-buffer slot boundaries, to avoid
 * writing new wraparound-indexing logic (a class of bug this codebase has
 * been bitten by before).
 ******************************************************************************/

namespace {
    arm::app::audio::MicroNetKwsMFCC *g_pp_mfcc = nullptr;

    constexpr int32_t kPPFrameLength       = frameLength;                     // 480
    constexpr int32_t kPPFrameStride       = frameStride;                     // 160
    constexpr int32_t kPPTailSamples       = kPPFrameLength - kPPFrameStride; // 320
    constexpr int32_t kPPNewSamplesPerStep = 8000;                            // 0.5 s @ 16 kHz (was 4000 / 0.25 s)
    constexpr int32_t kPPNewFramesPerStep  = 50;                              // (320+8000-480)/160 + 1
    constexpr int32_t kPPWindowSamples     = kPPTailSamples + kPPNewSamplesPerStep; // 8320

    int16_t g_pp_tail[kPPTailSamples];
    // Counts up across the first 2 steps after (re)initialisation, then keeps
    // growing harmlessly forever; only ever compared against >= kNumRows, so
    // it does not need to be clamped once the window is fully populated.
    int32_t g_pp_frames_populated = 0;

    TfLiteType g_pp_tensor_type  = kTfLiteNoType;
    float      g_pp_quant_scale  = 1.0f;
    int        g_pp_quant_offset = 0;
    size_t     g_pp_tensor_bytes = 0;

    std::vector<uint8_t> g_pp_working;      // persistent; shifted + appended in place each step
    std::vector<uint8_t> g_pp_handoff[2];   // ping-ponged copies exposed to InferenceProcess
    int g_pp_handoff_slot = 0;
}

int cv_kws_preprocess_init() {
    if (kws_input == nullptr) {
        xprintf("Preprocessing init: model not initialised (call cv_kws_init first)\n");
        return -1;
    }

    g_pp_mfcc = new arm::app::audio::MicroNetKwsMFCC(kNumCols, frameLength);
    g_pp_mfcc->Init();

    g_pp_tensor_type  = kws_input->type;
    g_pp_tensor_bytes = kws_input->bytes;

    TfLiteQuantization quant = kws_input->quantization;
    if (kTfLiteAffineQuantization == quant.type) {
        auto *quantParams = (TfLiteAffineQuantization *) quant.params;
        g_pp_quant_scale  = quantParams->scale->data[0];
        g_pp_quant_offset = quantParams->zero_point->data[0];
    }

    g_pp_working.assign(g_pp_tensor_bytes, 0);
    g_pp_handoff[0].assign(g_pp_tensor_bytes, 0);
    g_pp_handoff[1].assign(g_pp_tensor_bytes, 0);
    std::memset(g_pp_tail, 0, sizeof(g_pp_tail));
    g_pp_frames_populated = 0;
    g_pp_handoff_slot = 0;

    xprintf("Preprocessing state initialised: tensor_bytes=%u type=%d\n",
            (unsigned)g_pp_tensor_bytes, (int)g_pp_tensor_type);
    return 0;
}

// Shifts the persistent working tensor down by kPPNewFramesPerStep rows and
// computes+appends that many new rows from window4320 (the 320-sample tail
// plus this step's 4000 new samples). Dispatches on the model's actual input
// tensor type, mirroring the same four-way switch cv_kws_run()'s
// GetFeatureCalculator() already performs for the monolithic path.
static void ShiftAndAppendFrames(const int16_t* window4320) {
    const int32_t oldRows = kNumRows - kPPNewFramesPerStep; // 48

    switch (g_pp_tensor_type) {
        case kTfLiteInt8: {
            int8_t* data = reinterpret_cast<int8_t*>(g_pp_working.data());
            std::memmove(data, data + kPPNewFramesPerStep*kNumCols, oldRows*kNumCols*sizeof(int8_t));
            for (int32_t f = 0; f < kPPNewFramesPerStep; ++f) {
                std::vector<int16_t> win(window4320+f*kPPFrameStride, window4320+f*kPPFrameStride+kPPFrameLength);
                std::vector<int8_t> feat = g_pp_mfcc->MfccComputeQuant<int8_t>(win, g_pp_quant_scale, g_pp_quant_offset);
                std::memcpy(data+(oldRows+f)*kNumCols, feat.data(), kNumCols*sizeof(int8_t));
            }
            break;
        }
        case kTfLiteUInt8: {
            uint8_t* data = reinterpret_cast<uint8_t*>(g_pp_working.data());
            std::memmove(data, data + kPPNewFramesPerStep*kNumCols, oldRows*kNumCols*sizeof(uint8_t));
            for (int32_t f = 0; f < kPPNewFramesPerStep; ++f) {
                std::vector<int16_t> win(window4320+f*kPPFrameStride, window4320+f*kPPFrameStride+kPPFrameLength);
                std::vector<uint8_t> feat = g_pp_mfcc->MfccComputeQuant<uint8_t>(win, g_pp_quant_scale, g_pp_quant_offset);
                std::memcpy(data+(oldRows+f)*kNumCols, feat.data(), kNumCols*sizeof(uint8_t));
            }
            break;
        }
        case kTfLiteInt16: {
            int16_t* data = reinterpret_cast<int16_t*>(g_pp_working.data());
            std::memmove(data, data + kPPNewFramesPerStep*kNumCols, oldRows*kNumCols*sizeof(int16_t));
            for (int32_t f = 0; f < kPPNewFramesPerStep; ++f) {
                std::vector<int16_t> win(window4320+f*kPPFrameStride, window4320+f*kPPFrameStride+kPPFrameLength);
                std::vector<int16_t> feat = g_pp_mfcc->MfccComputeQuant<int16_t>(win, g_pp_quant_scale, g_pp_quant_offset);
                std::memcpy(data+(oldRows+f)*kNumCols, feat.data(), kNumCols*sizeof(int16_t));
            }
            break;
        }
        case kTfLiteFloat32: {
            float* data = reinterpret_cast<float*>(g_pp_working.data());
            std::memmove(data, data + kPPNewFramesPerStep*kNumCols, oldRows*kNumCols*sizeof(float));
            for (int32_t f = 0; f < kPPNewFramesPerStep; ++f) {
                std::vector<int16_t> win(window4320+f*kPPFrameStride, window4320+f*kPPFrameStride+kPPFrameLength);
                std::vector<float> feat = g_pp_mfcc->MfccCompute(win);
                std::memcpy(data+(oldRows+f)*kNumCols, feat.data(), kNumCols*sizeof(float));
            }
            break;
        }
        default:
            xprintf("Preprocessing: unsupported input tensor type %d\n", (int)g_pp_tensor_type);
            break;
    }
}

void* cv_kws_preprocess_step(const int16_t *newQuarterBuffer) {
    static int16_t scratch[kPPWindowSamples];   // 8320 samples; static, not on the task's own stack

    if (g_pp_frames_populated > 0) {
        std::memcpy(scratch, g_pp_tail, kPPTailSamples * sizeof(int16_t));
    } else {
        // First-ever call after init: no real tail exists yet. Zero-fill;
        // these frames are discarded anyway (window isn't valid until the
        // 4th call), so this padding is never fed to the NPU.
        std::memset(scratch, 0, kPPTailSamples * sizeof(int16_t));
    }
    std::memcpy(scratch + kPPTailSamples, newQuarterBuffer, kPPNewSamplesPerStep * sizeof(int16_t));

    uint32_t t1 = osKernelGetTickCount();
    ShiftAndAppendFrames(scratch);
    uint32_t t2 = osKernelGetTickCount();
    g_kws_mfcc_ms = ticksToMs(t2 - t1);

    // Save the new tail for next time: the last kPPTailSamples of THIS step's
    // new audio (not the old tail).
    std::memcpy(g_pp_tail, newQuarterBuffer + (kPPNewSamplesPerStep - kPPTailSamples),
                kPPTailSamples * sizeof(int16_t));

    g_pp_frames_populated += kPPNewFramesPerStep;
    if (g_pp_frames_populated < kNumRows) {
        return nullptr;   // window not fully valid yet -- first 3 steps after (re)init
    }

    g_pp_handoff_slot ^= 1;
    std::memcpy(g_pp_handoff[g_pp_handoff_slot].data(), g_pp_working.data(), g_pp_tensor_bytes);
    return g_pp_handoff[g_pp_handoff_slot].data();
}

int cv_kws_infer_step(void *featureTensor) {
    if (kws_int_ptr == nullptr || featureTensor == nullptr) {
        return -1;
    }

    uint32_t t1 = osKernelGetTickCount();
    uint8_t *dst = tflite::GetTensorData<uint8_t>(kws_input);
    std::memcpy(dst, featureTensor, g_pp_tensor_bytes);
    uint32_t t2 = osKernelGetTickCount();
    g_kws_copy_ms = ticksToMs(t2 - t1);

    t1 = osKernelGetTickCount();
    TfLiteStatus invoke_status = kws_int_ptr->Invoke();
    t2 = osKernelGetTickCount();
    g_kws_invoke_ms = ticksToMs(t2 - t1);
    if (invoke_status != kTfLiteOk) {
        printf("kws detect invoke fail\n");
        return -1;
    }

    t1 = osKernelGetTickCount();
    std::vector<MyClassificationResult> vecResults;
    GetClassificationResults(kws_output, vecResults, kwtLabels, 1, true);

    if (vecResults[0].normalisedVal >= threshold) {
        kws_report_detection(vecResults[0].label.c_str(),
                              static_cast<int>(vecResults[0].normalisedVal * 100),
                              vecResults[0].labelIdx);
    } else {
        kws_report_none();
    }
    t2 = osKernelGetTickCount();
    g_kws_postproc_ms = ticksToMs(t2 - t1);

    return 0;
}

int cv_kws_deinit()
{
	return 0;
}
