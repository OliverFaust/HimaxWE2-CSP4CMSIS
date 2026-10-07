override SCENARIO_APP_SUPPORT_LIST := $(APP_TYPE)

APPL_DEFINES += -DCSP4CMSIS_SHAKE_DETECTION
#APPL_DEFINES += -DIP_xdma
#APPL_DEFINES += -DEVT_DATAPATH

#APPL_DEFINES += -DEVT_CM55MTIMER -DEVT_CM55MMB
APPL_DEFINES += -DDBG_MORE

#EVENTHANDLER_SUPPORT = event_handler
#EVENTHANDLER_SUPPORT_LIST += evt_datapath

##
# library support feature
# Add new library here
# The source code should be loacted in ~\library\{lib_name}\
##
LIB_SEL = csp4cmsis
# CSP4CMSIS 3.0 on the SDK's CMSIS-RTOS2 adapter for FreeRTOS (OS_HAL := y below);
# static allocation is the default and the backend is detected from FreeRTOS.h
APPL_DEFINES += -DCSP4CMSIS_DEVICE_HEADER=\"WE2_device.h\"
# configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY in FreeRTOSConfig.h
APPL_DEFINES += -DCSP4CMSIS_MAX_SYSCALL_INTERRUPT_PRIORITY=5

#override OS_SEL := freertos
override OS_SEL := freertos_10_5_1
override OS_HAL := y
override MPU := n
override TRUSTZONE := y
override TRUSTZONE_TYPE := security
override TRUSTZONE_FW_TYPE := 1
override CIS_SEL := HM_COMMON
override EPII_USECASE_SEL := drv_onecore_cm55m_s


ifeq ($(strip $(TOOLCHAIN)), arm)
override LINKER_SCRIPT_FILE := $(SCENARIO_APP_ROOT)/$(APP_TYPE)/csp4cmsis_shake_detection.sct
else#TOOLChain
override LINKER_SCRIPT_FILE := $(SCENARIO_APP_ROOT)/$(APP_TYPE)/csp4cmsis_shake_detection.ld
endif

##
# Add new external device here
# The source code should be located in ~\external\{device_name}\
##
#EXT_DEV_LIST += 

