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
'dataTypeDef'('Cmd',['constructor'('Restart'),'constructor'('Pace'),'constructor'('Init')]).
'nameType'('UserCmd','type'('dotTupleType'(['setExp'('rangeEnum'(['Restart','Pace']))]))).
'channel'('frame','type'('dotUnitType')).
'channel'('release','type'('dotUnitType')).
'channel'('cmd','type'('dotTupleType'(['UserCmd']))).
'channel'('no_cmd','type'('dotUnitType')).
'channel'('pace_due','type'('dotUnitType')).
'channel'('handled','type'('dotTupleType'(['Cmd']))).
'bindval'('FS_REQ','prefix'('src_span'(19,10,19,15,642,5),[],'frame','prefix'('src_span'(19,19,19,26,651,7),[],'release','val_of'('POLL','src_span'(19,30,19,34,662,4)),'src_span'(19,27,19,29,658,15)),'src_span'(19,16,19,18,647,24)),'src_span'(19,1,19,34,633,33)).
'bindval'('POLL','[]'('prefix'('src_span'(21,8,21,11,675,3),['in'(_c)],'cmd','prefix'('src_span'(21,17,21,24,684,7),['out'(_c)],'handled','val_of'('WAIT','src_span'(21,30,21,34,697,4)),'src_span'(21,27,21,29,693,10)),'src_span'(21,14,21,16,680,23)),'prefix'('src_span'(22,11,22,17,712,6),[],'no_cmd','val_of'('WAIT','src_span'(22,21,22,25,722,4)),'src_span'(22,18,22,20,718,14)),'src_span_operator'('no_loc_info_available','src_span'(22,8,22,10,709,2))),'src_span'(21,1,22,25,668,58)).
'bindval'('WAIT','[]'('prefix'('src_span'(24,8,24,11,735,3),['in'(_c2)],'cmd','prefix'('src_span'(24,17,24,24,744,7),['out'(_c2)],'handled','val_of'('WAIT','src_span'(24,30,24,34,757,4)),'src_span'(24,27,24,29,753,10)),'src_span'(24,14,24,16,740,23)),'prefix'('src_span'(25,11,25,19,772,8),[],'pace_due','val_of'('FS_REQ','src_span'(25,23,25,29,784,6)),'src_span'(25,20,25,22,780,18)),'src_span_operator'('no_loc_info_available','src_span'(25,8,25,10,769,2))),'src_span'(24,1,25,29,728,62)).
'bindval'('COMMAND','repChoice'(['comprehensionGenerator'(_c3,'UserCmd')],'prefix'('src_span'(27,28,27,31,819,3),['out'(_c3)],'cmd','val_of'('COMMAND','src_span'(27,37,27,44,828,7)),'src_span'(27,34,27,36,824,13)),'src_span'(27,14,27,27,805,13)),'src_span'(27,1,27,44,792,43)).
'bindval'('SYSTEM_REQ','sharing'('closure'(['cmd']),'val_of'('FS_REQ','src_span'(29,14,29,20,850,6)),'val_of'('COMMAND','src_span'(29,37,29,44,873,7)),'src_span'(29,21,29,36,857,15)),'src_span'(29,1,29,44,837,43)).
'bindval'('Internal','setExp'('rangeEnum'(['frame','release','no_cmd','pace_due'])),'src_span'(31,1,31,46,882,45)).
'bindval'('CMD_SPEC','prefix'('src_span'(35,12,35,15,1075,3),['in'(_c4)],'cmd','prefix'('src_span'(35,21,35,28,1084,7),['out'(_c4)],'handled','val_of'('CMD_SPEC','src_span'(35,34,35,42,1097,8)),'src_span'(35,31,35,33,1093,14)),'src_span'(35,18,35,20,1080,27)),'src_span'(35,1,35,42,1064,41)).
'assertModelCheckExt'('False','val_of'('SYSTEM_REQ','src_span'(37,8,37,18,1114,10)),'DeadlockFree','F').
'assertRef'('False','val_of'('CMD_SPEC','src_span'(38,8,38,16,1153,8)),'Trace','\x5c\'('val_of'('SYSTEM_REQ','src_span'(38,21,38,31,1166,10)),'val_of'('Internal','src_span'(38,34,38,42,1179,8)),'src_span_operator'('no_loc_info_available','src_span'(38,32,38,33,1177,1))),'src_span'(38,1,38,42,1146,41)).
'assertRef'('False','val_of'('CMD_SPEC','src_span'(39,8,39,16,1195,8)),'Failure','\x5c\'('val_of'('SYSTEM_REQ','src_span'(39,21,39,31,1208,10)),'val_of'('Internal','src_span'(39,34,39,42,1221,8)),'src_span_operator'('no_loc_info_available','src_span'(39,32,39,33,1219,1))),'src_span'(39,1,39,42,1188,41)).
'dataTypeDef'('Var',['constructor'('V_cmd'),'constructor'('V_c')]).
'channel'('bind','type'('dotTupleType'(['Var']))).
'channel'('deliver','type'('dotTupleType'(['UserCmd']))).
'channel'('put','type'('dotTupleType'(['Var','Cmd']))).
'channel'('get','type'('dotTupleType'(['Var','Cmd']))).
'agent'('SLOT'(_t),'[]'('prefix'('src_span'(54,11,54,15,1683,4),['in'(_t2)],'bind','agent_call'('src_span'(54,22,54,26,1694,4),'SLOT',[_t2]),'src_span'(54,19,54,21,1690,15)),'prefix'('src_span'(55,14,55,21,1716,7),['in'(_x)],'deliver','prefix'('src_span'(55,27,55,30,1729,3),['out'(_t),'out'(_x)],'put','agent_call'('src_span'(55,38,55,42,1740,4),'SLOT',[_t]),'src_span'(55,35,55,37,1736,13)),'src_span'(55,24,55,26,1725,24)),'src_span_operator'('no_loc_info_available','src_span'(55,11,55,13,1713,2))),'no_loc_info_available').
'agent'('VAR'(_v,_x2),'[]'('prefix'('src_span'(57,13,57,18,1761,5),['in'(_y)],'dotTuple'(['put',_v]),'agent_call'('src_span'(57,24,57,27,1772,3),'VAR',[_v,_y]),'src_span'(57,21,57,23,1768,15)),'prefix'('src_span'(58,16,58,21,1797,5),['out'(_x2)],'dotTuple'(['get',_v]),'agent_call'('src_span'(58,27,58,30,1808,3),'VAR',[_v,_x2]),'src_span'(58,24,58,26,1804,15)),'src_span_operator'('no_loc_info_available','src_span'(58,13,58,15,1794,2))),'no_loc_info_available').
'bindval'('STORE','sharing'('closure'(['put']),'agent_call'('src_span'(60,9,60,13,1827,4),'SLOT',['V_cmd']),'|||'('agent_call'('src_span'(60,38,60,41,1856,3),'VAR',['V_cmd','Init']),'agent_call'('src_span'(60,59,60,62,1877,3),'VAR',['V_c','Init']),'src_span_operator'('no_loc_info_available','src_span'(60,55,60,58,1873,3))),'src_span'(60,21,60,36,1839,15)),'src_span'(60,1,60,74,1819,73)).
'bindval'('Mechanism','closure'(['bind','deliver','put','get']),'src_span'(62,1,62,42,1894,41)).
'bindval'('FS_BAD','prefix'('src_span'(65,10,65,20,2018,10),[],'dotTuple'(['bind','V_cmd']),'val_of'('LOOP_BAD','src_span'(65,24,65,32,2032,8)),'src_span'(65,21,65,23,2028,22)),'src_span'(65,1,65,32,2009,31)).
'bindval'('LOOP_BAD','prefix'('src_span'(66,12,66,17,2052,5),[],'frame','prefix'('src_span'(66,21,66,28,2061,7),[],'release','val_of'('POLL_BAD','src_span'(66,32,66,40,2072,8)),'src_span'(66,29,66,31,2068,19)),'src_span'(66,18,66,20,2057,28)),'src_span'(66,1,66,40,2041,39)).
'bindval'('POLL_BAD','[]'('prefix'('src_span'(67,12,67,15,2092,3),['in'(_x3)],'cmd','prefix'('src_span'(67,21,67,28,2101,7),['out'(_x3)],'deliver','prefix'('src_span'(67,34,67,37,2114,3),['in'(_),'in'(_)],'put','prefix'('src_span'(67,45,67,54,2125,9),['in'(_y2)],'dotTuple'(['get','V_cmd']),'prefix'('src_span'(67,60,67,67,2140,7),['out'(_y2)],'handled','val_of'('WAIT_BAD0','src_span'(67,73,67,82,2153,9)),'src_span'(67,70,67,72,2149,15)),'src_span'(67,57,67,59,2136,28)),'src_span'(67,42,67,44,2121,43)),'src_span'(67,31,67,33,2110,54)),'src_span'(67,18,67,20,2097,67)),'prefix'('src_span'(68,15,68,21,2177,6),[],'no_cmd','val_of'('WAIT_BAD0','src_span'(68,25,68,34,2187,9)),'src_span'(68,22,68,24,2183,19)),'src_span_operator'('no_loc_info_available','src_span'(68,12,68,14,2174,2))),'src_span'(67,1,68,34,2081,115)).
'bindval'('WAIT_BAD0','prefix'('src_span'(69,13,69,21,2209,8),[],'dotTuple'(['bind','V_c']),'val_of'('WAIT_BAD','src_span'(69,25,69,33,2221,8)),'src_span'(69,22,69,24,2217,20)),'src_span'(69,1,69,33,2197,32)).
'bindval'('WAIT_BAD','[]'('prefix'('src_span'(70,12,70,15,2241,3),['in'(_x4)],'cmd','prefix'('src_span'(70,21,70,28,2250,7),['out'(_x4)],'deliver','prefix'('src_span'(70,34,70,37,2263,3),['in'(_),'in'(_)],'put','prefix'('src_span'(70,45,70,52,2274,7),['in'(_y3)],'dotTuple'(['get','V_c']),'prefix'('src_span'(70,58,70,65,2287,7),['out'(_y3)],'handled','val_of'('WAIT_BAD','src_span'(70,71,70,79,2300,8)),'src_span'(70,68,70,70,2296,14)),'src_span'(70,55,70,57,2283,27)),'src_span'(70,42,70,44,2270,40)),'src_span'(70,31,70,33,2259,51)),'src_span'(70,18,70,20,2246,64)),'prefix'('src_span'(71,15,71,23,2323,8),[],'pace_due','val_of'('LOOP_BAD','src_span'(71,27,71,35,2335,8)),'src_span'(71,24,71,26,2331,20)),'src_span_operator'('no_loc_info_available','src_span'(71,12,71,14,2320,2))),'src_span'(70,1,71,35,2230,113)).
'bindval'('SYSTEM_BAD','sharing'('closure'(['cmd']),'\x5c\'('sharing'('closure'(['bind','deliver','put','get']),'val_of'('FS_BAD','src_span'(73,16,73,22,2360,6)),'val_of'('STORE','src_span'(73,59,73,64,2403,5)),'src_span'(73,23,73,58,2367,35)),'val_of'('Mechanism','src_span'(73,68,73,77,2412,9)),'src_span_operator'('no_loc_info_available','src_span'(73,66,73,67,2410,1))),'val_of'('COMMAND','src_span'(74,30,74,37,2452,7)),'src_span'(74,14,74,29,2436,15)),'src_span'(73,1,74,37,2345,114)).
'assertRef'('False','val_of'('CMD_SPEC','src_span'(77,8,77,16,2540,8)),'Trace','\x5c\'('val_of'('SYSTEM_BAD','src_span'(77,21,77,31,2553,10)),'val_of'('Internal','src_span'(77,34,77,42,2566,8)),'src_span_operator'('no_loc_info_available','src_span'(77,32,77,33,2564,1))),'src_span'(77,1,77,42,2533,41)).
'assertModelCheckExt'('False','val_of'('SYSTEM_BAD','src_span'(78,8,78,18,2582,10)),'DeadlockFree','F').
'bindval'('FS_FIX','prefix'('src_span'(81,10,81,20,2699,10),[],'dotTuple'(['bind','V_cmd']),'val_of'('LOOP_FIX','src_span'(81,24,81,32,2713,8)),'src_span'(81,21,81,23,2709,22)),'src_span'(81,1,81,32,2690,31)).
'bindval'('LOOP_FIX','prefix'('src_span'(82,12,82,17,2733,5),[],'frame','prefix'('src_span'(82,21,82,28,2742,7),[],'release','val_of'('POLL_FIX','src_span'(82,32,82,40,2753,8)),'src_span'(82,29,82,31,2749,19)),'src_span'(82,18,82,20,2738,28)),'src_span'(82,1,82,40,2722,39)).
'bindval'('POLL_FIX','[]'('prefix'('src_span'(83,12,83,15,2773,3),['in'(_x5)],'cmd','prefix'('src_span'(83,21,83,28,2782,7),['out'(_x5)],'deliver','prefix'('src_span'(83,34,83,37,2795,3),['in'(_),'in'(_)],'put','prefix'('src_span'(83,45,83,54,2806,9),['in'(_y4)],'dotTuple'(['get','V_cmd']),'prefix'('src_span'(83,60,83,67,2821,7),['out'(_y4)],'handled','val_of'('WAIT_FIX0','src_span'(83,73,83,82,2834,9)),'src_span'(83,70,83,72,2830,15)),'src_span'(83,57,83,59,2817,28)),'src_span'(83,42,83,44,2802,43)),'src_span'(83,31,83,33,2791,54)),'src_span'(83,18,83,20,2778,67)),'prefix'('src_span'(84,15,84,21,2858,6),[],'no_cmd','val_of'('WAIT_FIX0','src_span'(84,25,84,34,2868,9)),'src_span'(84,22,84,24,2864,19)),'src_span_operator'('no_loc_info_available','src_span'(84,12,84,14,2855,2))),'src_span'(83,1,84,34,2762,115)).
'bindval'('WAIT_FIX0','prefix'('src_span'(85,13,85,23,2890,10),[],'dotTuple'(['bind','V_cmd']),'val_of'('WAIT_FIX','src_span'(85,27,85,35,2904,8)),'src_span'(85,24,85,26,2900,22)),'src_span'(85,1,85,35,2878,34)).
'bindval'('WAIT_FIX','[]'('prefix'('src_span'(86,12,86,15,2924,3),['in'(_x6)],'cmd','prefix'('src_span'(86,21,86,28,2933,7),['out'(_x6)],'deliver','prefix'('src_span'(86,34,86,37,2946,3),['in'(_),'in'(_)],'put','prefix'('src_span'(86,45,86,54,2957,9),['in'(_y5)],'dotTuple'(['get','V_cmd']),'prefix'('src_span'(86,60,86,67,2972,7),['out'(_y5)],'handled','val_of'('WAIT_FIX','src_span'(86,73,86,81,2985,8)),'src_span'(86,70,86,72,2981,14)),'src_span'(86,57,86,59,2968,27)),'src_span'(86,42,86,44,2953,42)),'src_span'(86,31,86,33,2942,53)),'src_span'(86,18,86,20,2929,66)),'prefix'('src_span'(87,15,87,23,3008,8),[],'pace_due','val_of'('LOOP_FIX','src_span'(87,27,87,35,3020,8)),'src_span'(87,24,87,26,3016,20)),'src_span_operator'('no_loc_info_available','src_span'(87,12,87,14,3005,2))),'src_span'(86,1,87,35,2913,115)).
'bindval'('SYSTEM_FIX','sharing'('closure'(['cmd']),'\x5c\'('sharing'('closure'(['bind','deliver','put','get']),'val_of'('FS_FIX','src_span'(89,16,89,22,3045,6)),'val_of'('STORE','src_span'(89,59,89,64,3088,5)),'src_span'(89,23,89,58,3052,35)),'val_of'('Mechanism','src_span'(89,68,89,77,3097,9)),'src_span_operator'('no_loc_info_available','src_span'(89,66,89,67,3095,1))),'val_of'('COMMAND','src_span'(90,30,90,37,3137,7)),'src_span'(90,14,90,29,3121,15)),'src_span'(89,1,90,37,3030,114)).
'assertRef'('False','val_of'('CMD_SPEC','src_span'(93,8,93,16,3173,8)),'Trace','\x5c\'('val_of'('SYSTEM_FIX','src_span'(93,21,93,31,3186,10)),'val_of'('Internal','src_span'(93,34,93,42,3199,8)),'src_span_operator'('no_loc_info_available','src_span'(93,32,93,33,3197,1))),'src_span'(93,1,93,42,3166,41)).
'assertRef'('False','val_of'('CMD_SPEC','src_span'(94,8,94,16,3215,8)),'Failure','\x5c\'('val_of'('SYSTEM_FIX','src_span'(94,21,94,31,3228,10)),'val_of'('Internal','src_span'(94,34,94,42,3241,8)),'src_span_operator'('no_loc_info_available','src_span'(94,32,94,33,3239,1))),'src_span'(94,1,94,42,3208,41)).
'assertModelCheckExt'('False','val_of'('SYSTEM_FIX','src_span'(95,8,95,18,3257,10)),'DeadlockFree','F').
'comment'('lineComment'('-- FileSource: command handling with two alternations'),'src_position'(1,1,0,53)).
'comment'('lineComment'('-- Part 1 is the requirements model. Parts 2 and 3 show that the requirement'),'src_position'(2,1,54,76)).
'comment'('lineComment'('-- distinguishes the defective binding from the workaround.'),'src_position'(3,1,131,59)).
'comment'('lineComment'('-- ===================== Part 1: requirements model ====================='),'src_position'(14,1,365,73)).
'comment'('lineComment'('-- After each frame, FileSource offers a command or moves on at once (poll).'),'src_position'(15,1,439,76)).
'comment'('lineComment'('-- Then it waits for the pace deadline, still accepting commands (wait).'),'src_position'(16,1,516,72)).
'comment'('lineComment'('-- Both alternations are external choices.'),'src_position'(17,1,589,42)).
'comment'('lineComment'('-- Requirement: every command FileSource accepts is acted on, with exactly'),'src_position'(33,1,929,74)).
'comment'('lineComment'('-- the value accepted, before the next command is accepted.'),'src_position'(34,1,1004,59)).
'comment'('lineComment'('-- ============ Part 2: one binding slot per channel end =============='),'src_position'(41,1,1231,71)).
'comment'('lineComment'('-- Abstract mechanism: the channel end has one slot that remembers the'),'src_position'(42,1,1303,70)).
'comment'('lineComment'('-- variable the latest alternation bound it to. A value taken from the'),'src_position'(43,1,1374,70)).
'comment'('lineComment'('-- channel goes into that variable (put) before the input completes; each'),'src_position'(44,1,1445,73)).
'comment'('lineComment'('-- alternation then reads its own.'),'src_position'(45,1,1519,34)).
'comment'('lineComment'('-- Defective: the poll binds to cmd once; each wait binds to its own c.'),'src_position'(64,1,1937,71)).
'comment'('lineComment'('-- Expected to FAIL: counterexample (visible) cmd.Restart, handled.Init'),'src_position'(76,1,2461,71)).
'comment'('lineComment'('-- ============ Part 3: workaround, both bind the same variable =========='),'src_position'(80,1,2615,74)).
'comment'('lineComment'('-- Expected to hold'),'src_position'(92,1,3146,19)).
'symbol'('Cmd','Cmd','src_span'(5,10,5,13,201,3),'Datatype').
'symbol'('Restart','Restart','src_span'(5,16,5,23,207,7),'Constructor of Datatype').
'symbol'('Pace','Pace','src_span'(5,26,5,30,217,4),'Constructor of Datatype').
'symbol'('Init','Init','src_span'(5,33,5,37,224,4),'Constructor of Datatype').
'symbol'('UserCmd','UserCmd','src_span'(6,10,6,17,238,7),'Nametype').
'symbol'('frame','frame','src_span'(8,9,8,14,273,5),'Channel').
'symbol'('release','release','src_span'(8,16,8,23,280,7),'Channel').
'symbol'('cmd','cmd','src_span'(9,9,9,12,296,3),'Channel').
'symbol'('no_cmd','no_cmd','src_span'(10,9,10,15,318,6),'Channel').
'symbol'('pace_due','pace_due','src_span'(11,9,11,17,333,8),'Channel').
'symbol'('handled','handled','src_span'(12,9,12,16,350,7),'Channel').
'symbol'('FS_REQ','FS_REQ','src_span'(19,1,19,7,633,6),'Ident (Groundrep.)').
'symbol'('POLL','POLL','src_span'(21,1,21,5,668,4),'Ident (Groundrep.)').
'symbol'('c','c','src_span'(21,12,21,13,679,1),'Ident (Prolog Variable)').
'symbol'('WAIT','WAIT','src_span'(24,1,24,5,728,4),'Ident (Groundrep.)').
'symbol'('c2','c','src_span'(24,12,24,13,739,1),'Ident (Prolog Variable)').
'symbol'('COMMAND','COMMAND','src_span'(27,1,27,8,792,7),'Ident (Groundrep.)').
'symbol'('c3','c','src_span'(27,14,27,15,805,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM_REQ','SYSTEM_REQ','src_span'(29,1,29,11,837,10),'Ident (Groundrep.)').
'symbol'('Internal','Internal','src_span'(31,1,31,9,882,8),'Ident (Groundrep.)').
'symbol'('CMD_SPEC','CMD_SPEC','src_span'(35,1,35,9,1064,8),'Ident (Groundrep.)').
'symbol'('c4','c','src_span'(35,16,35,17,1079,1),'Ident (Prolog Variable)').
'symbol'('Var','Var','src_span'(47,10,47,13,1564,3),'Datatype').
'symbol'('V_cmd','V_cmd','src_span'(47,16,47,21,1570,5),'Constructor of Datatype').
'symbol'('V_c','V_c','src_span'(47,24,47,27,1578,3),'Constructor of Datatype').
'symbol'('bind','bind','src_span'(49,9,49,13,1591,4),'Channel').
'symbol'('deliver','deliver','src_span'(50,9,50,16,1610,7),'Channel').
'symbol'('put','put','src_span'(51,9,51,12,1636,3),'Channel').
'symbol'('get','get','src_span'(52,9,52,12,1658,3),'Channel').
'symbol'('SLOT','SLOT','src_span'(54,1,54,5,1673,4),'Funktion or Process').
'symbol'('t','t','src_span'(54,6,54,7,1678,1),'Ident (Prolog Variable)').
'symbol'('t2','t2','src_span'(54,16,54,18,1688,2),'Ident (Prolog Variable)').
'symbol'('x','x','src_span'(55,22,55,23,1724,1),'Ident (Prolog Variable)').
'symbol'('VAR','VAR','src_span'(57,1,57,4,1749,3),'Funktion or Process').
'symbol'('v','v','src_span'(57,5,57,6,1753,1),'Ident (Prolog Variable)').
'symbol'('x2','x','src_span'(57,8,57,9,1756,1),'Ident (Prolog Variable)').
'symbol'('y','y','src_span'(57,19,57,20,1767,1),'Ident (Prolog Variable)').
'symbol'('STORE','STORE','src_span'(60,1,60,6,1819,5),'Ident (Groundrep.)').
'symbol'('Mechanism','Mechanism','src_span'(62,1,62,10,1894,9),'Ident (Groundrep.)').
'symbol'('FS_BAD','FS_BAD','src_span'(65,1,65,7,2009,6),'Ident (Groundrep.)').
'symbol'('LOOP_BAD','LOOP_BAD','src_span'(66,1,66,9,2041,8),'Ident (Groundrep.)').
'symbol'('POLL_BAD','POLL_BAD','src_span'(67,1,67,9,2081,8),'Ident (Groundrep.)').
'symbol'('x3','x','src_span'(67,16,67,17,2096,1),'Ident (Prolog Variable)').
'symbol'('y2','y','src_span'(67,55,67,56,2135,1),'Ident (Prolog Variable)').
'symbol'('WAIT_BAD0','WAIT_BAD0','src_span'(69,1,69,10,2197,9),'Ident (Groundrep.)').
'symbol'('WAIT_BAD','WAIT_BAD','src_span'(70,1,70,9,2230,8),'Ident (Groundrep.)').
'symbol'('x4','x','src_span'(70,16,70,17,2245,1),'Ident (Prolog Variable)').
'symbol'('y3','y','src_span'(70,53,70,54,2282,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM_BAD','SYSTEM_BAD','src_span'(73,1,73,11,2345,10),'Ident (Groundrep.)').
'symbol'('FS_FIX','FS_FIX','src_span'(81,1,81,7,2690,6),'Ident (Groundrep.)').
'symbol'('LOOP_FIX','LOOP_FIX','src_span'(82,1,82,9,2722,8),'Ident (Groundrep.)').
'symbol'('POLL_FIX','POLL_FIX','src_span'(83,1,83,9,2762,8),'Ident (Groundrep.)').
'symbol'('x5','x','src_span'(83,16,83,17,2777,1),'Ident (Prolog Variable)').
'symbol'('y4','y','src_span'(83,55,83,56,2816,1),'Ident (Prolog Variable)').
'symbol'('WAIT_FIX0','WAIT_FIX0','src_span'(85,1,85,10,2878,9),'Ident (Groundrep.)').
'symbol'('WAIT_FIX','WAIT_FIX','src_span'(86,1,86,9,2913,8),'Ident (Groundrep.)').
'symbol'('x6','x','src_span'(86,16,86,17,2928,1),'Ident (Prolog Variable)').
'symbol'('y5','y','src_span'(86,55,86,56,2967,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM_FIX','SYSTEM_FIX','src_span'(89,1,89,11,3030,10),'Ident (Groundrep.)').