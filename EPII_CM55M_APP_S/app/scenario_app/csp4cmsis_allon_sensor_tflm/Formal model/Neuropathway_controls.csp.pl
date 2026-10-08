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
'bindval'('MAX_INDEX','int'(3),'src_span'(4,1,4,14,169,13)).
'dataTypeDef'('prediction_t',['constructor'('person'),'constructor'('no_person')]).
'dataTypeDef'('source_t',['constructor'('camera'),'constructor'('inference')]).
'dataTypeDef'('report_t',['constructorC'('started','dotTupleType'(['source_t'])),'constructorC'('result','dotTupleType'(['setExp'('rangeClosed'('int'(0),'-'('val_of'('MAX_INDEX','src_span'(8,55,8,64,324,9)),'int'(1)))),'prediction_t']))]).
'channel'('g_trigger_chan','type'('dotUnitType')).
'channel'('frame_chan','type'('dotTupleType'(['setExp'('rangeClosed'('int'(0),'-'('val_of'('MAX_INDEX','src_span'(11,27,11,36,400,9)),'int'(1))))]))).
'channel'('report_chan','type'('dotTupleType'(['report_t']))).
'channel'('camera_report','type'('dotTupleType'(['report_t']))).
'channel'('inference_report','type'('dotTupleType'(['report_t']))).
'channel'('main_print','type'('dotUnitType')).
'channel'('camera_log','type'('dotUnitType')).
'channel'('direct_print','type'('dotUnitType')).
'channel'('line','type'('dotTupleType'(['report_t']))).
'channel'('stack_report','type'('dotUnitType')).
'bindval'('ENV','prefix'('src_span'(18,7,18,21,599,14),[],'g_trigger_chan','val_of'('ENV','src_span'(18,25,18,28,617,3)),'src_span'(18,22,18,24,613,21)),'src_span'(18,1,18,28,593,27)).
'bindval'('Camera1','prefix'('src_span'(23,11,23,21,900,10),[],'camera_log','prefix'('src_span'(23,25,23,38,914,13),['out'('dotTuple'(['started','camera']))],'camera_report','agent_call'('src_span'(23,57,23,68,946,11),'CameraLoop1',['int'(0)]),'src_span'(23,54,23,56,942,33)),'src_span'(23,22,23,24,910,60)),'src_span'(23,1,23,71,890,70)).
'agent'('CameraLoop1'(_c),'prefix'('src_span'(24,18,24,32,978,14),[],'g_trigger_chan','prefix'('src_span'(24,36,24,46,996,10),['out'(_c)],'frame_chan','agent_call'('src_span'(24,52,24,63,1012,11),'CameraLoop1',['%'('+'(_c,'int'(1)),'val_of'('MAX_INDEX','src_span'(24,74,24,83,1034,9)))]),'src_span'(24,49,24,51,1008,38)),'src_span'(24,33,24,35,992,66)),'src_span'(24,18,24,84,978,66)).
'bindval'('Inference1','prefix'('src_span'(25,14,25,24,1058,10),['in'(_f)],'frame_chan','prefix'('src_span'(25,30,25,46,1074,16),['out'('dotTuple'(['started','inference']))],'inference_report','agent_call'('src_span'(25,68,25,74,1112,6),'Infer1',[_f]),'src_span'(25,65,25,67,1108,31)),'src_span'(25,27,25,29,1070,53)),'src_span'(25,1,25,77,1045,76)).
'agent'('Infer1'(_f2),'|~|'('prefix'('src_span'(26,15,26,31,1136,16),['out'('dotTuple'(['result',_f2,'person']))],'inference_report','val_of'('Next1','src_span'(26,51,26,56,1172,5)),'src_span'(26,48,26,50,1168,25)),'prefix'('src_span'(26,63,26,79,1184,16),['out'('dotTuple'(['result',_f2,'no_person']))],'inference_report','val_of'('Next1','src_span'(26,102,26,107,1223,5)),'src_span'(26,99,26,101,1219,28)),'src_span_operator'('no_loc_info_available','src_span'(26,58,26,61,1179,3))),'no_loc_info_available').
'bindval'('Next1','prefix'('src_span'(27,14,27,24,1243,10),['in'(_f3)],'frame_chan','agent_call'('src_span'(27,30,27,36,1259,6),'Infer1',[_f3]),'src_span'(27,27,27,29,1255,15)),'src_span'(27,1,27,39,1230,38)).
'bindval'('Reporter1','prefix'('src_span'(28,14,28,27,1282,13),['in'(_r)],'camera_report','prefix'('src_span'(28,33,28,37,1301,4),['out'(_r)],'line','prefix'('src_span'(28,43,28,59,1311,16),['in'(_s)],'inference_report','prefix'('src_span'(28,65,28,69,1333,4),['out'(_s)],'line','val_of'('Reporter1','src_span'(28,75,28,84,1343,9)),'src_span'(28,72,28,74,1339,15)),'src_span'(28,62,28,64,1329,25)),'src_span'(28,40,28,42,1307,47)),'src_span'(28,30,28,32,1297,57)),'src_span'(28,1,28,84,1269,83)).
'bindval'('SYSTEM1','prefix'('src_span'(29,11,29,21,1363,10),[],'main_print','sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(30,6,30,9,1382,3)),'sharing'('closure'(['camera_report','inference_report']),'sharing'('closure'(['frame_chan']),'val_of'('Camera1','src_span'(31,11,31,18,1423,7)),'val_of'('Inference1','src_span'(31,42,31,52,1454,10)),'src_span'(31,19,31,41,1431,22)),'val_of'('Reporter1','src_span'(32,57,32,66,1522,9)),'src_span'(32,13,32,56,1478,43)),'src_span'(30,10,30,36,1386,26)),'src_span'(29,22,30,4,1373,170)),'src_span'(29,1,32,68,1353,180)).
'assertModelCheckExt'('False','val_of'('SYSTEM1','src_span'(34,8,34,15,1542,7)),'DeadlockFree','F').
'bindval'('Camera2','prefix'('src_span'(38,11,38,21,1771,10),[],'camera_log','prefix'('src_span'(38,25,38,36,1785,11),['out'('dotTuple'(['started','camera']))],'report_chan','agent_call'('src_span'(38,55,38,66,1815,11),'CameraLoop2',['int'(0)]),'src_span'(38,52,38,54,1811,33)),'src_span'(38,22,38,24,1781,58)),'src_span'(38,1,38,69,1761,68)).
'agent'('CameraLoop2'(_c2),'prefix'('src_span'(39,18,39,32,1847,14),[],'g_trigger_chan','prefix'('src_span'(39,36,39,46,1865,10),['out'(_c2)],'frame_chan','agent_call'('src_span'(39,52,39,63,1881,11),'CameraLoop2',['%'('+'(_c2,'int'(1)),'val_of'('MAX_INDEX','src_span'(39,74,39,83,1903,9)))]),'src_span'(39,49,39,51,1877,38)),'src_span'(39,33,39,35,1861,66)),'src_span'(39,18,39,84,1847,66)).
'bindval'('Inference2','prefix'('src_span'(40,14,40,24,1927,10),['in'(_f4)],'frame_chan','prefix'('src_span'(40,30,40,41,1943,11),['out'('dotTuple'(['started','inference']))],'report_chan','agent_call'('src_span'(40,63,40,69,1976,6),'Infer2',[_f4]),'src_span'(40,60,40,62,1972,31)),'src_span'(40,27,40,29,1939,48)),'src_span'(40,1,40,72,1914,71)).
'agent'('Infer2'(_f5),'|~|'('prefix'('src_span'(41,15,41,26,2000,11),['out'('dotTuple'(['result',_f5,'person']))],'report_chan','prefix'('src_span'(41,46,41,58,2031,12),[],'direct_print','val_of'('Next2','src_span'(41,62,41,67,2047,5)),'src_span'(41,59,41,61,2043,21)),'src_span'(41,43,41,45,2027,41)),'prefix'('src_span'(42,19,42,30,2072,11),['out'('dotTuple'(['result',_f5,'no_person']))],'report_chan','prefix'('src_span'(42,53,42,65,2106,12),[],'direct_print','val_of'('Next2','src_span'(42,69,42,74,2122,5)),'src_span'(42,66,42,68,2118,21)),'src_span'(42,50,42,52,2102,44)),'src_span_operator'('no_loc_info_available','src_span'(42,14,42,17,2067,3))),'no_loc_info_available').
'bindval'('Next2','prefix'('src_span'(43,14,43,24,2142,10),['in'(_f6)],'frame_chan','agent_call'('src_span'(43,30,43,36,2158,6),'Infer2',[_f6]),'src_span'(43,27,43,29,2154,15)),'src_span'(43,1,43,39,2129,38)).
'bindval'('Reporter2','prefix'('src_span'(44,14,44,25,2181,11),['in'(_r2)],'report_chan','prefix'('src_span'(44,31,44,35,2198,4),['out'(_r2)],'line','|~|'('prefix'('src_span'(44,43,44,55,2210,12),[],'stack_report','val_of'('Reporter2','src_span'(44,59,44,68,2226,9)),'src_span'(44,56,44,58,2222,25)),'val_of'('Reporter2','src_span'(44,74,44,83,2241,9)),'src_span_operator'('no_loc_info_available','src_span'(44,70,44,73,2237,3))),'src_span'(44,38,44,40,2204,49)),'src_span'(44,28,44,30,2194,59)),'src_span'(44,1,44,84,2168,83)).
'bindval'('SYSTEM2','prefix'('src_span'(45,11,45,21,2262,10),[],'main_print','sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(46,6,46,9,2281,3)),'sharing'('closure'(['report_chan']),'sharing'('closure'(['frame_chan']),'val_of'('Camera2','src_span'(47,11,47,18,2322,7)),'val_of'('Inference2','src_span'(47,42,47,52,2353,10)),'src_span'(47,19,47,41,2330,22)),'val_of'('Reporter2','src_span'(47,78,47,87,2389,9)),'src_span'(47,54,47,77,2365,23)),'src_span'(46,10,46,36,2285,26)),'src_span'(45,22,46,4,2272,138)),'src_span'(45,1,47,89,2252,148)).
'bindval'('CONSOLE2','\x5c\'('val_of'('SYSTEM2','src_span'(48,12,48,19,2412,7)),'closure'(['g_trigger_chan','frame_chan','report_chan']),'src_span_operator'('no_loc_info_available','src_span'(48,20,48,21,2420,1))),'src_span'(48,1,48,67,2401,66)).
'agent'('STK'(_P),'|~|'('prefix'('src_span'(50,11,50,23,2479,12),[],'stack_report',_P,'src_span'(50,24,50,26,2491,17)),_P,'src_span_operator'('no_loc_info_available','src_span'(50,30,50,33,2498,3))),'no_loc_info_available').
'bindval'('SPEC','prefix'('src_span'(51,8,51,18,2511,10),[],'main_print','prefix'('src_span'(51,22,51,32,2525,10),[],'camera_log','prefix'('src_span'(51,36,51,40,2539,4),['out'('dotTuple'(['started','camera']))],'line','agent_call'('src_span'(52,8,52,11,2569,3),'STK',['prefix'('src_span'(52,12,52,16,2573,4),['out'('dotTuple'(['started','inference']))],'line','agent_call'('src_span'(52,38,52,41,2599,3),'STK',['agent_call'('src_span'(52,42,52,49,2603,7),'RESULTS',['int'(0)])]),'src_span'(52,35,52,37,2595,37))]),'src_span'(51,56,52,7,2558,72)),'src_span'(51,33,51,35,2535,90)),'src_span'(51,19,51,21,2521,104)),'src_span'(51,1,52,54,2504,111)).
'agent'('RESULTS'(_f7),'repInternalChoice'(['comprehensionGenerator'(_p,'prediction_t')],'prefix'('src_span'(53,37,53,41,2652,4),['out'('dotTuple'(['result',_f7,_p]))],'line','agent_call'('src_span'(53,56,53,59,2671,3),'STK',['agent_call'('src_span'(53,60,53,67,2675,7),'RESULTS',['%'('+'(_f7,'int'(1)),'val_of'('MAX_INDEX','src_span'(53,78,53,87,2693,9)))])]),'src_span'(53,53,53,55,2667,48)),'src_span'(53,18,53,36,2633,18)),'src_span'(53,14,53,89,2629,75)).
'assertRef'('False','val_of'('SPEC','src_span'(55,8,55,12,2713,4)),'Trace','val_of'('CONSOLE2','src_span'(55,17,55,25,2722,8)),'src_span'(55,1,55,25,2706,24)).
'comment'('lineComment'('-- Positive controls for Neuropathway.csp: two plausible wrong designs. Each must FAIL its'),'src_position'(1,1,0,90)).
'comment'('lineComment'('-- check, showing that the checks of the real model can detect these faults.'),'src_position'(2,1,91,76)).
'comment'('lineComment'('-- Control 1 (must deadlock): one channel per writer, and a Reporter that reads them in a'),'src_position'(20,1,622,89)).
'comment'('lineComment'('-- fixed order, Camera first, as if every round brought one report from each. Camera reports'),'src_position'(21,1,712,92)).
'comment'('lineComment'('-- only once, so the Reporter waits for it for ever while Inference waits to report.'),'src_position'(22,1,805,84)).
'comment'('lineComment'('-- expected: false'),'src_position'(34,46,1580,18)).
'comment'('lineComment'('-- Control 2 (must violate the console specification): as the real network, but Inference'),'src_position'(36,1,1600,89)).
'comment'('lineComment'('-- also prints directly (a second printer), as the old dbg_printf did.'),'src_position'(37,1,1690,70)).
'comment'('lineComment'('-- expected: false'),'src_position'(55,46,2751,18)).
'symbol'('MAX_INDEX','MAX_INDEX','src_span'(4,1,4,10,169,9),'Ident (Groundrep.)').
'symbol'('prediction_t','prediction_t','src_span'(6,10,6,22,193,12),'Datatype').
'symbol'('person','person','src_span'(6,25,6,31,208,6),'Constructor of Datatype').
'symbol'('no_person','no_person','src_span'(6,34,6,43,217,9),'Constructor of Datatype').
'symbol'('source_t','source_t','src_span'(7,10,7,18,236,8),'Datatype').
'symbol'('camera','camera','src_span'(7,25,7,31,251,6),'Constructor of Datatype').
'symbol'('inference','inference','src_span'(7,34,7,43,260,9),'Constructor of Datatype').
'symbol'('report_t','report_t','src_span'(8,10,8,18,279,8),'Datatype').
'symbol'('started','started','src_span'(8,25,8,32,294,7),'Constructor of Datatype').
'symbol'('result','result','src_span'(8,44,8,50,313,6),'Constructor of Datatype').
'symbol'('g_trigger_chan','g_trigger_chan','src_span'(10,9,10,23,359,14),'Channel').
'symbol'('frame_chan','frame_chan','src_span'(11,9,11,19,382,10),'Channel').
'symbol'('report_chan','report_chan','src_span'(12,9,12,20,421,11),'Channel').
'symbol'('camera_report','camera_report','src_span'(13,9,13,22,452,13),'Channel').
'symbol'('inference_report','inference_report','src_span'(13,24,13,40,467,16),'Channel').
'symbol'('main_print','main_print','src_span'(14,9,14,19,503,10),'Channel').
'symbol'('camera_log','camera_log','src_span'(14,21,14,31,515,10),'Channel').
'symbol'('direct_print','direct_print','src_span'(14,33,14,45,527,12),'Channel').
'symbol'('line','line','src_span'(15,9,15,13,548,4),'Channel').
'symbol'('stack_report','stack_report','src_span'(16,9,16,21,579,12),'Channel').
'symbol'('ENV','ENV','src_span'(18,1,18,4,593,3),'Ident (Groundrep.)').
'symbol'('Camera1','Camera1','src_span'(23,1,23,8,890,7),'Ident (Groundrep.)').
'symbol'('CameraLoop1','CameraLoop1','src_span'(24,1,24,12,961,11),'Funktion or Process').
'symbol'('c','c','src_span'(24,13,24,14,973,1),'Ident (Prolog Variable)').
'symbol'('Inference1','Inference1','src_span'(25,1,25,11,1045,10),'Ident (Groundrep.)').
'symbol'('f','f','src_span'(25,25,25,26,1069,1),'Ident (Prolog Variable)').
'symbol'('Infer1','Infer1','src_span'(26,1,26,7,1122,6),'Funktion or Process').
'symbol'('f2','f','src_span'(26,8,26,9,1129,1),'Ident (Prolog Variable)').
'symbol'('Next1','Next1','src_span'(27,1,27,6,1230,5),'Ident (Groundrep.)').
'symbol'('f3','f','src_span'(27,25,27,26,1254,1),'Ident (Prolog Variable)').
'symbol'('Reporter1','Reporter1','src_span'(28,1,28,10,1269,9),'Ident (Groundrep.)').
'symbol'('r','r','src_span'(28,28,28,29,1296,1),'Ident (Prolog Variable)').
'symbol'('s','s','src_span'(28,60,28,61,1328,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM1','SYSTEM1','src_span'(29,1,29,8,1353,7),'Ident (Groundrep.)').
'symbol'('Camera2','Camera2','src_span'(38,1,38,8,1761,7),'Ident (Groundrep.)').
'symbol'('CameraLoop2','CameraLoop2','src_span'(39,1,39,12,1830,11),'Funktion or Process').
'symbol'('c2','c','src_span'(39,13,39,14,1842,1),'Ident (Prolog Variable)').
'symbol'('Inference2','Inference2','src_span'(40,1,40,11,1914,10),'Ident (Groundrep.)').
'symbol'('f4','f','src_span'(40,25,40,26,1938,1),'Ident (Prolog Variable)').
'symbol'('Infer2','Infer2','src_span'(41,1,41,7,1986,6),'Funktion or Process').
'symbol'('f5','f','src_span'(41,8,41,9,1993,1),'Ident (Prolog Variable)').
'symbol'('Next2','Next2','src_span'(43,1,43,6,2129,5),'Ident (Groundrep.)').
'symbol'('f6','f','src_span'(43,25,43,26,2153,1),'Ident (Prolog Variable)').
'symbol'('Reporter2','Reporter2','src_span'(44,1,44,10,2168,9),'Ident (Groundrep.)').
'symbol'('r2','r','src_span'(44,26,44,27,2193,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM2','SYSTEM2','src_span'(45,1,45,8,2252,7),'Ident (Groundrep.)').
'symbol'('CONSOLE2','CONSOLE2','src_span'(48,1,48,9,2401,8),'Ident (Groundrep.)').
'symbol'('STK','STK','src_span'(50,1,50,4,2469,3),'Funktion or Process').
'symbol'('P','P','src_span'(50,5,50,6,2473,1),'Ident (Prolog Variable)').
'symbol'('SPEC','SPEC','src_span'(51,1,51,5,2504,4),'Ident (Groundrep.)').
'symbol'('RESULTS','RESULTS','src_span'(53,1,53,8,2616,7),'Funktion or Process').
'symbol'('f7','f','src_span'(53,9,53,10,2624,1),'Ident (Prolog Variable)').
'symbol'('p','p','src_span'(53,18,53,19,2633,1),'Ident (Prolog Variable)').