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
'bindval'('MAX_INDEX','int'(3),'src_span'(4,1,4,14,165,13)).
'dataTypeDef'('prediction_t',['constructor'('person'),'constructor'('no_person')]).
'dataTypeDef'('source_t',['constructor'('camera'),'constructor'('inference')]).
'dataTypeDef'('thread_t',['constructor'('cam'),'constructor'('inf'),'constructor'('rep'),'constructor'('main_app')]).
'dataTypeDef'('report_t',['constructorC'('started','dotTupleType'(['source_t'])),'constructorC'('result','dotTupleType'(['setExp'('rangeClosed'('int'(0),'-'('val_of'('MAX_INDEX','src_span'(9,55,9,64,371,9)),'int'(1)))),'prediction_t'])),'constructorC'('stack','dotTupleType'(['thread_t']))]).
'channel'('g_trigger_chan','type'('dotUnitType')).
'channel'('frame_chan','type'('dotTupleType'(['setExp'('rangeClosed'('int'(0),'-'('val_of'('MAX_INDEX','src_span'(12,27,12,36,464,9)),'int'(1))))]))).
'channel'('report_chan','type'('dotTupleType'(['report_t']))).
'channel'('camera_report','type'('dotTupleType'(['report_t']))).
'channel'('inference_report','type'('dotTupleType'(['report_t']))).
'channel'('camera_log','type'('dotUnitType')).
'channel'('direct_print','type'('dotUnitType')).
'channel'('stack_tick','type'('dotUnitType')).
'channel'('line','type'('dotTupleType'(['report_t']))).
'bindval'('ENV','prefix'('src_span'(18,7,18,21,642,14),[],'g_trigger_chan','val_of'('ENV','src_span'(18,25,18,28,660,3)),'src_span'(18,22,18,24,656,21)),'src_span'(18,1,18,28,636,27)).
'bindval'('Camera','prefix'('src_span'(20,10,20,20,674,10),[],'camera_log','prefix'('src_span'(20,24,20,35,688,11),['out'('dotTuple'(['started','camera']))],'report_chan','agent_call'('src_span'(20,54,20,64,718,10),'CameraLoop',['int'(0)]),'src_span'(20,51,20,53,714,32)),'src_span'(20,21,20,23,684,57)),'src_span'(20,1,20,67,665,66)).
'agent'('CameraLoop'(_c),'prefix'('src_span'(21,17,21,31,748,14),[],'g_trigger_chan','prefix'('src_span'(21,35,21,45,766,10),['out'(_c)],'frame_chan','agent_call'('src_span'(21,51,21,61,782,10),'CameraLoop',['%'('+'(_c,'int'(1)),'val_of'('MAX_INDEX','src_span'(21,72,21,81,803,9)))]),'src_span'(21,48,21,50,778,37)),'src_span'(21,32,21,34,762,65)),'src_span'(21,17,21,82,748,65)).
'bindval'('SPEC_PIPE','prefix'('src_span'(23,14,23,24,828,10),[],'camera_log','prefix'('src_span'(23,28,23,32,842,4),['out'('dotTuple'(['started','camera']))],'line','prefix'('src_span'(23,51,23,55,865,4),['out'('dotTuple'(['started','inference']))],'line','agent_call'('src_span'(23,77,23,84,891,7),'RESULTS',['int'(0)]),'src_span'(23,74,23,76,887,32)),'src_span'(23,48,23,50,861,55)),'src_span'(23,25,23,27,838,73)),'src_span'(23,1,23,87,815,86)).
'agent'('RESULTS'(_f),'repInternalChoice'(['comprehensionGenerator'(_p,'prediction_t')],'prefix'('src_span'(24,37,24,41,938,4),['out'('dotTuple'(['result',_f,_p]))],'line','agent_call'('src_span'(24,56,24,63,957,7),'RESULTS',['%'('+'(_f,'int'(1)),'val_of'('MAX_INDEX','src_span'(24,74,24,83,975,9)))]),'src_span'(24,53,24,55,953,43)),'src_span'(24,18,24,36,919,18)),'src_span'(24,14,24,84,915,70)).
'bindval'('SPEC_STACK','prefix'('src_span'(25,14,25,18,999,4),['out'('dotTuple'(['stack','cam']))],'line','prefix'('src_span'(25,32,25,36,1017,4),['out'('dotTuple'(['stack','inf']))],'line','prefix'('src_span'(25,50,25,54,1035,4),['out'('dotTuple'(['stack','rep']))],'line','prefix'('src_span'(25,68,25,72,1053,4),['out'('dotTuple'(['stack','main_app']))],'line','val_of'('SPEC_STACK','src_span'(25,91,25,101,1076,10)),'src_span'(25,88,25,90,1072,29)),'src_span'(25,65,25,67,1049,47)),'src_span'(25,47,25,49,1031,65)),'src_span'(25,29,25,31,1013,83)),'src_span'(25,1,25,101,986,100)).
'bindval'('Camera1','prefix'('src_span'(30,11,30,21,1366,10),[],'camera_log','prefix'('src_span'(30,25,30,38,1380,13),['out'('dotTuple'(['started','camera']))],'camera_report','agent_call'('src_span'(30,57,30,68,1412,11),'CameraLoop1',['int'(0)]),'src_span'(30,54,30,56,1408,33)),'src_span'(30,22,30,24,1376,60)),'src_span'(30,1,30,71,1356,70)).
'agent'('CameraLoop1'(_c2),'prefix'('src_span'(31,18,31,32,1444,14),[],'g_trigger_chan','prefix'('src_span'(31,36,31,46,1462,10),['out'(_c2)],'frame_chan','agent_call'('src_span'(31,52,31,63,1478,11),'CameraLoop1',['%'('+'(_c2,'int'(1)),'val_of'('MAX_INDEX','src_span'(31,74,31,83,1500,9)))]),'src_span'(31,49,31,51,1474,38)),'src_span'(31,33,31,35,1458,66)),'src_span'(31,18,31,84,1444,66)).
'bindval'('Inference1','prefix'('src_span'(32,14,32,24,1524,10),['in'(_f2)],'frame_chan','prefix'('src_span'(32,30,32,46,1540,16),['out'('dotTuple'(['started','inference']))],'inference_report','agent_call'('src_span'(32,68,32,74,1578,6),'Infer1',[_f2]),'src_span'(32,65,32,67,1574,31)),'src_span'(32,27,32,29,1536,53)),'src_span'(32,1,32,77,1511,76)).
'agent'('Infer1'(_f3),'|~|'('prefix'('src_span'(33,15,33,31,1602,16),['out'('dotTuple'(['result',_f3,'person']))],'inference_report','val_of'('Next1','src_span'(33,51,33,56,1638,5)),'src_span'(33,48,33,50,1634,25)),'prefix'('src_span'(33,63,33,79,1650,16),['out'('dotTuple'(['result',_f3,'no_person']))],'inference_report','val_of'('Next1','src_span'(33,102,33,107,1689,5)),'src_span'(33,99,33,101,1685,28)),'src_span_operator'('no_loc_info_available','src_span'(33,58,33,61,1645,3))),'no_loc_info_available').
'bindval'('Next1','prefix'('src_span'(34,14,34,24,1709,10),['in'(_f4)],'frame_chan','agent_call'('src_span'(34,30,34,36,1725,6),'Infer1',[_f4]),'src_span'(34,27,34,29,1721,15)),'src_span'(34,1,34,39,1696,38)).
'bindval'('Reporter1','prefix'('src_span'(35,14,35,27,1748,13),['in'(_r)],'camera_report','prefix'('src_span'(35,33,35,37,1767,4),['out'(_r)],'line','prefix'('src_span'(35,43,35,59,1777,16),['in'(_s)],'inference_report','prefix'('src_span'(35,65,35,69,1799,4),['out'(_s)],'line','val_of'('Reporter1','src_span'(35,75,35,84,1809,9)),'src_span'(35,72,35,74,1805,15)),'src_span'(35,62,35,64,1795,25)),'src_span'(35,40,35,42,1773,47)),'src_span'(35,30,35,32,1763,57)),'src_span'(35,1,35,84,1735,83)).
'bindval'('SYSTEM1','sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(36,11,36,14,1829,3)),'sharing'('closure'(['camera_report','inference_report']),'sharing'('closure'(['frame_chan']),'val_of'('Camera1','src_span'(37,7,37,14,1866,7)),'val_of'('Inference1','src_span'(37,38,37,48,1897,10)),'src_span'(37,15,37,37,1874,22)),'val_of'('Reporter1','src_span'(37,94,37,103,1953,9)),'src_span'(37,50,37,93,1909,43)),'src_span'(36,15,36,41,1833,26)),'src_span'(36,1,37,104,1819,144)).
'assertModelCheckExt'('False','val_of'('SYSTEM1','src_span'(39,8,39,15,1972,7)),'DeadlockFree','F').
'bindval'('Inference2','prefix'('src_span'(43,14,43,24,2205,10),['in'(_f5)],'frame_chan','prefix'('src_span'(43,30,43,41,2221,11),['out'('dotTuple'(['started','inference']))],'report_chan','agent_call'('src_span'(43,63,43,69,2254,6),'Infer2',[_f5]),'src_span'(43,60,43,62,2250,31)),'src_span'(43,27,43,29,2217,48)),'src_span'(43,1,43,72,2192,71)).
'agent'('Infer2'(_f6),'|~|'('prefix'('src_span'(44,15,44,26,2278,11),['out'('dotTuple'(['result',_f6,'person']))],'report_chan','prefix'('src_span'(44,46,44,58,2309,12),[],'direct_print','val_of'('Next2','src_span'(44,62,44,67,2325,5)),'src_span'(44,59,44,61,2321,21)),'src_span'(44,43,44,45,2305,41)),'prefix'('src_span'(45,19,45,30,2350,11),['out'('dotTuple'(['result',_f6,'no_person']))],'report_chan','prefix'('src_span'(45,53,45,65,2384,12),[],'direct_print','val_of'('Next2','src_span'(45,69,45,74,2400,5)),'src_span'(45,66,45,68,2396,21)),'src_span'(45,50,45,52,2380,44)),'src_span_operator'('no_loc_info_available','src_span'(45,14,45,17,2345,3))),'no_loc_info_available').
'bindval'('Next2','prefix'('src_span'(46,14,46,24,2420,10),['in'(_f7)],'frame_chan','agent_call'('src_span'(46,30,46,36,2436,6),'Infer2',[_f7]),'src_span'(46,27,46,29,2432,15)),'src_span'(46,1,46,39,2407,38)).
'bindval'('Reporter2','prefix'('src_span'(47,14,47,25,2459,11),['in'(_r2)],'report_chan','prefix'('src_span'(47,31,47,35,2476,4),['out'(_r2)],'line','val_of'('Reporter2','src_span'(47,41,47,50,2486,9)),'src_span'(47,38,47,40,2482,15)),'src_span'(47,28,47,30,2472,25)),'src_span'(47,1,47,50,2446,49)).
'bindval'('SYSTEM2','sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(48,11,48,14,2506,3)),'sharing'('closure'(['report_chan']),'sharing'('closure'(['frame_chan']),'val_of'('Camera','src_span'(49,7,49,13,2543,6)),'val_of'('Inference2','src_span'(49,37,49,47,2573,10)),'src_span'(49,14,49,36,2550,22)),'val_of'('Reporter2','src_span'(49,73,49,82,2609,9)),'src_span'(49,49,49,72,2585,23)),'src_span'(48,15,48,41,2510,26)),'src_span'(48,1,49,83,2496,123)).
'bindval'('CONSOLE2','\x5c\'('val_of'('SYSTEM2','src_span'(50,12,50,19,2631,7)),'closure'(['g_trigger_chan','frame_chan','report_chan']),'src_span_operator'('no_loc_info_available','src_span'(50,20,50,21,2639,1))),'src_span'(50,1,50,67,2620,66)).
'assertRef'('False','val_of'('SPEC_PIPE','src_span'(52,8,52,17,2695,9)),'Trace','val_of'('CONSOLE2','src_span'(52,22,52,30,2709,8)),'src_span'(52,1,52,30,2688,29)).
'bindval'('InferenceStall','prefix'('src_span'(57,18,57,28,3042,10),['in'(_f8)],'frame_chan','prefix'('src_span'(57,34,57,45,3058,11),['out'('dotTuple'(['started','inference']))],'report_chan','|~|'('prefix'('src_span'(58,20,58,31,3110,11),['out'('dotTuple'(['result',_f8,'person']))],'report_chan','stop'('src_span'(58,51,58,55,3141,4)),'src_span'(58,48,58,50,3137,24)),'prefix'('src_span'(58,62,58,73,3152,11),['out'('dotTuple'(['result',_f8,'no_person']))],'report_chan','stop'('src_span'(58,96,58,100,3186,4)),'src_span'(58,93,58,95,3182,27)),'src_span_operator'('no_loc_info_available','src_span'(58,57,58,60,3147,3))),'src_span'(57,64,58,17,3087,123)),'src_span'(57,31,57,33,3054,140)),'src_span'(57,1,58,102,3025,167)).
'bindval'('Reporter3','prefix'('src_span'(59,13,59,24,3205,11),['in'(_r3)],'report_chan','prefix'('src_span'(59,30,59,34,3222,4),['out'(_r3)],'line','|~|'('prefix'('src_span'(60,15,60,19,3246,4),['out'('dotTuple'(['stack','cam']))],'line','prefix'('src_span'(60,33,60,37,3264,4),['out'('dotTuple'(['stack','inf']))],'line','prefix'('src_span'(60,51,60,55,3282,4),['out'('dotTuple'(['stack','rep']))],'line','prefix'('src_span'(60,69,60,73,3300,4),['out'('dotTuple'(['stack','main_app']))],'line','val_of'('Reporter3','src_span'(60,92,60,101,3323,9)),'src_span'(60,89,60,91,3319,28)),'src_span'(60,66,60,68,3296,46)),'src_span'(60,48,60,50,3278,64)),'src_span'(60,30,60,32,3260,82)),'val_of'('Reporter3','src_span'(61,18,61,27,3351,9)),'src_span_operator'('no_loc_info_available','src_span'(61,14,61,17,3347,3))),'src_span'(59,37,60,12,3228,135)),'src_span'(59,27,59,29,3218,145)),'src_span'(59,1,61,28,3193,168)).
'bindval'('SYSTEM3','sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(62,11,62,14,3372,3)),'sharing'('closure'(['report_chan']),'sharing'('closure'(['frame_chan']),'val_of'('Camera','src_span'(63,7,63,13,3409,6)),'val_of'('InferenceStall','src_span'(63,37,63,51,3439,14)),'src_span'(63,14,63,36,3416,22)),'val_of'('Reporter3','src_span'(63,77,63,86,3479,9)),'src_span'(63,53,63,76,3455,23)),'src_span'(62,15,62,41,3376,26)),'src_span'(62,1,63,87,3362,127)).
'bindval'('CONSOLE_STACK3','\x5c\'('val_of'('SYSTEM3','src_span'(64,18,64,25,3507,7)),'agent_call'('src_span'(64,28,64,32,3517,4),'diff',['Events','closure'(['dotTuple'(['line','stack'])])]),'src_span_operator'('no_loc_info_available','src_span'(64,26,64,27,3515,1))),'src_span'(64,1,64,58,3490,57)).
'assertRef'('False','val_of'('SPEC_STACK','src_span'(66,8,66,18,3556,10)),'Failure','val_of'('CONSOLE_STACK3','src_span'(66,23,66,37,3571,14)),'src_span'(66,1,66,37,3549,36)).
'comment'('lineComment'('-- Positive controls for Neuropathway.csp: plausible wrong designs. Each must FAIL its check,'),'src_position'(1,1,0,93)).
'comment'('lineComment'('-- showing that the checks of the real model can detect these faults.'),'src_position'(2,1,94,69)).
'comment'('lineComment'('-- Control 1 (must deadlock): one channel per writer, and a Reporter that reads them in a'),'src_position'(27,1,1088,89)).
'comment'('lineComment'('-- fixed order, Camera first, as if every round brought one report from each. Camera reports'),'src_position'(28,1,1178,92)).
'comment'('lineComment'('-- only once, so the Reporter waits for it for ever while Inference waits to report.'),'src_position'(29,1,1271,84)).
'comment'('lineComment'('-- expected: false'),'src_position'(39,46,2010,18)).
'comment'('lineComment'('-- Control 2 (must violate the console specification): as the real pipeline, but Inference'),'src_position'(41,1,2030,90)).
'comment'('lineComment'('-- also prints directly (a second printer), as the old dbg_printf did.'),'src_position'(42,1,2121,70)).
'comment'('lineComment'('-- expected: false'),'src_position'(52,46,2733,18)).
'comment'('lineComment'('-- Control 3 (the previous design, must lose the stack report when the pipeline stalls): the'),'src_position'(54,1,2753,92)).
'comment'('lineComment'('-- Reporter prints the stack report itself, after a report, when its timer has expired (an'),'src_position'(55,1,2846,90)).
'comment'('lineComment'('-- internal choice), and MainApp sends nothing. Inference stops after its first result.'),'src_position'(56,1,2937,87)).
'comment'('lineComment'('-- expected: false'),'src_position'(66,46,3594,18)).
'symbol'('MAX_INDEX','MAX_INDEX','src_span'(4,1,4,10,165,9),'Ident (Groundrep.)').
'symbol'('prediction_t','prediction_t','src_span'(6,10,6,22,189,12),'Datatype').
'symbol'('person','person','src_span'(6,25,6,31,204,6),'Constructor of Datatype').
'symbol'('no_person','no_person','src_span'(6,34,6,43,213,9),'Constructor of Datatype').
'symbol'('source_t','source_t','src_span'(7,10,7,18,232,8),'Datatype').
'symbol'('camera','camera','src_span'(7,25,7,31,247,6),'Constructor of Datatype').
'symbol'('inference','inference','src_span'(7,34,7,43,256,9),'Constructor of Datatype').
'symbol'('thread_t','thread_t','src_span'(8,10,8,18,275,8),'Datatype').
'symbol'('cam','cam','src_span'(8,25,8,28,290,3),'Constructor of Datatype').
'symbol'('inf','inf','src_span'(8,31,8,34,296,3),'Constructor of Datatype').
'symbol'('rep','rep','src_span'(8,37,8,40,302,3),'Constructor of Datatype').
'symbol'('main_app','main_app','src_span'(8,43,8,51,308,8),'Constructor of Datatype').
'symbol'('report_t','report_t','src_span'(9,10,9,18,326,8),'Datatype').
'symbol'('started','started','src_span'(9,25,9,32,341,7),'Constructor of Datatype').
'symbol'('result','result','src_span'(9,44,9,50,360,6),'Constructor of Datatype').
'symbol'('stack','stack','src_span'(9,83,9,88,399,5),'Constructor of Datatype').
'symbol'('g_trigger_chan','g_trigger_chan','src_span'(11,9,11,23,423,14),'Channel').
'symbol'('frame_chan','frame_chan','src_span'(12,9,12,19,446,10),'Channel').
'symbol'('report_chan','report_chan','src_span'(13,9,13,20,485,11),'Channel').
'symbol'('camera_report','camera_report','src_span'(14,9,14,22,516,13),'Channel').
'symbol'('inference_report','inference_report','src_span'(14,24,14,40,531,16),'Channel').
'symbol'('camera_log','camera_log','src_span'(15,9,15,19,567,10),'Channel').
'symbol'('direct_print','direct_print','src_span'(15,21,15,33,579,12),'Channel').
'symbol'('stack_tick','stack_tick','src_span'(15,35,15,45,593,10),'Channel').
'symbol'('line','line','src_span'(16,9,16,13,612,4),'Channel').
'symbol'('ENV','ENV','src_span'(18,1,18,4,636,3),'Ident (Groundrep.)').
'symbol'('Camera','Camera','src_span'(20,1,20,7,665,6),'Ident (Groundrep.)').
'symbol'('CameraLoop','CameraLoop','src_span'(21,1,21,11,732,10),'Funktion or Process').
'symbol'('c','c','src_span'(21,12,21,13,743,1),'Ident (Prolog Variable)').
'symbol'('SPEC_PIPE','SPEC_PIPE','src_span'(23,1,23,10,815,9),'Ident (Groundrep.)').
'symbol'('RESULTS','RESULTS','src_span'(24,1,24,8,902,7),'Funktion or Process').
'symbol'('f','f','src_span'(24,9,24,10,910,1),'Ident (Prolog Variable)').
'symbol'('p','p','src_span'(24,18,24,19,919,1),'Ident (Prolog Variable)').
'symbol'('SPEC_STACK','SPEC_STACK','src_span'(25,1,25,11,986,10),'Ident (Groundrep.)').
'symbol'('Camera1','Camera1','src_span'(30,1,30,8,1356,7),'Ident (Groundrep.)').
'symbol'('CameraLoop1','CameraLoop1','src_span'(31,1,31,12,1427,11),'Funktion or Process').
'symbol'('c2','c','src_span'(31,13,31,14,1439,1),'Ident (Prolog Variable)').
'symbol'('Inference1','Inference1','src_span'(32,1,32,11,1511,10),'Ident (Groundrep.)').
'symbol'('f2','f','src_span'(32,25,32,26,1535,1),'Ident (Prolog Variable)').
'symbol'('Infer1','Infer1','src_span'(33,1,33,7,1588,6),'Funktion or Process').
'symbol'('f3','f','src_span'(33,8,33,9,1595,1),'Ident (Prolog Variable)').
'symbol'('Next1','Next1','src_span'(34,1,34,6,1696,5),'Ident (Groundrep.)').
'symbol'('f4','f','src_span'(34,25,34,26,1720,1),'Ident (Prolog Variable)').
'symbol'('Reporter1','Reporter1','src_span'(35,1,35,10,1735,9),'Ident (Groundrep.)').
'symbol'('r','r','src_span'(35,28,35,29,1762,1),'Ident (Prolog Variable)').
'symbol'('s','s','src_span'(35,60,35,61,1794,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM1','SYSTEM1','src_span'(36,1,36,8,1819,7),'Ident (Groundrep.)').
'symbol'('Inference2','Inference2','src_span'(43,1,43,11,2192,10),'Ident (Groundrep.)').
'symbol'('f5','f','src_span'(43,25,43,26,2216,1),'Ident (Prolog Variable)').
'symbol'('Infer2','Infer2','src_span'(44,1,44,7,2264,6),'Funktion or Process').
'symbol'('f6','f','src_span'(44,8,44,9,2271,1),'Ident (Prolog Variable)').
'symbol'('Next2','Next2','src_span'(46,1,46,6,2407,5),'Ident (Groundrep.)').
'symbol'('f7','f','src_span'(46,25,46,26,2431,1),'Ident (Prolog Variable)').
'symbol'('Reporter2','Reporter2','src_span'(47,1,47,10,2446,9),'Ident (Groundrep.)').
'symbol'('r2','r','src_span'(47,26,47,27,2471,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM2','SYSTEM2','src_span'(48,1,48,8,2496,7),'Ident (Groundrep.)').
'symbol'('CONSOLE2','CONSOLE2','src_span'(50,1,50,9,2620,8),'Ident (Groundrep.)').
'symbol'('InferenceStall','InferenceStall','src_span'(57,1,57,15,3025,14),'Ident (Groundrep.)').
'symbol'('f8','f','src_span'(57,29,57,30,3053,1),'Ident (Prolog Variable)').
'symbol'('Reporter3','Reporter3','src_span'(59,1,59,10,3193,9),'Ident (Groundrep.)').
'symbol'('r3','r','src_span'(59,25,59,26,3217,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM3','SYSTEM3','src_span'(62,1,62,8,3362,7),'Ident (Groundrep.)').
'symbol'('CONSOLE_STACK3','CONSOLE_STACK3','src_span'(64,1,64,15,3490,14),'Ident (Groundrep.)').
'symbol'('diff','diff','src_span'(64,28,64,32,3517,4),'BuiltIn primitive').