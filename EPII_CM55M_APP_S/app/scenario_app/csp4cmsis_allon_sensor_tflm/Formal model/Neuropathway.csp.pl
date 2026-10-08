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
'bindval'('MAX_INDEX','int'(3),'src_span'(5,1,5,14,239,13)).
'dataTypeDef'('prediction_t',['constructor'('person'),'constructor'('no_person')]).
'dataTypeDef'('source_t',['constructor'('camera'),'constructor'('inference')]).
'dataTypeDef'('report_t',['constructorC'('started','dotTupleType'(['source_t'])),'constructorC'('result','dotTupleType'(['setExp'('rangeClosed'('int'(0),'-'('val_of'('MAX_INDEX','src_span'(9,55,9,64,483,9)),'int'(1)))),'prediction_t']))]).
'channel'('g_trigger_chan','type'('dotUnitType')).
'channel'('frame_chan','type'('dotTupleType'(['setExp'('rangeClosed'('int'(0),'-'('val_of'('MAX_INDEX','src_span'(12,27,12,36,618,9)),'int'(1))))]))).
'channel'('report_chan','type'('dotTupleType'(['report_t']))).
'channel'('main_print','type'('dotUnitType')).
'channel'('camera_log','type'('dotUnitType')).
'channel'('line','type'('dotTupleType'(['report_t']))).
'channel'('stack_report','type'('dotUnitType')).
'bindval'('ENV','prefix'('src_span'(20,7,20,21,1226,14),[],'g_trigger_chan','val_of'('ENV','src_span'(20,25,20,28,1244,3)),'src_span'(20,22,20,24,1240,21)),'src_span'(20,1,20,28,1220,27)).
'bindval'('Camera','prefix'('src_span'(23,10,23,20,1352,10),[],'camera_log','prefix'('src_span'(23,24,23,35,1366,11),['out'('dotTuple'(['started','camera']))],'report_chan','agent_call'('src_span'(23,54,23,64,1396,10),'CameraLoop',['int'(0)]),'src_span'(23,51,23,53,1392,32)),'src_span'(23,21,23,23,1362,57)),'src_span'(23,1,23,67,1343,66)).
'agent'('CameraLoop'(_c),'prefix'('src_span'(24,17,24,31,1426,14),[],'g_trigger_chan','prefix'('src_span'(24,35,24,45,1444,10),['out'(_c)],'frame_chan','agent_call'('src_span'(24,51,24,61,1460,10),'CameraLoop',['%'('+'(_c,'int'(1)),'val_of'('MAX_INDEX','src_span'(24,72,24,81,1481,9)))]),'src_span'(24,48,24,50,1456,37)),'src_span'(24,32,24,34,1440,65)),'src_span'(24,17,24,82,1426,65)).
'bindval'('Inference','prefix'('src_span'(28,13,28,23,1689,10),['in'(_f)],'frame_chan','prefix'('src_span'(28,29,28,40,1705,11),['out'('dotTuple'(['started','inference']))],'report_chan','agent_call'('src_span'(28,62,28,67,1738,5),'Infer',[_f]),'src_span'(28,59,28,61,1734,30)),'src_span'(28,26,28,28,1701,47)),'src_span'(28,1,28,70,1677,69)).
'agent'('Infer'(_f2),'|~|'('prefix'('src_span'(29,14,29,25,1760,11),['out'('dotTuple'(['result',_f2,'person']))],'report_chan','val_of'('Next','src_span'(29,45,29,49,1791,4)),'src_span'(29,42,29,44,1787,24)),'prefix'('src_span'(29,56,29,67,1802,11),['out'('dotTuple'(['result',_f2,'no_person']))],'report_chan','val_of'('Next','src_span'(29,90,29,94,1836,4)),'src_span'(29,87,29,89,1832,27)),'src_span_operator'('no_loc_info_available','src_span'(29,51,29,54,1797,3))),'no_loc_info_available').
'bindval'('Next','prefix'('src_span'(30,13,30,23,1854,10),['in'(_f3)],'frame_chan','agent_call'('src_span'(30,29,30,34,1870,5),'Infer',[_f3]),'src_span'(30,26,30,28,1866,14)),'src_span'(30,1,30,37,1842,36)).
'bindval'('Reporter','prefix'('src_span'(33,12,33,23,1986,11),['in'(_r)],'report_chan','prefix'('src_span'(33,29,33,33,2003,4),['out'(_r)],'line','|~|'('prefix'('src_span'(33,41,33,53,2015,12),[],'stack_report','val_of'('Reporter','src_span'(33,57,33,65,2031,8)),'src_span'(33,54,33,56,2027,24)),'val_of'('Reporter','src_span'(33,71,33,79,2045,8)),'src_span_operator'('no_loc_info_available','src_span'(33,67,33,70,2041,3))),'src_span'(33,36,33,38,2009,47)),'src_span'(33,26,33,28,1999,57)),'src_span'(33,1,33,80,1975,79)).
'bindval'('NETWORK','sharing'('closure'(['report_chan']),'sharing'('closure'(['frame_chan']),'val_of'('Camera','src_span'(35,12,35,18,2067,6)),'val_of'('Inference','src_span'(35,42,35,51,2097,9)),'src_span'(35,19,35,41,2074,22)),'val_of'('Reporter','src_span'(35,77,35,85,2132,8)),'src_span'(35,53,35,76,2108,23)),'src_span'(35,1,35,85,2056,84)).
'bindval'('SYSTEM','prefix'('src_span'(38,10,38,20,2239,10),[],'main_print','sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(38,25,38,28,2254,3)),'val_of'('NETWORK','src_span'(38,56,38,63,2285,7)),'src_span'(38,29,38,55,2258,26)),'src_span'(38,21,38,23,2249,54)),'src_span'(38,1,38,64,2230,63)).
'bindval'('CONSOLE','\x5c\'('val_of'('SYSTEM','src_span'(41,11,41,17,2368,6)),'closure'(['g_trigger_chan','frame_chan','report_chan']),'src_span_operator'('no_loc_info_available','src_span'(41,18,41,19,2375,1))),'src_span'(41,1,41,65,2358,64)).
'agent'('STK'(_P),'|~|'('prefix'('src_span'(46,11,46,23,2655,12),[],'stack_report',_P,'src_span'(46,24,46,26,2667,17)),_P,'src_span_operator'('no_loc_info_available','src_span'(46,30,46,33,2674,3))),'no_loc_info_available').
'bindval'('SPEC','prefix'('src_span'(47,8,47,18,2687,10),[],'main_print','prefix'('src_span'(47,22,47,32,2701,10),[],'camera_log','prefix'('src_span'(47,36,47,40,2715,4),['out'('dotTuple'(['started','camera']))],'line','agent_call'('src_span'(48,8,48,11,2745,3),'STK',['prefix'('src_span'(48,12,48,16,2749,4),['out'('dotTuple'(['started','inference']))],'line','agent_call'('src_span'(48,38,48,41,2775,3),'STK',['agent_call'('src_span'(48,42,48,49,2779,7),'RESULTS',['int'(0)])]),'src_span'(48,35,48,37,2771,37))]),'src_span'(47,56,48,7,2734,72)),'src_span'(47,33,47,35,2711,90)),'src_span'(47,19,47,21,2697,104)),'src_span'(47,1,48,54,2680,111)).
'agent'('RESULTS'(_f4),'repInternalChoice'(['comprehensionGenerator'(_p,'prediction_t')],'prefix'('src_span'(49,37,49,41,2828,4),['out'('dotTuple'(['result',_f4,_p]))],'line','agent_call'('src_span'(49,56,49,59,2847,3),'STK',['agent_call'('src_span'(49,60,49,67,2851,7),'RESULTS',['%'('+'(_f4,'int'(1)),'val_of'('MAX_INDEX','src_span'(49,78,49,87,2869,9)))])]),'src_span'(49,53,49,55,2843,48)),'src_span'(49,18,49,36,2809,18)),'src_span'(49,14,49,89,2805,75)).
'assertModelCheckExt'('False','val_of'('SYSTEM','src_span'(51,8,51,14,2889,6)),'DeadlockFree','F').
'assertModelCheck'('False','val_of'('SYSTEM','src_span'(52,8,52,14,2924,6)),'LivelockFree').
'assertRef'('False','val_of'('SPEC','src_span'(53,8,53,12,2957,4)),'Trace','val_of'('CONSOLE','src_span'(53,17,53,24,2966,7)),'src_span'(53,1,53,24,2950,23)).
'assertRef'('False','val_of'('SPEC','src_span'(54,8,54,12,2981,4)),'Failure','val_of'('CONSOLE','src_span'(54,17,54,24,2990,7)),'src_span'(54,1,54,24,2974,23)).
'assertRef'('False','val_of'('SPEC','src_span'(55,8,55,12,3005,4)),'FailureDivergence','val_of'('CONSOLE','src_span'(55,18,55,25,3015,7)),'src_span'(55,1,55,25,2998,24)).
'comment'('lineComment'('-- Neurochannel (csp4cmsis_allon_sensor_tflm): Camera -> Inference -> Reporter.'),'src_position'(1,1,0,79)).
'comment'('lineComment'('-- The Reporter is the only process that prints while the network runs; Camera and'),'src_position'(2,1,80,82)).
'comment'('lineComment'('-- Inference send it reports over one rendezvous channel with two writers.'),'src_position'(3,1,163,74)).
'comment'('lineComment'('-- frame indices 0..2 (wrapping), enough to check order'),'src_position'(5,48,286,55)).
'comment'('lineComment'('-- frame-ready interrupt -> Camera'),'src_position'(11,48,557,34)).
'comment'('lineComment'('-- Camera -> Inference (rendezvous)'),'src_position'(12,48,639,35)).
'comment'('lineComment'('-- Camera, Inference -> Reporter (rendezvous, two writers)'),'src_position'(13,48,722,58)).
'comment'('lineComment'('-- MainApp\x27\s line; the camera driver\x27\s start-up log'),'src_position'(14,48,828,51)).
'comment'('lineComment'('-- the Reporter\x27\s lines'),'src_position'(15,48,927,23)).
'comment'('lineComment'('-- the Reporter\x27\s periodic stack report'),'src_position'(16,48,998,39)).
'comment'('lineComment'('-- The frame-ready interrupt. Camera re-arms the capture only after it has read a trigger,'),'src_position'(18,1,1039,90)).
'comment'('lineComment'('-- so at most one trigger is pending: the one-slot buffer behaves like a rendezvous here.'),'src_position'(19,1,1130,89)).
'comment'('lineComment'('-- Camera: the driver prints its start-up log, then Camera reports Started (and never again).'),'src_position'(22,1,1249,93)).
'comment'('lineComment'('-- Inference: initialises the model only after the first frame (i.e. after Camera started),'),'src_position'(26,1,1493,91)).
'comment'('lineComment'('-- then reports one result per frame. The prediction depends on the image: internal choice.'),'src_position'(27,1,1585,91)).
'comment'('lineComment'('-- Reporter: prints every report; after a report it may print the stack report (timer-driven).'),'src_position'(32,1,1880,94)).
'comment'('lineComment'('-- MainApp runs above the network: it prints its line and ends before any process runs.'),'src_position'(37,1,2142,87)).
'comment'('lineComment'('-- The console as the user sees it (internal channels hidden).'),'src_position'(40,1,2295,62)).
'comment'('lineComment'('-- Specification of the console: MainApp\x27\s line, the camera driver\x27\s log, Camera\x27\s and'),'src_position'(43,1,2424,86)).
'comment'('lineComment'('-- Inference\x27\s Started lines, then exactly one result line per frame, in frame order;'),'src_position'(44,1,2511,85)).
'comment'('lineComment'('-- a stack report may follow any Reporter line.'),'src_position'(45,1,2597,47)).
'symbol'('MAX_INDEX','MAX_INDEX','src_span'(5,1,5,10,239,9),'Ident (Groundrep.)').
'symbol'('prediction_t','prediction_t','src_span'(7,10,7,22,352,12),'Datatype').
'symbol'('person','person','src_span'(7,25,7,31,367,6),'Constructor of Datatype').
'symbol'('no_person','no_person','src_span'(7,34,7,43,376,9),'Constructor of Datatype').
'symbol'('source_t','source_t','src_span'(8,10,8,18,395,8),'Datatype').
'symbol'('camera','camera','src_span'(8,25,8,31,410,6),'Constructor of Datatype').
'symbol'('inference','inference','src_span'(8,34,8,43,419,9),'Constructor of Datatype').
'symbol'('report_t','report_t','src_span'(9,10,9,18,438,8),'Datatype').
'symbol'('started','started','src_span'(9,25,9,32,453,7),'Constructor of Datatype').
'symbol'('result','result','src_span'(9,44,9,50,472,6),'Constructor of Datatype').
'symbol'('g_trigger_chan','g_trigger_chan','src_span'(11,9,11,23,518,14),'Channel').
'symbol'('frame_chan','frame_chan','src_span'(12,9,12,19,600,10),'Channel').
'symbol'('report_chan','report_chan','src_span'(13,9,13,20,683,11),'Channel').
'symbol'('main_print','main_print','src_span'(14,9,14,19,789,10),'Channel').
'symbol'('camera_log','camera_log','src_span'(14,21,14,31,801,10),'Channel').
'symbol'('line','line','src_span'(15,9,15,13,888,4),'Channel').
'symbol'('stack_report','stack_report','src_span'(16,9,16,21,959,12),'Channel').
'symbol'('ENV','ENV','src_span'(20,1,20,4,1220,3),'Ident (Groundrep.)').
'symbol'('Camera','Camera','src_span'(23,1,23,7,1343,6),'Ident (Groundrep.)').
'symbol'('CameraLoop','CameraLoop','src_span'(24,1,24,11,1410,10),'Funktion or Process').
'symbol'('c','c','src_span'(24,12,24,13,1421,1),'Ident (Prolog Variable)').
'symbol'('Inference','Inference','src_span'(28,1,28,10,1677,9),'Ident (Groundrep.)').
'symbol'('f','f','src_span'(28,24,28,25,1700,1),'Ident (Prolog Variable)').
'symbol'('Infer','Infer','src_span'(29,1,29,6,1747,5),'Funktion or Process').
'symbol'('f2','f','src_span'(29,7,29,8,1753,1),'Ident (Prolog Variable)').
'symbol'('Next','Next','src_span'(30,1,30,5,1842,4),'Ident (Groundrep.)').
'symbol'('f3','f','src_span'(30,24,30,25,1865,1),'Ident (Prolog Variable)').
'symbol'('Reporter','Reporter','src_span'(33,1,33,9,1975,8),'Ident (Groundrep.)').
'symbol'('r','r','src_span'(33,24,33,25,1998,1),'Ident (Prolog Variable)').
'symbol'('NETWORK','NETWORK','src_span'(35,1,35,8,2056,7),'Ident (Groundrep.)').
'symbol'('SYSTEM','SYSTEM','src_span'(38,1,38,7,2230,6),'Ident (Groundrep.)').
'symbol'('CONSOLE','CONSOLE','src_span'(41,1,41,8,2358,7),'Ident (Groundrep.)').
'symbol'('STK','STK','src_span'(46,1,46,4,2645,3),'Funktion or Process').
'symbol'('P','P','src_span'(46,5,46,6,2649,1),'Ident (Prolog Variable)').
'symbol'('SPEC','SPEC','src_span'(47,1,47,5,2680,4),'Ident (Groundrep.)').
'symbol'('RESULTS','RESULTS','src_span'(49,1,49,8,2792,7),'Funktion or Process').
'symbol'('f4','f','src_span'(49,9,49,10,2800,1),'Ident (Prolog Variable)').
'symbol'('p','p','src_span'(49,18,49,19,2809,1),'Ident (Prolog Variable)').