:- dynamic parserVersionNum/1, parserVersionStr/1, parseResult/5.
:- dynamic module/4.
'parserVersionStr'('0.6.2.1').
'parseResult'('ok','',0,0,0).
:- dynamic channel/2, bindval/3, agent/3.
:- dynamic agent_curry/3, symbol/4.
:- dynamic dataTypeDef/2, subTypeDef/2, nameType/2.
:- dynamic cspTransparent/1.
:- dynamic cspPrint/1.
:- dynamic pragma/1.
:- dynamic comment/2.
:- dynamic assertBool/1, assertRef/5, assertTauPrio/6.
:- dynamic assertModelCheckExt/4, assertModelCheck/3.
:- dynamic assertLtl/4, assertCtl/4.
'parserVersionNum'([0,11,1,1]).
'parserVersionStr'('CSPM-Frontent-0.11.1.1').
'bindval'('MAX_INDEX','int'(3),'src_span'(6,1,6,14,367,13)).
'dataTypeDef'('prediction_t',['constructor'('person'),'constructor'('no_person')]).
'dataTypeDef'('source_t',['constructor'('camera'),'constructor'('inference')]).
'dataTypeDef'('thread_t',['constructor'('cam'),'constructor'('inf'),'constructor'('rep'),'constructor'('main_app')]).
'dataTypeDef'('report_t',['constructorC'('started','dotTupleType'(['source_t'])),'constructorC'('result','dotTupleType'(['setExp'('rangeClosed'('int'(0),'-'('val_of'('MAX_INDEX','src_span'(11,55,11,64,683,9)),'int'(1)))),'prediction_t'])),'constructorC'('stack','dotTupleType'(['thread_t']))]).
'channel'('g_trigger_chan','type'('dotUnitType')).
'channel'('frame_chan','type'('dotTupleType'(['setExp'('rangeClosed'('int'(0),'-'('val_of'('MAX_INDEX','src_span'(14,27,14,36,835,9)),'int'(1))))]))).
'channel'('report_chan','type'('dotTupleType'(['report_t']))).
'channel'('camera_log','type'('dotUnitType')).
'channel'('stack_tick','type'('dotUnitType')).
'channel'('line','type'('dotTupleType'(['report_t']))).
'bindval'('ENV','prefix'('src_span'(22,7,22,21,1450,14),[],'g_trigger_chan','val_of'('ENV','src_span'(22,25,22,28,1468,3)),'src_span'(22,22,22,24,1464,21)),'src_span'(22,1,22,28,1444,27)).
'bindval'('Camera','prefix'('src_span'(25,10,25,20,1576,10),[],'camera_log','prefix'('src_span'(25,24,25,35,1590,11),['out'('dotTuple'(['started','camera']))],'report_chan','agent_call'('src_span'(25,54,25,64,1620,10),'CameraLoop',['int'(0)]),'src_span'(25,51,25,53,1616,32)),'src_span'(25,21,25,23,1586,57)),'src_span'(25,1,25,67,1567,66)).
'agent'('CameraLoop'(_c),'prefix'('src_span'(26,17,26,31,1650,14),[],'g_trigger_chan','prefix'('src_span'(26,35,26,45,1668,10),['out'(_c)],'frame_chan','agent_call'('src_span'(26,51,26,61,1684,10),'CameraLoop',['%'('+'(_c,'int'(1)),'val_of'('MAX_INDEX','src_span'(26,72,26,81,1705,9)))]),'src_span'(26,48,26,50,1680,37)),'src_span'(26,32,26,34,1664,65)),'src_span'(26,17,26,82,1650,65)).
'bindval'('Inference','prefix'('src_span'(30,13,30,23,1913,10),['in'(_f)],'frame_chan','prefix'('src_span'(30,29,30,40,1929,11),['out'('dotTuple'(['started','inference']))],'report_chan','agent_call'('src_span'(30,62,30,67,1962,5),'Infer',[_f]),'src_span'(30,59,30,61,1958,30)),'src_span'(30,26,30,28,1925,47)),'src_span'(30,1,30,70,1901,69)).
'agent'('Infer'(_f2),'|~|'('prefix'('src_span'(31,14,31,25,1984,11),['out'('dotTuple'(['result',_f2,'person']))],'report_chan','val_of'('Next','src_span'(31,45,31,49,2015,4)),'src_span'(31,42,31,44,2011,24)),'prefix'('src_span'(31,56,31,67,2026,11),['out'('dotTuple'(['result',_f2,'no_person']))],'report_chan','val_of'('Next','src_span'(31,90,31,94,2060,4)),'src_span'(31,87,31,89,2056,27)),'src_span_operator'('no_loc_info_available','src_span'(31,51,31,54,2021,3))),'no_loc_info_available').
'bindval'('Next','prefix'('src_span'(32,13,32,23,2078,10),['in'(_f3)],'frame_chan','agent_call'('src_span'(32,29,32,34,2094,5),'Infer',[_f3]),'src_span'(32,26,32,28,2090,14)),'src_span'(32,1,32,37,2066,36)).
'bindval'('MainApp','prefix'('src_span'(36,11,36,21,2260,10),[],'stack_tick','prefix'('src_span'(36,25,36,36,2274,11),['out'('dotTuple'(['stack','cam']))],'report_chan','prefix'('src_span'(36,50,36,61,2299,11),['out'('dotTuple'(['stack','inf']))],'report_chan','prefix'('src_span'(37,11,37,22,2334,11),['out'('dotTuple'(['stack','rep']))],'report_chan','prefix'('src_span'(37,36,37,47,2359,11),['out'('dotTuple'(['stack','main_app']))],'report_chan','val_of'('MainApp','src_span'(37,66,37,73,2389,7)),'src_span'(37,63,37,65,2385,26)),'src_span'(37,33,37,35,2355,51)),'src_span'(36,72,37,10,2320,86)),'src_span'(36,47,36,49,2295,111)),'src_span'(36,22,36,24,2270,136)),'src_span'(36,1,37,73,2250,146)).
'bindval'('Reporter','prefix'('src_span'(40,12,40,23,2489,11),['in'(_r)],'report_chan','prefix'('src_span'(40,29,40,33,2506,4),['out'(_r)],'line','val_of'('Reporter','src_span'(40,39,40,47,2516,8)),'src_span'(40,36,40,38,2512,14)),'src_span'(40,26,40,28,2502,24)),'src_span'(40,1,40,47,2478,46)).
'bindval'('WRITERS','|||'('sharing'('closure'(['frame_chan']),'val_of'('Camera','src_span'(42,12,42,18,2537,6)),'val_of'('Inference','src_span'(42,42,42,51,2567,9)),'src_span'(42,19,42,41,2544,22)),'val_of'('MainApp','src_span'(42,57,42,64,2582,7)),'src_span_operator'('no_loc_info_available','src_span'(42,53,42,56,2578,3))),'src_span'(42,1,42,64,2526,63)).
'bindval'('NETWORK','sharing'('closure'(['report_chan']),'val_of'('WRITERS','src_span'(43,11,43,18,2600,7)),'val_of'('Reporter','src_span'(43,43,43,51,2632,8)),'src_span'(43,19,43,42,2608,23)),'src_span'(43,1,43,51,2590,50)).
'bindval'('SYSTEM','sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(44,11,44,14,2651,3)),'val_of'('NETWORK','src_span'(44,42,44,49,2682,7)),'src_span'(44,15,44,41,2655,26)),'src_span'(44,1,44,49,2641,48)).
'bindval'('INTERNAL','closure'(['g_trigger_chan','frame_chan','report_chan','stack_tick']),'src_span'(46,1,46,69,2691,68)).
'bindval'('CONSOLE_PIPE','\x5c\'('val_of'('SYSTEM','src_span'(50,16,50,22,2954,6)),'agent_call'('src_span'(50,25,50,30,2963,5),'union',['val_of'('INTERNAL','src_span'(50,31,50,39,2969,8)),'closure'(['dotTuple'(['line','stack'])])]),'src_span_operator'('no_loc_info_available','src_span'(50,23,50,24,2961,1))),'src_span'(50,1,50,58,2939,57)).
'bindval'('SPEC_PIPE','prefix'('src_span'(51,14,51,24,3010,10),[],'camera_log','prefix'('src_span'(51,28,51,32,3024,4),['out'('dotTuple'(['started','camera']))],'line','prefix'('src_span'(51,51,51,55,3047,4),['out'('dotTuple'(['started','inference']))],'line','agent_call'('src_span'(51,77,51,84,3073,7),'RESULTS',['int'(0)]),'src_span'(51,74,51,76,3069,32)),'src_span'(51,48,51,50,3043,55)),'src_span'(51,25,51,27,3020,73)),'src_span'(51,1,51,87,2997,86)).
'agent'('RESULTS'(_f4),'repInternalChoice'(['comprehensionGenerator'(_p,'prediction_t')],'prefix'('src_span'(52,37,52,41,3120,4),['out'('dotTuple'(['result',_f4,_p]))],'line','agent_call'('src_span'(52,56,52,63,3139,7),'RESULTS',['%'('+'(_f4,'int'(1)),'val_of'('MAX_INDEX','src_span'(52,74,52,83,3157,9)))]),'src_span'(52,53,52,55,3135,43)),'src_span'(52,18,52,36,3101,18)),'src_span'(52,14,52,84,3097,70)).
'bindval'('CONSOLE_STACK','\x5c\'('val_of'('SYSTEM','src_span'(55,17,55,23,3279,6)),'agent_call'('src_span'(55,26,55,30,3288,4),'diff',['Events','closure'(['dotTuple'(['line','stack'])])]),'src_span_operator'('no_loc_info_available','src_span'(55,24,55,25,3286,1))),'src_span'(55,1,55,56,3263,55)).
'bindval'('SPEC_STACK','prefix'('src_span'(56,14,56,18,3332,4),['out'('dotTuple'(['stack','cam']))],'line','prefix'('src_span'(56,32,56,36,3350,4),['out'('dotTuple'(['stack','inf']))],'line','prefix'('src_span'(56,50,56,54,3368,4),['out'('dotTuple'(['stack','rep']))],'line','prefix'('src_span'(56,68,56,72,3386,4),['out'('dotTuple'(['stack','main_app']))],'line','val_of'('SPEC_STACK','src_span'(56,91,56,101,3409,10)),'src_span'(56,88,56,90,3405,29)),'src_span'(56,65,56,67,3382,47)),'src_span'(56,47,56,49,3364,65)),'src_span'(56,29,56,31,3346,83)),'src_span'(56,1,56,101,3319,100)).
'assertModelCheckExt'('False','val_of'('SYSTEM','src_span'(58,8,58,14,3428,6)),'DeadlockFree','F').
'assertModelCheck'('False','val_of'('SYSTEM','src_span'(59,8,59,14,3463,6)),'LivelockFree').
'assertRef'('False','val_of'('SPEC_PIPE','src_span'(60,8,60,17,3496,9)),'Trace','val_of'('CONSOLE_PIPE','src_span'(60,23,60,35,3511,12)),'src_span'(60,1,60,35,3489,34)).
'assertRef'('False','val_of'('SPEC_PIPE','src_span'(61,8,61,17,3531,9)),'Failure','val_of'('CONSOLE_PIPE','src_span'(61,23,61,35,3546,12)),'src_span'(61,1,61,35,3524,34)).
'assertRef'('False','val_of'('SPEC_STACK','src_span'(62,8,62,18,3566,10)),'Trace','val_of'('CONSOLE_STACK','src_span'(62,23,62,36,3581,13)),'src_span'(62,1,62,36,3559,35)).
'assertRef'('False','val_of'('SPEC_STACK','src_span'(63,8,63,18,3602,10)),'Failure','val_of'('CONSOLE_STACK','src_span'(63,23,63,36,3617,13)),'src_span'(63,1,63,36,3595,35)).
'bindval'('InferenceStall','prefix'('src_span'(67,19,67,29,3824,10),['in'(_f5)],'frame_chan','prefix'('src_span'(67,35,67,46,3840,11),['out'('dotTuple'(['started','inference']))],'report_chan','|~|'('prefix'('src_span'(68,21,68,32,3893,11),['out'('dotTuple'(['result',_f5,'person']))],'report_chan','stop'('src_span'(68,52,68,56,3924,4)),'src_span'(68,49,68,51,3920,24)),'prefix'('src_span'(68,63,68,74,3935,11),['out'('dotTuple'(['result',_f5,'no_person']))],'report_chan','stop'('src_span'(68,97,68,101,3969,4)),'src_span'(68,94,68,96,3965,27)),'src_span_operator'('no_loc_info_available','src_span'(68,58,68,61,3930,3))),'src_span'(67,65,68,18,3869,124)),'src_span'(67,32,67,34,3836,141)),'src_span'(67,1,68,103,3806,169)).
'bindval'('SYSTEM_STALL','sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(69,16,69,19,3991,3)),'sharing'('closure'(['report_chan']),'|||'('sharing'('closure'(['frame_chan']),'val_of'('Camera','src_span'(70,8,70,14,4029,6)),'val_of'('InferenceStall','src_span'(70,38,70,52,4059,14)),'src_span'(70,15,70,37,4036,22)),'val_of'('MainApp','src_span'(70,58,70,65,4079,7)),'src_span_operator'('no_loc_info_available','src_span'(70,54,70,57,4075,3))),'val_of'('Reporter','src_span'(70,91,70,99,4112,8)),'src_span'(70,67,70,90,4088,23)),'src_span'(69,20,69,46,3995,26)),'src_span'(69,1,70,100,3976,145)).
'bindval'('CONSOLE_STACK_STALL','\x5c\'('val_of'('SYSTEM_STALL','src_span'(71,23,71,35,4144,12)),'agent_call'('src_span'(71,38,71,42,4159,4),'diff',['Events','closure'(['dotTuple'(['line','stack'])])]),'src_span_operator'('no_loc_info_available','src_span'(71,36,71,37,4157,1))),'src_span'(71,1,71,68,4122,67)).
'assertModelCheckExt'('False','val_of'('SYSTEM_STALL','src_span'(73,8,73,20,4198,12)),'DeadlockFree','F').
'assertRef'('False','val_of'('SPEC_STACK','src_span'(74,8,74,18,4239,10)),'Failure','val_of'('CONSOLE_STACK_STALL','src_span'(74,23,74,42,4254,19)),'src_span'(74,1,74,42,4232,41)).
'comment'('lineComment'('-- Neurochannel (csp4cmsis_allon_sensor_tflm): Camera -> Inference -> Reporter, plus MainApp.'),'src_position'(1,1,0,93)).
'comment'('lineComment'('-- The Reporter is the only process that prints while the network runs. Camera, Inference and'),'src_position'(2,1,94,93)).
'comment'('lineComment'('-- MainApp send it reports over one rendezvous channel with three writers; MainApp sends one'),'src_position'(3,1,188,92)).
'comment'('lineComment'('-- stack report per thread on its own timer (every 3 s), whatever the pipeline does.'),'src_position'(4,1,281,84)).
'comment'('lineComment'('-- frame indices 0..2 (wrapping), enough to check order'),'src_position'(6,48,414,55)).
'comment'('lineComment'('-- whose stack'),'src_position'(10,58,614,14)).
'comment'('lineComment'('-- frame-ready interrupt -> Camera'),'src_position'(13,48,774,34)).
'comment'('lineComment'('-- Camera -> Inference (rendezvous)'),'src_position'(14,48,856,35)).
'comment'('lineComment'('-- Camera, Inference, MainApp -> Reporter (rendezvous, three writers)'),'src_position'(15,48,939,69)).
'comment'('lineComment'('-- the camera driver\x27\s start-up log'),'src_position'(16,48,1056,35)).
'comment'('lineComment'('-- MainApp\x27\s timer (3 s)'),'src_position'(17,48,1139,24)).
'comment'('lineComment'('-- the Reporter\x27\s lines (print is a CSP-M keyword)'),'src_position'(18,48,1211,50)).
'comment'('lineComment'('-- The frame-ready interrupt. Camera re-arms the capture only after it has read a trigger,'),'src_position'(20,1,1263,90)).
'comment'('lineComment'('-- so at most one trigger is pending: the one-slot buffer behaves like a rendezvous here.'),'src_position'(21,1,1354,89)).
'comment'('lineComment'('-- Camera: the driver prints its start-up log, then Camera reports Started (and never again).'),'src_position'(24,1,1473,93)).
'comment'('lineComment'('-- Inference: initialises the model only after the first frame (i.e. after Camera started),'),'src_position'(28,1,1717,91)).
'comment'('lineComment'('-- then reports one result per frame. The prediction depends on the image: internal choice.'),'src_position'(29,1,1809,91)).
'comment'('lineComment'('-- MainApp: on every timer tick, one stack report per process (InParallel order) and one for'),'src_position'(34,1,2104,92)).
'comment'('lineComment'('-- itself, over its own writer end. It never prints.'),'src_position'(35,1,2197,52)).
'comment'('lineComment'('-- Reporter: receives any report and prints it as one line. No state, no timer.'),'src_position'(39,1,2398,79)).
'comment'('lineComment'('-- Pipeline view of the console (stack lines hidden): the camera driver\x27\s log, Camera\x27\s and'),'src_position'(48,1,2761,91)).
'comment'('lineComment'('-- Inference\x27\s Started lines, then exactly one result line per frame, in frame order.'),'src_position'(49,1,2853,85)).
'comment'('lineComment'('-- Stack view of the console (only stack lines visible): complete groups, in order, for ever.'),'src_position'(54,1,3169,93)).
'comment'('lineComment'('-- Stall: Inference stops for ever after its first result (as in the board\x27\s stall test).'),'src_position'(65,1,3632,89)).
'comment'('lineComment'('-- The pipeline stops, the stack report goes on: no deadlock, stack view unchanged.'),'src_position'(66,1,3722,83)).
'symbol'('MAX_INDEX','MAX_INDEX','src_span'(6,1,6,10,367,9),'Ident (Groundrep.)').
'symbol'('prediction_t','prediction_t','src_span'(8,10,8,22,480,12),'Datatype').
'symbol'('person','person','src_span'(8,25,8,31,495,6),'Constructor of Datatype').
'symbol'('no_person','no_person','src_span'(8,34,8,43,504,9),'Constructor of Datatype').
'symbol'('source_t','source_t','src_span'(9,10,9,18,523,8),'Datatype').
'symbol'('camera','camera','src_span'(9,25,9,31,538,6),'Constructor of Datatype').
'symbol'('inference','inference','src_span'(9,34,9,43,547,9),'Constructor of Datatype').
'symbol'('thread_t','thread_t','src_span'(10,10,10,18,566,8),'Datatype').
'symbol'('cam','cam','src_span'(10,25,10,28,581,3),'Constructor of Datatype').
'symbol'('inf','inf','src_span'(10,31,10,34,587,3),'Constructor of Datatype').
'symbol'('rep','rep','src_span'(10,37,10,40,593,3),'Constructor of Datatype').
'symbol'('main_app','main_app','src_span'(10,43,10,51,599,8),'Constructor of Datatype').
'symbol'('report_t','report_t','src_span'(11,10,11,18,638,8),'Datatype').
'symbol'('started','started','src_span'(11,25,11,32,653,7),'Constructor of Datatype').
'symbol'('result','result','src_span'(11,44,11,50,672,6),'Constructor of Datatype').
'symbol'('stack','stack','src_span'(11,83,11,88,711,5),'Constructor of Datatype').
'symbol'('g_trigger_chan','g_trigger_chan','src_span'(13,9,13,23,735,14),'Channel').
'symbol'('frame_chan','frame_chan','src_span'(14,9,14,19,817,10),'Channel').
'symbol'('report_chan','report_chan','src_span'(15,9,15,20,900,11),'Channel').
'symbol'('camera_log','camera_log','src_span'(16,9,16,19,1017,10),'Channel').
'symbol'('stack_tick','stack_tick','src_span'(17,9,17,19,1100,10),'Channel').
'symbol'('line','line','src_span'(18,9,18,13,1172,4),'Channel').
'symbol'('ENV','ENV','src_span'(22,1,22,4,1444,3),'Ident (Groundrep.)').
'symbol'('Camera','Camera','src_span'(25,1,25,7,1567,6),'Ident (Groundrep.)').
'symbol'('CameraLoop','CameraLoop','src_span'(26,1,26,11,1634,10),'Funktion or Process').
'symbol'('c','c','src_span'(26,12,26,13,1645,1),'Ident (Prolog Variable)').
'symbol'('Inference','Inference','src_span'(30,1,30,10,1901,9),'Ident (Groundrep.)').
'symbol'('f','f','src_span'(30,24,30,25,1924,1),'Ident (Prolog Variable)').
'symbol'('Infer','Infer','src_span'(31,1,31,6,1971,5),'Funktion or Process').
'symbol'('f2','f','src_span'(31,7,31,8,1977,1),'Ident (Prolog Variable)').
'symbol'('Next','Next','src_span'(32,1,32,5,2066,4),'Ident (Groundrep.)').
'symbol'('f3','f','src_span'(32,24,32,25,2089,1),'Ident (Prolog Variable)').
'symbol'('MainApp','MainApp','src_span'(36,1,36,8,2250,7),'Ident (Groundrep.)').
'symbol'('Reporter','Reporter','src_span'(40,1,40,9,2478,8),'Ident (Groundrep.)').
'symbol'('r','r','src_span'(40,24,40,25,2501,1),'Ident (Prolog Variable)').
'symbol'('WRITERS','WRITERS','src_span'(42,1,42,8,2526,7),'Ident (Groundrep.)').
'symbol'('NETWORK','NETWORK','src_span'(43,1,43,8,2590,7),'Ident (Groundrep.)').
'symbol'('SYSTEM','SYSTEM','src_span'(44,1,44,7,2641,6),'Ident (Groundrep.)').
'symbol'('INTERNAL','INTERNAL','src_span'(46,1,46,9,2691,8),'Ident (Groundrep.)').
'symbol'('CONSOLE_PIPE','CONSOLE_PIPE','src_span'(50,1,50,13,2939,12),'Ident (Groundrep.)').
'symbol'('union','union','src_span'(50,25,50,30,2963,5),'BuiltIn primitive').
'symbol'('SPEC_PIPE','SPEC_PIPE','src_span'(51,1,51,10,2997,9),'Ident (Groundrep.)').
'symbol'('RESULTS','RESULTS','src_span'(52,1,52,8,3084,7),'Funktion or Process').
'symbol'('f4','f','src_span'(52,9,52,10,3092,1),'Ident (Prolog Variable)').
'symbol'('p','p','src_span'(52,18,52,19,3101,1),'Ident (Prolog Variable)').
'symbol'('CONSOLE_STACK','CONSOLE_STACK','src_span'(55,1,55,14,3263,13),'Ident (Groundrep.)').
'symbol'('diff','diff','src_span'(55,26,55,30,3288,4),'BuiltIn primitive').
'symbol'('SPEC_STACK','SPEC_STACK','src_span'(56,1,56,11,3319,10),'Ident (Groundrep.)').
'symbol'('InferenceStall','InferenceStall','src_span'(67,1,67,15,3806,14),'Ident (Groundrep.)').
'symbol'('f5','f','src_span'(67,30,67,31,3835,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM_STALL','SYSTEM_STALL','src_span'(69,1,69,13,3976,12),'Ident (Groundrep.)').
'symbol'('CONSOLE_STACK_STALL','CONSOLE_STACK_STALL','src_span'(71,1,71,20,4122,19),'Ident (Groundrep.)').