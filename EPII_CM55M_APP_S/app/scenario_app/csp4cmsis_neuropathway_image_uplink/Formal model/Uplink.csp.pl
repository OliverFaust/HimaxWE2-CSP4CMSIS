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
'bindval'('W','int'(2),'src_span'(17,1,17,14,1237,13)).
'bindval'('MAX_INDEX','int'(2),'src_span'(18,1,18,14,1251,13)).
'bindval'('IDS','setExp'('rangeClosed'('int'(0),'int'(3))),'src_span'(19,1,19,19,1265,18)).
'bindval'('NONE','int'(4),'src_span'(20,1,20,14,1284,13)).
'bindval'('MAXM','int'(2),'src_span'(21,1,21,14,1344,13)).
'agent'('sat'(_m),'ifte'('>'(_m,'val_of'('MAXM','src_span'(23,17,23,21,1375,4))),'val_of'('MAXM','src_span'(23,27,23,31,1385,4)),_m,'src_span'(23,10,23,21,1368,11),'src_span'(23,22,23,26,1379,18),'src_span'(23,32,23,36,1389,11)),'src_span'(23,10,23,38,1368,28)).
'dataTypeDef'('source_t',['constructor'('camera'),'constructor'('inference')]).
'dataTypeDef'('outcome_t',['constructor'('better'),'constructor'('worse'),'constructor'('failed')]).
'dataTypeDef'('report_t',['constructorC'('started','dotTupleType'(['source_t'])),'constructor'('stack'),'constructor'('scores'),'constructorC'('window','dotTupleType'(['setExp'('rangeClosed'('int'(0),'val_of'('MAXM','src_span'(27,69,27,73,1600,4))))])),'constructorC'('wimage','dotTupleType'(['setExp'('rangeClosed'('int'(0),'val_of'('MAXM','src_span'(27,88,27,92,1619,4)))),'val_of'('IDS','src_span'(27,94,27,97,1625,3))]))]).
'bindval'('INF_TEXT','agent_call'('src_span'(29,12,29,17,1641,5),'union',['setExp'('rangeEnum'(['scores'])),'setExp'('rangeEnum'(['dotTuple'(['window',_m2])]),['comprehensionGenerator'(_m2,'setExp'('rangeClosed'('int'(0),'val_of'('MAXM','src_span'(29,49,29,53,1678,4)))))])]),'src_span'(29,1,29,56,1630,55)).
'bindval'('OTHER','setExp'('rangeEnum'(['dotTuple'(['started','camera']),'dotTuple'(['started','inference']),'stack'])),'src_span'(30,1,30,54,1734,53)).
'channel'('g_trigger_chan','type'('dotUnitType')).
'channel'('frame_chan','type'('dotTupleType'(['setExp'('rangeClosed'('int'(0),'-'('val_of'('MAX_INDEX','src_span'(33,28,33,37,1898,9)),'int'(1)))),'val_of'('IDS','src_span'(33,41,33,44,1911,3))]))).
'channel'('release_chan','type'('dotTupleType'(['val_of'('IDS','src_span'(34,24,34,27,1989,3))]))).
'channel'('free_in','type'('dotTupleType'(['val_of'('IDS','src_span'(35,24,35,27,2093,3))]))).
'channel'('free_out','type'('dotTupleType'(['val_of'('IDS','src_span'(36,24,36,27,2172,3))]))).
'channel'('poll_empty','type'('dotUnitType')).
'channel'('ready_in','type'('dotUnitType')).
'channel'('ready_out','type'('dotUnitType')).
'channel'('ready_empty','type'('dotUnitType')).
'channel'('report_chan','type'('dotTupleType'(['report_t']))).
'channel'('line','type'('dotTupleType'(['report_t']))).
'channel'('uplink','type'('dotTupleType'(['val_of'('IDS','src_span'(43,24,43,27,2816,3))]))).
'channel'('scored','type'('dotTupleType'(['outcome_t','val_of'('IDS','src_span'(44,34,44,37,2919,3))]))).
'channel'('suppress','type'('dotTupleType'(['val_of'('IDS','src_span'(45,24,45,27,3005,3))]))).
'channel'('merge','type'('dotUnitType')).
'channel'('camera_log','type'('dotUnitType')).
'channel'('stack_tick','type'('dotUnitType')).
'channel'('overflow','type'('dotUnitType')).
'channel'('error','type'('dotUnitType')).
'bindval'('ENV','prefix'('src_span'(50,7,50,21,3247,14),[],'g_trigger_chan','val_of'('ENV','src_span'(50,25,50,28,3265,3)),'src_span'(50,22,50,24,3261,21)),'src_span'(50,1,50,28,3241,27)).
'agent'('RUN'(_A),'repChoice'(['comprehensionGenerator'(_x,_A)],'prefix'('src_span'(52,21,52,22,3290,1),[],_x,'agent_call'('src_span'(52,26,52,29,3295,3),'RUN',[_A]),'src_span'(52,23,52,25,3291,11)),'src_span'(52,13,52,20,3282,7)),'src_span'(52,10,52,32,3279,22)).
'bindval'('Camera','prefix'('src_span'(55,10,55,20,3399,10),[],'camera_log','prefix'('src_span'(55,24,55,35,3413,11),['out'('dotTuple'(['started','camera']))],'report_chan','agent_call'('src_span'(55,54,55,64,3443,10),'CameraLoop',['int'(0),'int'(0)]),'src_span'(55,51,55,53,3439,35)),'src_span'(55,21,55,23,3409,60)),'src_span'(55,1,55,70,3390,69)).
'agent'('CameraLoop'(_i,_b),'prefix'('src_span'(56,20,56,34,3479,14),[],'g_trigger_chan','prefix'('src_span'(56,38,56,48,3497,10),['out'(_i),'out'(_b)],'frame_chan','prefix'('src_span'(56,56,56,68,3515,12),['in'(_nb)],'release_chan','agent_call'('src_span'(56,75,56,85,3534,10),'CameraLoop',['%'('+'(_i,'int'(1)),'val_of'('MAX_INDEX','src_span'(56,96,56,105,3555,9))),_nb]),'src_span'(56,72,56,74,3530,42)),'src_span'(56,53,56,55,3511,60)),'src_span'(56,35,56,37,3493,90)),'src_span'(56,20,56,110,3479,90)).
'bindval'('Inference','prefix'('src_span'(62,13,62,23,3932,10),['in'(_i2),'in'(_p)],'frame_chan','prefix'('src_span'(62,31,62,42,3950,11),['out'('dotTuple'(['started','inference']))],'report_chan','agent_call'('src_span'(62,64,62,69,3983,5),'Infer',[_i2,_p,'agent_call'('src_span'(62,76,62,80,3995,4),'diff',['val_of'('IDS','src_span'(62,81,62,84,4000,3)),'setExp'('rangeEnum'([_p]))]),'val_of'('NONE','src_span'(62,92,62,96,4011,4)),'true','true','int'(0)]),'src_span'(62,61,62,63,3979,70)),'src_span'(62,28,62,30,3946,87)),'src_span'(62,1,62,112,3920,111)).
'agent'('Infer'(_i3,_p2,_sp,_best,_tok,_rdy,_m3),'[]'('prefix'('src_span'(65,6,65,14,4075,8),['in'(_b2)],'free_out','agent_call'('src_span'(65,20,65,29,4089,9),'PollReady',[_i3,_p2,'agent_call'('src_span'(65,36,65,41,4105,5),'union',[_sp,'setExp'('rangeEnum'([_b2]))]),_best,'true',_rdy,_m3]),'src_span'(65,17,65,19,4085,57)),'prefix'('src_span'(66,9,66,19,4150,10),[],'poll_empty','agent_call'('src_span'(66,23,66,32,4164,9),'PollReady',[_i3,_p2,_sp,_best,_tok,_rdy,_m3]),'src_span'(66,20,66,22,4160,52)),'src_span_operator'('no_loc_info_available','src_span'(66,5,66,7,4146,2))),'no_loc_info_available').
'agent'('PollReady'(_i4,_p3,_sp2,_best2,_tok2,_rdy2,_m4),'[]'('prefix'('src_span'(69,6,69,15,4251,9),[],'ready_out','agent_call'('src_span'(69,19,69,26,4264,7),'Release',[_i4,_p3,_sp2,_best2,_tok2,'true',_m4]),'src_span'(69,16,69,18,4260,50)),'prefix'('src_span'(70,9,70,20,4311,11),[],'ready_empty','agent_call'('src_span'(70,24,70,31,4326,7),'Release',[_i4,_p3,_sp2,_best2,_tok2,_rdy2,_m4]),'src_span'(70,21,70,23,4322,51)),'src_span_operator'('no_loc_info_available','src_span'(70,5,70,7,4307,2))),'no_loc_info_available').
'agent'('Release'(_i5,_p4,_sp3,_best3,_tok3,_rdy3,_m5),'repInternalChoice'(['comprehensionGenerator'(_s,_sp3)],'prefix'('src_span'(73,18,73,30,4421,12),['out'(_s)],'release_chan','agent_call'('src_span'(73,36,73,41,4439,5),'Score',[_i5,_p4,'agent_call'('src_span'(73,48,73,52,4451,4),'diff',[_sp3,'setExp'('rangeEnum'([_s]))]),_best3,_tok3,_rdy3,_m5]),'src_span'(73,33,73,35,4435,51)),'src_span'(73,9,73,17,4412,8)),'src_span'(73,5,73,81,4408,76)).
'agent'('Score'(_i6,_p5,_sp4,_best4,_tok4,_rdy4,_m6),'ifte'('=='(_best4,'val_of'('NONE','src_span'(76,16,76,20,4538,4))),'|~|'('prefix'('src_span'(77,10,77,16,4557,6),['out'('failed'),'out'(_p5)],'scored','agent_call'('src_span'(77,29,77,32,4576,3),'End',[_i6,'agent_call'('src_span'(77,36,77,41,4583,5),'union',[_sp4,'setExp'('rangeEnum'([_p5]))]),_best4,_tok4,_rdy4,_m6]),'src_span'(77,26,77,28,4572,47)),'prefix'('src_span'(78,14,78,20,4632,6),['out'('better'),'out'(_p5)],'scored','agent_call'('src_span'(78,33,78,36,4651,3),'End',[_i6,_sp4,_p5,_tok4,_rdy4,_m6]),'src_span'(78,30,78,32,4647,32)),'src_span_operator'('no_loc_info_available','src_span'(78,9,78,12,4627,3))),'|~|'('|~|'('prefix'('src_span'(80,10,80,16,4697,6),['out'('failed'),'out'(_p5)],'scored','agent_call'('src_span'(80,29,80,32,4716,3),'End',[_i6,'agent_call'('src_span'(80,36,80,41,4723,5),'union',[_sp4,'setExp'('rangeEnum'([_p5]))]),_best4,_tok4,_rdy4,_m6]),'src_span'(80,26,80,28,4712,47)),'prefix'('src_span'(81,14,81,20,4772,6),['out'('better'),'out'(_p5)],'scored','agent_call'('src_span'(81,33,81,36,4791,3),'End',[_i6,'agent_call'('src_span'(81,40,81,45,4798,5),'union',[_sp4,'setExp'('rangeEnum'([_best4]))]),_p5,_tok4,_rdy4,_m6]),'src_span'(81,30,81,32,4787,47)),'src_span_operator'('no_loc_info_available','src_span'(81,9,81,12,4767,3))),'prefix'('src_span'(82,14,82,20,4847,6),['out'('worse'),'out'(_p5)],'scored','agent_call'('src_span'(82,32,82,35,4865,3),'End',[_i6,'agent_call'('src_span'(82,39,82,44,4872,5),'union',[_sp4,'setExp'('rangeEnum'([_p5]))]),_best4,_tok4,_rdy4,_m6]),'src_span'(82,29,82,31,4861,47)),'src_span_operator'('no_loc_info_available','src_span'(82,9,82,12,4842,3))),'no_loc_info_available','no_loc_info_available','no_loc_info_available'),'src_span'(76,5,82,74,4527,380)).
'agent'('End'(_i7,_sp5,_best5,_tok5,_rdy5,_m7),'ifte'(_rdy5,'ifte'('bool_and'('=='('%'(_i7,'val_of'('W','src_span'(88,16,88,17,5141,1))),'-'('val_of'('W','src_span'(88,21,88,22,5146,1)),'int'(1))),_tok5),'ifte'('=='(_best5,'val_of'('NONE','src_span'(89,24,89,28,5188,4))),'prefix'('src_span'(89,34,89,45,5198,11),['out'('dotTuple'(['window',_m7]))],'report_chan','agent_call'('src_span'(89,58,89,62,5222,4),'Next',[_sp5,'val_of'('NONE','src_span'(89,67,89,71,5231,4)),_tok5,'false','int'(0)]),'src_span'(89,55,89,57,5218,42)),'|~|'('prefix'('src_span'(90,19,90,30,5270,11),['out'('dotTuple'(['wimage',_m7,_best5]))],'report_chan','agent_call'('src_span'(90,48,90,52,5299,4),'Next',[_sp5,'val_of'('NONE','src_span'(90,57,90,61,5308,4)),'false','false','int'(0)]),'src_span'(90,45,90,47,5295,49)),'prefix'('src_span'(91,23,91,31,5354,8),['out'(_best5)],'suppress','prefix'('src_span'(91,40,91,51,5371,11),['out'('dotTuple'(['window',_m7]))],'report_chan','agent_call'('src_span'(91,64,91,68,5395,4),'Next',['agent_call'('src_span'(91,69,91,74,5400,5),'union',[_sp5,'setExp'('rangeEnum'([_best5]))]),'val_of'('NONE','src_span'(91,88,91,92,5419,4)),_tok5,'false','int'(0)]),'src_span'(91,61,91,63,5391,57)),'src_span'(91,37,91,39,5367,77)),'src_span_operator'('no_loc_info_available','src_span'(91,18,91,21,5349,3))),'no_loc_info_available','no_loc_info_available','no_loc_info_available'),'ifte'('=='('%'(_i7,'val_of'('W','src_span'(92,21,92,22,5461,1))),'-'('val_of'('W','src_span'(92,26,92,27,5466,1)),'int'(1))),'prefix'('src_span'(93,13,93,18,5489,5),[],'merge','prefix'('src_span'(93,22,93,33,5498,11),['out'('scores')],'report_chan','agent_call'('src_span'(93,44,93,48,5520,4),'Next',[_sp5,_best5,_tok5,'false','agent_call'('src_span'(93,71,93,74,5547,3),'sat',['+'(_m7,'int'(1))])]),'src_span'(93,41,93,43,5516,49)),'src_span'(93,19,93,21,5494,69)),'prefix'('src_span'(95,13,95,24,5584,11),['out'('scores')],'report_chan','agent_call'('src_span'(95,35,95,39,5606,4),'Next',[_sp5,_best5,_tok5,'false',_m7]),'src_span'(95,32,95,34,5602,40)),'no_loc_info_available','no_loc_info_available','src_span'(93,83,95,12,5558,146)),'no_loc_info_available','no_loc_info_available','src_span'(91,110,92,13,5440,458)),'ifte'('=='('%'(_i7,'val_of'('W','src_span'(96,17,96,18,5652,1))),'-'('val_of'('W','src_span'(96,22,96,23,5657,1)),'int'(1))),'prefix'('src_span'(97,9,97,14,5676,5),[],'merge','agent_call'('src_span'(97,18,97,22,5685,4),'Next',[_sp5,_best5,_tok5,_rdy5,'agent_call'('src_span'(97,43,97,46,5710,3),'sat',['+'(_m7,'int'(1))])]),'src_span'(97,15,97,17,5681,45)),'agent_call'('src_span'(99,9,99,13,5739,4),'Next',[_sp5,_best5,_tok5,_rdy5,_m7]),'no_loc_info_available','no_loc_info_available','src_span'(97,55,99,8,5721,90)),'src_span'(87,5,87,11,5114,6),'src_span'(87,12,88,8,5120,518),'src_span'(95,65,96,9,5635,632)),'src_span'(87,5,99,36,5114,652)).
'agent'('Next'(_sp6,_best6,_tok6,_rdy6,_m8),'prefix'('src_span'(101,31,101,41,5798,10),['in'(_j),'in'(_p6)],'frame_chan','agent_call'('src_span'(101,49,101,54,5816,5),'Infer',[_j,_p6,_sp6,_best6,_tok6,_rdy6,_m8]),'src_span'(101,46,101,48,5812,40)),'src_span'(101,31,101,83,5798,52)).
'bindval'('FREE','[]'('prefix'('src_span'(106,9,106,16,6101,7),['in'(_b3)],'free_in','agent_call'('src_span'(106,22,106,31,6114,9),'FREE_FULL',[_b3]),'src_span'(106,19,106,21,6110,18)),'prefix'('src_span'(106,40,106,50,6132,10),[],'poll_empty','val_of'('FREE','src_span'(106,54,106,58,6146,4)),'src_span'(106,51,106,53,6142,18)),'src_span_operator'('no_loc_info_available','src_span'(106,36,106,38,6128,2))),'src_span'(106,1,106,59,6093,58)).
'agent'('FREE_FULL'(_b4),'[]'('prefix'('src_span'(107,17,107,25,6168,8),['out'(_b4)],'free_out','val_of'('FREE','src_span'(107,31,107,35,6182,4)),'src_span'(107,28,107,30,6178,10)),'prefix'('src_span'(107,41,107,48,6192,7),['in'(_x2)],'free_in','prefix'('src_span'(107,54,107,62,6205,8),[],'overflow','stop'('src_span'(107,66,107,70,6217,4)),'src_span'(107,63,107,65,6213,16)),'src_span'(107,51,107,53,6201,22)),'src_span_operator'('no_loc_info_available','src_span'(107,37,107,39,6188,2))),'no_loc_info_available').
'bindval'('READY','[]'('prefix'('src_span'(109,10,109,18,6233,8),[],'ready_in','val_of'('READY_FULL','src_span'(109,22,109,32,6245,10)),'src_span'(109,19,109,21,6241,22)),'prefix'('src_span'(109,38,109,49,6261,11),[],'ready_empty','val_of'('READY','src_span'(109,53,109,58,6276,5)),'src_span'(109,50,109,52,6272,20)),'src_span_operator'('no_loc_info_available','src_span'(109,34,109,36,6257,2))),'src_span'(109,1,109,59,6224,58)).
'bindval'('READY_FULL','[]'('prefix'('src_span'(110,15,110,24,6297,9),[],'ready_out','val_of'('READY','src_span'(110,28,110,33,6310,5)),'src_span'(110,25,110,27,6306,18)),'prefix'('src_span'(110,39,110,47,6321,8),[],'ready_in','prefix'('src_span'(110,51,110,59,6333,8),[],'overflow','stop'('src_span'(110,63,110,67,6345,4)),'src_span'(110,60,110,62,6341,16)),'src_span'(110,48,110,50,6329,28)),'src_span_operator'('no_loc_info_available','src_span'(110,35,110,37,6317,2))),'src_span'(110,1,110,68,6283,67)).
'bindval'('MainApp','prefix'('src_span'(113,11,113,21,6456,10),[],'stack_tick','prefix'('src_span'(113,25,113,36,6470,11),['out'('stack')],'report_chan','val_of'('MainApp','src_span'(113,46,113,53,6491,7)),'src_span'(113,43,113,45,6487,17)),'src_span'(113,22,113,24,6466,42)),'src_span'(113,1,113,53,6446,52)).
'agent'('MainAppN'(_n),'ifte'('=='(_n,'int'(0)),'stop'('src_span'(114,30,114,34,6528,4)),'prefix'('src_span'(114,40,114,50,6538,10),[],'stack_tick','prefix'('src_span'(114,54,114,65,6552,11),['out'('stack')],'report_chan','agent_call'('src_span'(114,75,114,83,6573,8),'MainAppN',['-'(_n,'int'(1))]),'src_span'(114,72,114,74,6569,25)),'src_span'(114,51,114,53,6548,50)),'no_loc_info_available','no_loc_info_available','src_span'(114,35,114,39,6532,60)),'src_span'(114,15,114,90,6513,75)).
'bindval'('Reporter','[]'('[]'('prefix'('src_span'(118,13,118,24,6783,11),['inGuard'(_r,'val_of'('INF_TEXT','src_span'(118,27,118,35,6797,8)))],'report_chan','prefix'('src_span'(118,39,118,43,6809,4),['out'(_r)],'line','prefix'('src_span'(118,49,118,57,6819,8),[],'ready_in','val_of'('Reporter','src_span'(118,61,118,69,6831,8)),'src_span'(118,58,118,60,6827,20)),'src_span'(118,46,118,48,6815,26)),'src_span'(118,36,118,38,6805,45)),'prefix'('src_span'(119,16,119,27,6856,11),['inGuard'(_r2,'val_of'('OTHER','src_span'(119,30,119,35,6870,5)))],'report_chan','prefix'('src_span'(119,39,119,43,6879,4),['out'(_r2)],'line','val_of'('Reporter','src_span'(119,49,119,57,6889,8)),'src_span'(119,46,119,48,6885,14)),'src_span'(119,36,119,38,6875,30)),'src_span_operator'('no_loc_info_available','src_span'(119,12,119,14,6852,2))),'prefix'('src_span'(120,16,120,34,6914,18),['in'(_m9),'in'(_b5)],'dotTuple'(['report_chan','wimage']),'prefix'('src_span'(120,42,120,46,6940,4),['out'('dotTuple'(['window',_m9]))],'line','prefix'('src_span'(120,59,120,65,6957,6),['out'(_b5)],'uplink','prefix'('src_span'(120,71,120,78,6969,7),['out'(_b5)],'free_in','prefix'('src_span'(120,84,120,92,6982,8),[],'ready_in','val_of'('Reporter','src_span'(120,96,120,104,6994,8)),'src_span'(120,93,120,95,6990,20)),'src_span'(120,81,120,83,6978,26)),'src_span'(120,68,120,70,6965,39)),'src_span'(120,56,120,58,6953,58)),'src_span'(120,39,120,41,6936,68)),'src_span_operator'('no_loc_info_available','src_span'(120,12,120,14,6910,2))),'src_span'(118,1,120,105,6771,232)).
'bindval'('ReporterStall','[]'('[]'('prefix'('src_span'(124,18,124,29,7191,11),['inGuard'(_r3,'val_of'('INF_TEXT','src_span'(124,32,124,40,7205,8)))],'report_chan','prefix'('src_span'(124,44,124,48,7217,4),['out'(_r3)],'line','|~|'('prefix'('src_span'(124,56,124,64,7229,8),[],'ready_in','val_of'('ReporterStall','src_span'(124,68,124,81,7241,13)),'src_span'(124,65,124,67,7237,25)),'stop'('src_span'(124,87,124,91,7260,4)),'src_span_operator'('no_loc_info_available','src_span'(124,83,124,86,7256,3))),'src_span'(124,51,124,53,7223,44)),'src_span'(124,41,124,43,7213,63)),'prefix'('src_span'(125,21,125,32,7287,11),['inGuard'(_r4,'val_of'('OTHER','src_span'(125,35,125,40,7301,5)))],'report_chan','prefix'('src_span'(125,44,125,48,7310,4),['out'(_r4)],'line','val_of'('ReporterStall','src_span'(125,54,125,67,7320,13)),'src_span'(125,51,125,53,7316,19)),'src_span'(125,41,125,43,7306,35)),'src_span_operator'('no_loc_info_available','src_span'(125,17,125,19,7283,2))),'prefix'('src_span'(126,21,126,39,7355,18),['in'(_m148),'in'(_b6)],'dotTuple'(['report_chan','wimage']),'prefix'('src_span'(126,47,126,51,7381,4),['out'('dotTuple'(['window',_m148]))],'line','prefix'('src_span'(126,64,126,70,7398,6),['out'(_b6)],'uplink','|~|'('prefix'('src_span'(127,23,127,30,7432,7),['out'(_b6)],'free_in','prefix'('src_span'(127,36,127,44,7445,8),[],'ready_in','val_of'('ReporterStall','src_span'(127,48,127,61,7457,13)),'src_span'(127,45,127,47,7453,25)),'src_span'(127,33,127,35,7441,31)),'stop'('src_span'(127,67,127,71,7476,4)),'src_span_operator'('no_loc_info_available','src_span'(127,63,127,66,7472,3))),'src_span'(126,73,127,20,7406,77)),'src_span'(126,61,126,63,7394,96)),'src_span'(126,44,126,46,7377,106)),'src_span_operator'('no_loc_info_available','src_span'(126,17,126,19,7351,2))),'src_span'(124,1,127,73,7174,308)).
'agent'('PIPE'(_Inf),'sharing'('closure'(['frame_chan','release_chan']),'val_of'('Camera','src_span'(129,17,129,23,7500,6)),_Inf,'src_span'(129,24,129,60,7507,36)),'src_span'(129,24,129,60,7507,36)).
'agent'('NETWORK'(_Inf2,_Rep,_Main),'sharing'('closure'(['ready_in','ready_out','ready_empty']),'sharing'('closure'(['free_in','free_out','poll_empty']),'sharing'('closure'(['report_chan']),'|||'('agent_call'('src_span'(131,8,131,12,7581,4),'PIPE',[_Inf2]),_Main,'src_span_operator'('no_loc_info_available','src_span'(131,18,131,21,7591,3))),_Rep,'src_span'(131,28,131,51,7601,23)),'val_of'('FREE','src_span'(132,48,132,52,7677,4)),'src_span'(132,6,132,47,7635,41)),'val_of'('READY','src_span'(133,50,133,55,7732,5)),'src_span'(133,5,133,49,7687,44)),'src_span'(133,5,133,49,7687,44)).
'agent'('SYS'(_Inf3,_Rep2,_Main2),'sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(134,23,134,26,7760,3)),'agent_call'('src_span'(134,54,134,61,7791,7),'NETWORK',[_Inf3,_Rep2,_Main2]),'src_span'(134,27,134,53,7764,26)),'src_span'(134,27,134,53,7764,26)).
'bindval'('CYCLE','prefix'('src_span'(136,9,136,23,7824,14),[],'g_trigger_chan','val_of'('CYCLE','src_span'(136,27,136,32,7842,5)),'src_span'(136,24,136,26,7838,23)),'src_span'(136,1,136,32,7816,31)).
'agent'('OBS'(_cam,_pend,_best7,_sp7,_send,_slot),'[]'('[]'('[]'('[]'('[]'('[]'('prefix'('src_span'(145,6,145,16,8389,10),['in'(_i8),'in'(_b7)],'frame_chan','ifte'('=='(_b7,_cam),'agent_call'('src_span'(145,42,145,45,8425,3),'OBS',['val_of'('NONE','src_span'(145,46,145,50,8429,4)),_b7,_best7,_sp7,_send,_slot]),'prefix'('src_span'(145,82,145,87,8465,5),[],'error','stop'('src_span'(145,91,145,95,8474,4)),'src_span'(145,88,145,90,8470,13)),'no_loc_info_available','no_loc_info_available','src_span'(145,77,145,81,8459,53)),'src_span'(145,21,145,23,8403,78)),'prefix'('src_span'(146,6,146,18,8486,12),['in'(_b8)],'release_chan','ifte'('bool_and'('bool_and'('=='(_cam,'val_of'('NONE','src_span'(146,35,146,39,8515,4))),'!='(_pend,'val_of'('NONE','src_span'(146,52,146,56,8532,4)))),'agent_call'('src_span'(146,61,146,67,8541,6),'member',[_b8,_sp7])),'agent_call'('src_span'(147,30,147,33,8584,3),'OBS',[_b8,_pend,_best7,'agent_call'('src_span'(147,49,147,53,8603,4),'diff',[_sp7,'setExp'('rangeEnum'([_b8]))]),_send,_slot]),'prefix'('src_span'(147,81,147,86,8635,5),[],'error','stop'('src_span'(147,90,147,94,8644,4)),'src_span'(147,87,147,89,8640,13)),'no_loc_info_available','no_loc_info_available','src_span'(147,76,147,80,8629,64)),'src_span'(146,21,146,23,8500,151)),'src_span_operator'('no_loc_info_available','src_span'(146,2,146,4,8482,2))),'prefix'('src_span'(148,6,148,12,8656,6),['in'(_o),'in'(_b9)],'scored','ifte'('!='(_b9,_pend),'prefix'('src_span'(148,39,148,44,8689,5),[],'error','stop'('src_span'(148,48,148,52,8698,4)),'src_span'(148,45,148,47,8694,13)),'ifte'('=='(_o,'better'),'agent_call'('src_span'(150,26,150,29,8768,3),'OBS',[_cam,'val_of'('NONE','src_span'(150,35,150,39,8777,4)),_b9,'ifte'('=='(_best7,'val_of'('NONE','src_span'(150,55,150,59,8797,4))),_sp7,'agent_call'('src_span'(150,73,150,78,8815,5),'union',[_sp7,'setExp'('rangeEnum'([_best7]))]),'no_loc_info_available','no_loc_info_available','src_span'(150,68,150,72,8809,25)),_send,_slot]),'agent_call'('src_span'(151,26,151,29,8871,3),'OBS',[_cam,'val_of'('NONE','src_span'(151,35,151,39,8880,4)),_best7,'agent_call'('src_span'(151,47,151,52,8892,5),'union',[_sp7,'setExp'('rangeEnum'([_b9]))]),_send,_slot]),'no_loc_info_available','no_loc_info_available','src_span'(150,104,151,25,8845,151)),'no_loc_info_available','no_loc_info_available','src_span'(148,53,149,25,8702,230)),'src_span'(148,17,148,19,8666,256)),'src_span_operator'('no_loc_info_available','src_span'(148,2,148,4,8652,2))),'prefix'('src_span'(152,6,152,14,8927,8),['in'(_b168)],'suppress','ifte'('=='(_b168,_best7),'agent_call'('src_span'(152,39,152,42,8960,3),'OBS',[_cam,_pend,'val_of'('NONE','src_span'(152,54,152,58,8975,4)),'agent_call'('src_span'(152,60,152,65,8981,5),'union',[_sp7,'setExp'('rangeEnum'([_b168]))]),_send,_slot]),'prefix'('src_span'(152,93,152,98,9014,5),[],'error','stop'('src_span'(152,102,152,106,9023,4)),'src_span'(152,99,152,101,9019,13)),'no_loc_info_available','no_loc_info_available','src_span'(152,88,152,92,9008,67)),'src_span'(152,17,152,19,8937,93)),'src_span_operator'('no_loc_info_available','src_span'(152,2,152,4,8923,2))),'prefix'('src_span'(153,6,153,24,9035,18),['in'(_m169),'in'(_b170)],'dotTuple'(['report_chan','wimage']),'ifte'('bool_and'('bool_and'('=='(_b170,_best7),'=='(_send,'val_of'('NONE','src_span'(153,58,153,62,9087,4)))),'=='(_slot,'val_of'('NONE','src_span'(153,75,153,79,9104,4)))),'agent_call'('src_span'(154,38,154,41,9146,3),'OBS',[_cam,_pend,'val_of'('NONE','src_span'(154,53,154,57,9161,4)),_sp7,_b170,_slot]),'prefix'('src_span'(154,77,154,82,9185,5),[],'error','stop'('src_span'(154,86,154,90,9194,4)),'src_span'(154,83,154,85,9190,13)),'no_loc_info_available','no_loc_info_available','src_span'(154,72,154,76,9179,52)),'src_span'(153,29,153,31,9057,144)),'src_span_operator'('no_loc_info_available','src_span'(153,2,153,4,9031,2))),'prefix'('src_span'(155,6,155,13,9206,7),['in'(_b171)],'free_in','ifte'('=='(_b171,_send),'agent_call'('src_span'(155,38,155,41,9238,3),'OBS',[_cam,_pend,_best7,_sp7,'val_of'('NONE','src_span'(155,63,155,67,9263,4)),_b171]),'prefix'('src_span'(155,77,155,82,9277,5),[],'error','stop'('src_span'(155,86,155,90,9286,4)),'src_span'(155,83,155,85,9282,13)),'no_loc_info_available','no_loc_info_available','src_span'(155,72,155,76,9271,52)),'src_span'(155,16,155,18,9215,78)),'src_span_operator'('no_loc_info_available','src_span'(155,2,155,4,9202,2))),'prefix'('src_span'(156,6,156,14,9298,8),['in'(_b172)],'free_out','ifte'('=='(_b172,_slot),'agent_call'('src_span'(156,39,156,42,9331,3),'OBS',[_cam,_pend,_best7,'agent_call'('src_span'(156,60,156,65,9352,5),'union',[_sp7,'setExp'('rangeEnum'([_b172]))]),_send,'val_of'('NONE','src_span'(156,82,156,86,9374,4))]),'prefix'('src_span'(156,93,156,98,9385,5),[],'error','stop'('src_span'(156,102,156,106,9394,4)),'src_span'(156,99,156,101,9390,13)),'no_loc_info_available','no_loc_info_available','src_span'(156,88,156,92,9379,67)),'src_span'(156,17,156,19,9308,93)),'src_span_operator'('no_loc_info_available','src_span'(156,2,156,4,9294,2))),'no_loc_info_available').
'bindval'('ROLE_EVENTS','closure'(['frame_chan','release_chan','scored','suppress','dotTuple'(['report_chan','wimage']),'free_in','free_out']),'src_span'(158,1,158,102,9402,101)).
'agent'('OBSERVED'(_P),'sharing'('val_of'('ROLE_EVENTS','src_span'(159,20,159,31,9523,11)),_P,'agent_call'('src_span'(159,35,159,38,9538,3),'OBS',['int'(0),'val_of'('NONE','src_span'(159,42,159,46,9545,4)),'val_of'('NONE','src_span'(159,48,159,52,9551,4)),'setExp'('rangeEnum'(['int'(1),'int'(2),'int'(3)])),'val_of'('NONE','src_span'(159,65,159,69,9568,4)),'val_of'('NONE','src_span'(159,71,159,75,9574,4))]),'src_span'(159,17,159,34,9520,17)),'src_span'(159,17,159,34,9520,17)).
'bindval'('SYSTEM','agent_call'('src_span'(6,10,6,13,199,3),'SYS',['val_of'('Inference','src_span'(6,14,6,23,203,9)),'val_of'('Reporter','src_span'(6,25,6,33,214,8)),'val_of'('MainApp','src_span'(6,35,6,42,224,7))]),'src_span'(6,1,6,43,190,42)).
'assertModelCheckExt'('False','val_of'('SYSTEM','src_span'(8,8,8,14,241,6)),'DeadlockFree','F').
'assertModelCheck'('False','val_of'('SYSTEM','src_span'(9,8,9,14,276,6)),'LivelockFree').
'assertRef'('False','agent_call'('src_span'(13,8,13,11,483,3),'RUN',['agent_call'('src_span'(13,12,13,16,487,4),'diff',['Events','setExp'('rangeEnum'(['error','overflow']))])]),'Trace','agent_call'('src_span'(13,49,13,57,524,8),'OBSERVED',['val_of'('SYSTEM','src_span'(13,58,13,64,533,6))]),'src_span'(13,1,13,65,476,64)).
'agent'('MCOUNT'(_k),'[]'('[]'('prefix'('src_span'(17,14,17,19,680,5),[],'merge','agent_call'('src_span'(17,23,17,29,689,6),'MCOUNT',['agent_call'('src_span'(17,30,17,33,696,3),'sat',['+'(_k,'int'(1))])]),'src_span'(17,20,17,22,685,27)),'prefix'('src_span'(18,17,18,35,725,18),['out'(_k)],'dotTuple'(['report_chan','window']),'agent_call'('src_span'(18,41,18,47,749,6),'MCOUNT',['int'(0)]),'src_span'(18,38,18,40,745,15)),'src_span_operator'('no_loc_info_available','src_span'(18,13,18,15,721,2))),'prefix'('src_span'(19,17,19,35,776,18),['out'(_k),'in'(_b175)],'dotTuple'(['report_chan','wimage']),'agent_call'('src_span'(19,43,19,49,802,6),'MCOUNT',['int'(0)]),'src_span'(19,40,19,42,798,15)),'src_span_operator'('no_loc_info_available','src_span'(19,13,19,15,772,2))),'no_loc_info_available').
'assertRef'('False','agent_call'('src_span'(21,8,21,14,821,6),'MCOUNT',['int'(0)]),'Trace','\x5c\'('val_of'('SYSTEM','src_span'(21,22,21,28,835,6)),'agent_call'('src_span'(21,31,21,35,844,4),'diff',['Events','closure'(['merge','dotTuple'(['report_chan','window']),'dotTuple'(['report_chan','wimage'])])]),'src_span_operator'('no_loc_info_available','src_span'(21,29,21,30,842,1))),'src_span'(21,1,21,96,814,95)).
'bindval'('INF_REPORTS','closure'(['dotTuple'(['report_chan','scores']),'dotTuple'(['report_chan','window']),'dotTuple'(['report_chan','wimage'])]),'src_span'(25,1,25,79,1089,78)).
'bindval'('TOKEN','repChoice'(['comprehensionGenerator'(_r5,'val_of'('INF_REPORTS','src_span'(26,17,26,28,1184,11)))],'prefix'('src_span'(26,31,26,32,1198,1),[],_r5,'prefix'('src_span'(26,36,26,44,1203,8),[],'ready_in','val_of'('TOKEN','src_span'(26,48,26,53,1215,5)),'src_span'(26,45,26,47,1211,17)),'src_span'(26,33,26,35,1199,22)),'src_span'(26,13,26,30,1180,17)),'src_span'(26,1,26,54,1168,53)).
'assertRef'('False','val_of'('TOKEN','src_span'(28,8,28,13,1230,5)),'Trace','\x5c\'('val_of'('SYSTEM','src_span'(28,18,28,24,1240,6)),'agent_call'('src_span'(28,27,28,31,1249,4),'diff',['Events','agent_call'('src_span'(28,40,28,45,1262,5),'union',['val_of'('INF_REPORTS','src_span'(28,46,28,57,1268,11)),'setExp'('rangeEnum'(['ready_in']))])]),'src_span_operator'('no_loc_info_available','src_span'(28,25,28,26,1247,1))),'src_span'(28,1,28,71,1223,70)).
'bindval'('SYSTEM_STALL','agent_call'('src_span'(36,16,36,19,1859,3),'SYS',['val_of'('Inference','src_span'(36,20,36,29,1863,9)),'val_of'('ReporterStall','src_span'(36,31,36,44,1874,13)),'val_of'('MainApp','src_span'(36,46,36,53,1889,7))]),'src_span'(36,1,36,54,1844,53)).
'assertModelCheckExt'('False','val_of'('SYSTEM_STALL','src_span'(38,8,38,20,1906,12)),'DeadlockFree','F').
'assertRef'('False','val_of'('CYCLE','src_span'(39,8,39,13,1947,5)),'FailureDivergence','\x5c\'('agent_call'('src_span'(39,19,39,22,1958,3),'SYS',['val_of'('Inference','src_span'(39,23,39,32,1962,9)),'val_of'('Reporter','src_span'(39,34,39,42,1973,8)),'agent_call'('src_span'(39,44,39,52,1983,8),'MainAppN',['int'(2)])]),'agent_call'('src_span'(39,59,39,63,1998,4),'diff',['Events','setExp'('rangeEnum'(['g_trigger_chan']))]),'src_span_operator'('no_loc_info_available','src_span'(39,57,39,58,1996,1))),'src_span'(39,1,39,89,1940,88)).
'assertRef'('False','val_of'('CYCLE','src_span'(40,8,40,13,2036,5)),'FailureDivergence','\x5c\'('agent_call'('src_span'(40,19,40,22,2047,3),'SYS',['val_of'('Inference','src_span'(40,23,40,32,2051,9)),'val_of'('ReporterStall','src_span'(40,34,40,47,2062,13)),'agent_call'('src_span'(40,49,40,57,2077,8),'MainAppN',['int'(2)])]),'agent_call'('src_span'(40,64,40,68,2092,4),'diff',['Events','setExp'('rangeEnum'(['g_trigger_chan']))]),'src_span_operator'('no_loc_info_available','src_span'(40,62,40,63,2090,1))),'src_span'(40,1,40,94,2029,93)).
'bindval'('ReporterStop','[]'('[]'('prefix'('src_span'(45,17,45,28,2365,11),['inGuard'(_r6,'val_of'('INF_TEXT','src_span'(45,31,45,39,2379,8)))],'report_chan','prefix'('src_span'(45,43,45,47,2391,4),['out'(_r6)],'line','prefix'('src_span'(45,53,45,61,2401,8),[],'ready_in','val_of'('ReporterStop','src_span'(45,65,45,77,2413,12)),'src_span'(45,62,45,64,2409,24)),'src_span'(45,50,45,52,2397,30)),'src_span'(45,40,45,42,2387,49)),'prefix'('src_span'(46,20,46,31,2446,11),['inGuard'(_r7,'val_of'('OTHER','src_span'(46,34,46,39,2460,5)))],'report_chan','prefix'('src_span'(46,43,46,47,2469,4),['out'(_r7)],'line','val_of'('ReporterStop','src_span'(46,53,46,65,2479,12)),'src_span'(46,50,46,52,2475,18)),'src_span'(46,40,46,42,2465,34)),'src_span_operator'('no_loc_info_available','src_span'(46,16,46,18,2442,2))),'prefix'('src_span'(47,20,47,38,2512,18),['in'(_m179),'in'(_b180)],'dotTuple'(['report_chan','wimage']),'prefix'('src_span'(47,46,47,50,2538,4),['out'('dotTuple'(['window',_m179]))],'line','prefix'('src_span'(47,63,47,69,2555,6),['out'(_b180)],'uplink','stop'('src_span'(47,75,47,79,2567,4)),'src_span'(47,72,47,74,2563,10)),'src_span'(47,60,47,62,2551,29)),'src_span'(47,43,47,45,2534,39)),'src_span_operator'('no_loc_info_available','src_span'(47,16,47,18,2508,2))),'src_span'(45,1,47,80,2349,223)).
'bindval'('SYSTEM_STOP','agent_call'('src_span'(48,15,48,18,2587,3),'SYS',['val_of'('Inference','src_span'(48,19,48,28,2591,9)),'val_of'('ReporterStop','src_span'(48,30,48,42,2602,12)),'stop'('src_span'(48,44,48,48,2616,4))]),'src_span'(48,1,48,49,2573,48)).
'bindval'('STALL_VIEW','closure'(['dotTuple'(['report_chan','window']),'dotTuple'(['report_chan','wimage']),'uplink','merge']),'src_span'(50,1,50,73,2623,72)).
'bindval'('PRE','|~|'('|~|'('prefix'('src_span'(51,15,51,20,2710,5),[],'merge','val_of'('PRE','src_span'(51,24,51,27,2719,3)),'src_span'(51,21,51,23,2715,12)),'repInternalChoice'(['comprehensionGenerator'(_k2,'setExp'('rangeClosed'('int'(0),'val_of'('MAXM','src_span'(52,31,52,35,2754,4)))))],'prefix'('src_span'(52,39,52,57,2762,18),['out'(_k2)],'dotTuple'(['report_chan','window']),'val_of'('PRE','src_span'(52,63,52,66,2786,3)),'src_span'(52,60,52,62,2782,9)),'src_span'(52,23,52,38,2746,15)),'src_span_operator'('no_loc_info_available','src_span'(52,14,52,17,2737,3))),'repInternalChoice'(['comprehensionGenerator'(_k3,'setExp'('rangeClosed'('int'(0),'val_of'('MAXM','src_span'(53,31,53,35,2821,4))))),'comprehensionGenerator'(_b183,'val_of'('IDS','src_span'(53,42,53,45,2832,3)))],'prefix'('src_span'(53,48,53,66,2838,18),['out'(_k3),'out'(_b183)],'dotTuple'(['report_chan','wimage']),'|||'('prefix'('src_span'(53,76,53,82,2866,6),['out'(_b183)],'uplink','stop'('src_span'(53,88,53,92,2878,4)),'src_span'(53,85,53,87,2874,10)),'val_of'('MERGING','src_span'(53,98,53,105,2888,7)),'src_span_operator'('no_loc_info_available','src_span'(53,94,53,97,2884,3))),'src_span'(53,71,53,73,2860,38)),'src_span'(53,23,53,47,2813,24)),'src_span_operator'('no_loc_info_available','src_span'(53,14,53,17,2804,3))),'src_span'(51,1,53,107,2696,201)).
'bindval'('MERGING','prefix'('src_span'(54,14,54,19,2911,5),[],'merge','val_of'('MERGING','src_span'(54,23,54,30,2920,7)),'src_span'(54,20,54,22,2916,16)),'src_span'(54,1,54,30,2898,29)).
'assertRef'('False','val_of'('PRE','src_span'(56,8,56,11,2936,3)),'FailureDivergence','\x5c\'('val_of'('SYSTEM_STOP','src_span'(56,17,56,28,2945,11)),'agent_call'('src_span'(56,31,56,35,2959,4),'diff',['Events','val_of'('STALL_VIEW','src_span'(56,44,56,54,2972,10))]),'src_span_operator'('no_loc_info_available','src_span'(56,29,56,30,2957,1))),'src_span'(56,1,56,55,2929,54)).
'comment'('lineComment'('-- Uplink (csp4cmsis_neuropathway_image_uplink): the assertions. The processes are in'),'src_position'(1,1,0,85)).
'comment'('lineComment'('-- Uplink_defs.csp; Command and cmd_chan are checked in Uplink_command.csp.'),'src_position'(2,1,86,75)).
'comment'('lineComment'('-- Uplink (csp4cmsis_neuropathway_image_uplink), definitions shared by Uplink.csp and'),'src_position'(1,1,0,85)).
'comment'('lineComment'('-- Uplink_controls.csp: Camera -> Inference -> Reporter, plus MainApp, with the four JPEG buffers'),'src_position'(2,1,86,97)).
'comment'('lineComment'('-- as tokens and the Reporter\x27\s ready token.'),'src_position'(3,1,184,44)).
'comment'('lineComment'('-- Buffer ids travel with the frames (frame_chan), back to Camera as the next DMA target'),'src_position'(4,1,229,88)).
'comment'('lineComment'('-- (release_chan), to the Reporter with a Window report that carries an image (report_chan) and'),'src_position'(5,1,318,95)).
'comment'('lineComment'('-- back to Inference when the send is done (free_chan, one slot).'),'src_position'(6,1,414,65)).
'comment'('lineComment'('-- Inference writes at most one report per ready token: the Reporter returns the token on'),'src_position'(7,1,480,89)).
'comment'('lineComment'('-- ready_chan (one slot) when it has finished the report, image included. Each frame Inference'),'src_position'(8,1,570,94)).
'comment'('lineComment'('-- holds the token it writes one report: at a window end, if it also holds the free token, the'),'src_position'(9,1,665,94)).
'comment'('lineComment'('-- Window report (with the image if the window passes the filter, else suppressed); otherwise a'),'src_position'(10,1,760,95)).
'comment'('lineComment'('-- Scores report. Without the token it keeps the scores (they go with its next report) and'),'src_position'(11,1,856,90)).
'comment'('lineComment'('-- merges a window that ends.'),'src_position'(12,1,947,29)).
'comment'('lineComment'('-- Command and cmd_chan are modelled separately (Uplink_command.csp).'),'src_position'(13,1,977,69)).
'comment'('lineComment'('-- Bounded for exhaustive checking: windows of W = 2 frames (8 on the board), frame indices'),'src_position'(14,1,1047,91)).
'comment'('lineComment'('-- 0..1 wrapping (only the position in the window matters), the merged count saturating at MAXM.'),'src_position'(15,1,1139,96)).
'comment'('lineComment'('-- no buffer'),'src_position'(20,48,1331,12)).
'comment'('lineComment'('-- the frame\x27\s score against the window\x27\s best'),'src_position'(26,48,1485,46)).
'comment'('lineComment'('-- Inference\x27\s text reports (return the token)'),'src_position'(29,58,1687,46)).
'comment'('lineComment'('-- frame-ready interrupt -> Camera'),'src_position'(32,48,1836,34)).
'comment'('lineComment'('-- Camera -> Inference: frame index, its buffer'),'src_position'(33,48,1918,47)).
'comment'('lineComment'('-- Inference -> Camera: raw buffer free, next DMA target'),'src_position'(34,48,2013,56)).
'comment'('lineComment'('-- Reporter -> free_chan\x27\s slot'),'src_position'(35,48,2117,31)).
'comment'('lineComment'('-- free_chan\x27\s slot -> Inference (poll, value ready)'),'src_position'(36,48,2196,52)).
'comment'('lineComment'('-- free_chan\x27\s slot -> Inference (poll, SKIP taken)'),'src_position'(37,48,2296,51)).
'comment'('lineComment'('-- Reporter -> ready_chan\x27\s slot'),'src_position'(38,48,2395,32)).
'comment'('lineComment'('-- ready_chan\x27\s slot -> Inference (poll, token back)'),'src_position'(39,48,2475,52)).
'comment'('lineComment'('-- ready_chan\x27\s slot -> Inference (poll, SKIP taken)'),'src_position'(40,48,2575,52)).
'comment'('lineComment'('-- Camera, Inference, MainApp -> Reporter'),'src_position'(41,48,2675,41)).
'comment'('lineComment'('-- the Reporter\x27\s text lines'),'src_position'(42,48,2764,28)).
'comment'('lineComment'('-- the Reporter sends the JPEG in this buffer'),'src_position'(43,48,2840,45)).
'comment'('lineComment'('-- Inference has scored the frame in this buffer'),'src_position'(44,48,2933,48)).
'comment'('lineComment'('-- the window\x27\s best fails the filter, back to the spares'),'src_position'(45,48,3029,57)).
'comment'('lineComment'('-- Inference merges a window (no token at its end)'),'src_position'(46,48,3134,50)).
'comment'('lineComment'('-- Camera: the next DMA target is buffer 0 at start, then whatever Inference releases.'),'src_position'(54,1,3303,86)).
'comment'('lineComment'('-- Inference: sp = spare buffers, best = the window\x27\s best (NONE if none yet), tok = holds the'),'src_position'(58,1,3571,94)).
'comment'('lineComment'('-- free token, rdy = holds the ready token, m = windows merged since the last Window line. Per'),'src_position'(59,1,3666,94)).
'comment'('lineComment'('-- frame: poll free_chan, poll ready_chan, rescale and release a spare as the next DMA target,'),'src_position'(60,1,3761,94)).
'comment'('lineComment'('-- score, then report or not (End). It starts with both tokens.'),'src_position'(61,1,3856,63)).
'comment'('lineComment'('-- The filter (best >= T and at least K frames >= T) depends on the scores, so the model'),'src_position'(84,1,4909,88)).
'comment'('lineComment'('-- chooses internally between sending and suppressing a window that has a best.'),'src_position'(85,1,4998,79)).
'comment'('lineComment'('-- free_chan and ready_chan: one-slot buffered channels, polled by Inference with a PRI ALT'),'src_position'(103,1,5852,91)).
'comment'('lineComment'('-- and SKIP, which sees either the value or an empty slot, never both. A second write to a full'),'src_position'(104,1,5944,95)).
'comment'('lineComment'('-- slot would block the Reporter; overflow marks it.'),'src_position'(105,1,6040,52)).
'comment'('lineComment'('-- MainApp: one stack report per timer tick, over its own writer end. MainAppN(n): n reports.'),'src_position'(112,1,6352,93)).
'comment'('lineComment'('-- Reporter: a line per text report; a Window report with an image is its line, then the send,'),'src_position'(116,1,6590,94)).
'comment'('lineComment'('-- then the buffer back. It returns the ready token after each report of Inference\x27\s.'),'src_position'(117,1,6685,85)).
'comment'('lineComment'('-- Uplink stalled: after any report of Inference\x27\s the Reporter may stop for ever, without'),'src_position'(122,1,7005,90)).
'comment'('lineComment'('-- returning the token (or the buffer) and without reading report_chan again.'),'src_position'(123,1,7096,77)).
'comment'('lineComment'('-- Buffer roles: an observer that follows each id through the events, from the role it must be'),'src_position'(138,1,7849,94)).
'comment'('lineComment'('-- in to the next one: next (Camera\x27\s DMA target), pending (being scored), best, sending (from the'),'src_position'(139,1,7944,98)).
'comment'('lineComment'('-- Window report with the image until Inference has read it back; slot = in free_chan), and'),'src_position'(140,1,8043,91)).
'comment'('lineComment'('-- spare. It starts with 0 as next and 1..3 spare and moves exactly one id per event, so as long'),'src_position'(141,1,8135,96)).
'comment'('lineComment'('-- as no event finds an id in the wrong role (error), the four ids are always a permutation'),'src_position'(142,1,8232,91)).
'comment'('lineComment'('-- across the roles.'),'src_position'(143,1,8324,20)).
'comment'('lineComment'('-- The four buffer ids are always a permutation across the roles; Camera is only handed a spare;'),'src_position'(11,1,303,96)).
'comment'('lineComment'('-- only the window\x27\s best is sent; neither one-slot channel ever overflows.'),'src_position'(12,1,400,75)).
'comment'('lineComment'('-- The merged count: every Window line carries the number of windows merged since the previous'),'src_position'(15,1,542,94)).
'comment'('lineComment'('-- line (saturating at MAXM).'),'src_position'(16,1,637,29)).
'comment'('lineComment'('-- The ready token: Inference\x27\s reports and the Reporter\x27\s token returns alternate, so Inference'),'src_position'(23,1,911,96)).
'comment'('lineComment'('-- never writes a report while the Reporter is still busy with its previous one.'),'src_position'(24,1,1008,80)).
'comment'('lineComment'('-- Camera and Inference keep cycling: the frame-ready trigger is never refused, with the'),'src_position'(30,1,1295,88)).
'comment'('lineComment'('-- Reporter running and with the Reporter stalled for ever after any report (MainApp\x27\s stack'),'src_position'(31,1,1384,92)).
'comment'('lineComment'('-- reports then block too). Everything but the trigger is hidden and the refinement is'),'src_position'(32,1,1477,86)).
'comment'('lineComment'('-- failures-divergences, so a refused trigger and any loop of hidden events both fail it; MainApp'),'src_position'(33,1,1564,97)).
'comment'('lineComment'('-- sends two reports here, since its stack reports would otherwise be such a loop while the'),'src_position'(34,1,1662,91)).
'comment'('lineComment'('-- Reporter runs (and would hide a blocked Camera: a state on that loop has no refusals).'),'src_position'(35,1,1754,89)).
'comment'('lineComment'('-- Uplink stalled after the first image (MainApp left out, since it only blocks): from then on'),'src_position'(42,1,2124,94)).
'comment'('lineComment'('-- only the merges go on, one per window, for ever; no Window line, no image. Before it, Window'),'src_position'(43,1,2219,95)).
'comment'('lineComment'('-- lines and merges in any order.'),'src_position'(44,1,2315,33)).
'symbol'('W','W','src_span'(17,1,17,2,1237,1),'Ident (Groundrep.)').
'symbol'('MAX_INDEX','MAX_INDEX','src_span'(18,1,18,10,1251,9),'Ident (Groundrep.)').
'symbol'('IDS','IDS','src_span'(19,1,19,4,1265,3),'Ident (Groundrep.)').
'symbol'('NONE','NONE','src_span'(20,1,20,5,1284,4),'Ident (Groundrep.)').
'symbol'('MAXM','MAXM','src_span'(21,1,21,5,1344,4),'Ident (Groundrep.)').
'symbol'('sat','sat','src_span'(23,1,23,4,1359,3),'Funktion or Process').
'symbol'('m','m','src_span'(23,5,23,6,1363,1),'Ident (Prolog Variable)').
'symbol'('source_t','source_t','src_span'(25,10,25,18,1407,8),'Datatype').
'symbol'('camera','camera','src_span'(25,22,25,28,1419,6),'Constructor of Datatype').
'symbol'('inference','inference','src_span'(25,31,25,40,1428,9),'Constructor of Datatype').
'symbol'('outcome_t','outcome_t','src_span'(26,10,26,19,1447,9),'Datatype').
'symbol'('better','better','src_span'(26,22,26,28,1459,6),'Constructor of Datatype').
'symbol'('worse','worse','src_span'(26,31,26,36,1468,5),'Constructor of Datatype').
'symbol'('failed','failed','src_span'(26,39,26,45,1476,6),'Constructor of Datatype').
'symbol'('report_t','report_t','src_span'(27,10,27,18,1541,8),'Datatype').
'symbol'('started','started','src_span'(27,22,27,29,1553,7),'Constructor of Datatype').
'symbol'('stack','stack','src_span'(27,41,27,46,1572,5),'Constructor of Datatype').
'symbol'('scores','scores','src_span'(27,49,27,55,1580,6),'Constructor of Datatype').
'symbol'('window','window','src_span'(27,58,27,64,1589,6),'Constructor of Datatype').
'symbol'('wimage','wimage','src_span'(27,77,27,83,1608,6),'Constructor of Datatype').
'symbol'('INF_TEXT','INF_TEXT','src_span'(29,1,29,9,1630,8),'Ident (Groundrep.)').
'symbol'('union','union','src_span'(29,12,29,17,1641,5),'BuiltIn primitive').
'symbol'('m2','m','src_span'(29,40,29,41,1669,1),'Ident (Prolog Variable)').
'symbol'('OTHER','OTHER','src_span'(30,1,30,6,1734,5),'Ident (Groundrep.)').
'symbol'('g_trigger_chan','g_trigger_chan','src_span'(32,9,32,23,1797,14),'Channel').
'symbol'('frame_chan','frame_chan','src_span'(33,9,33,19,1879,10),'Channel').
'symbol'('release_chan','release_chan','src_span'(34,9,34,21,1974,12),'Channel').
'symbol'('free_in','free_in','src_span'(35,9,35,16,2078,7),'Channel').
'symbol'('free_out','free_out','src_span'(36,9,36,17,2157,8),'Channel').
'symbol'('poll_empty','poll_empty','src_span'(37,9,37,19,2257,10),'Channel').
'symbol'('ready_in','ready_in','src_span'(38,9,38,17,2356,8),'Channel').
'symbol'('ready_out','ready_out','src_span'(39,9,39,18,2436,9),'Channel').
'symbol'('ready_empty','ready_empty','src_span'(40,9,40,20,2536,11),'Channel').
'symbol'('report_chan','report_chan','src_span'(41,9,41,20,2636,11),'Channel').
'symbol'('line','line','src_span'(42,9,42,13,2725,4),'Channel').
'symbol'('uplink','uplink','src_span'(43,9,43,15,2801,6),'Channel').
'symbol'('scored','scored','src_span'(44,9,44,15,2894,6),'Channel').
'symbol'('suppress','suppress','src_span'(45,9,45,17,2990,8),'Channel').
'symbol'('merge','merge','src_span'(46,9,46,14,3095,5),'Channel').
'symbol'('camera_log','camera_log','src_span'(47,9,47,19,3193,10),'Channel').
'symbol'('stack_tick','stack_tick','src_span'(47,21,47,31,3205,10),'Channel').
'symbol'('overflow','overflow','src_span'(48,9,48,17,3224,8),'Channel').
'symbol'('error','error','src_span'(48,19,48,24,3234,5),'Channel').
'symbol'('ENV','ENV','src_span'(50,1,50,4,3241,3),'Ident (Groundrep.)').
'symbol'('RUN','RUN','src_span'(52,1,52,4,3270,3),'Funktion or Process').
'symbol'('A','A','src_span'(52,5,52,6,3274,1),'Ident (Prolog Variable)').
'symbol'('x','x','src_span'(52,13,52,14,3282,1),'Ident (Prolog Variable)').
'symbol'('Camera','Camera','src_span'(55,1,55,7,3390,6),'Ident (Groundrep.)').
'symbol'('CameraLoop','CameraLoop','src_span'(56,1,56,11,3460,10),'Funktion or Process').
'symbol'('i','i','src_span'(56,12,56,13,3471,1),'Ident (Prolog Variable)').
'symbol'('b','b','src_span'(56,15,56,16,3474,1),'Ident (Prolog Variable)').
'symbol'('nb','nb','src_span'(56,69,56,71,3528,2),'Ident (Prolog Variable)').
'symbol'('Inference','Inference','src_span'(62,1,62,10,3920,9),'Ident (Groundrep.)').
'symbol'('i2','i','src_span'(62,24,62,25,3943,1),'Ident (Prolog Variable)').
'symbol'('p','p','src_span'(62,26,62,27,3945,1),'Ident (Prolog Variable)').
'symbol'('diff','diff','src_span'(62,76,62,80,3995,4),'BuiltIn primitive').
'symbol'('Infer','Infer','src_span'(64,1,64,6,4033,5),'Funktion or Process').
'symbol'('i3','i','src_span'(64,7,64,8,4039,1),'Ident (Prolog Variable)').
'symbol'('p2','p','src_span'(64,10,64,11,4042,1),'Ident (Prolog Variable)').
'symbol'('sp','sp','src_span'(64,13,64,15,4045,2),'Ident (Prolog Variable)').
'symbol'('best','best','src_span'(64,17,64,21,4049,4),'Ident (Prolog Variable)').
'symbol'('tok','tok','src_span'(64,23,64,26,4055,3),'Ident (Prolog Variable)').
'symbol'('rdy','rdy','src_span'(64,28,64,31,4060,3),'Ident (Prolog Variable)').
'symbol'('m3','m','src_span'(64,33,64,34,4065,1),'Ident (Prolog Variable)').
'symbol'('b2','b','src_span'(65,15,65,16,4084,1),'Ident (Prolog Variable)').
'symbol'('PollReady','PollReady','src_span'(68,1,68,10,4205,9),'Funktion or Process').
'symbol'('i4','i','src_span'(68,11,68,12,4215,1),'Ident (Prolog Variable)').
'symbol'('p3','p','src_span'(68,14,68,15,4218,1),'Ident (Prolog Variable)').
'symbol'('sp2','sp','src_span'(68,17,68,19,4221,2),'Ident (Prolog Variable)').
'symbol'('best2','best','src_span'(68,21,68,25,4225,4),'Ident (Prolog Variable)').
'symbol'('tok2','tok','src_span'(68,27,68,30,4231,3),'Ident (Prolog Variable)').
'symbol'('rdy2','rdy','src_span'(68,32,68,35,4236,3),'Ident (Prolog Variable)').
'symbol'('m4','m','src_span'(68,37,68,38,4241,1),'Ident (Prolog Variable)').
'symbol'('Release','Release','src_span'(72,1,72,8,4365,7),'Funktion or Process').
'symbol'('i5','i','src_span'(72,9,72,10,4373,1),'Ident (Prolog Variable)').
'symbol'('p4','p','src_span'(72,12,72,13,4376,1),'Ident (Prolog Variable)').
'symbol'('sp3','sp','src_span'(72,15,72,17,4379,2),'Ident (Prolog Variable)').
'symbol'('best3','best','src_span'(72,19,72,23,4383,4),'Ident (Prolog Variable)').
'symbol'('tok3','tok','src_span'(72,25,72,28,4389,3),'Ident (Prolog Variable)').
'symbol'('rdy3','rdy','src_span'(72,30,72,33,4394,3),'Ident (Prolog Variable)').
'symbol'('m5','m','src_span'(72,35,72,36,4399,1),'Ident (Prolog Variable)').
'symbol'('s','s','src_span'(73,9,73,10,4412,1),'Ident (Prolog Variable)').
'symbol'('diff','diff','src_span'(73,48,73,52,4451,4),'BuiltIn primitive').
'symbol'('Score','Score','src_span'(75,1,75,6,4486,5),'Funktion or Process').
'symbol'('i6','i','src_span'(75,7,75,8,4492,1),'Ident (Prolog Variable)').
'symbol'('p5','p','src_span'(75,10,75,11,4495,1),'Ident (Prolog Variable)').
'symbol'('sp4','sp','src_span'(75,13,75,15,4498,2),'Ident (Prolog Variable)').
'symbol'('best4','best','src_span'(75,17,75,21,4502,4),'Ident (Prolog Variable)').
'symbol'('tok4','tok','src_span'(75,23,75,26,4508,3),'Ident (Prolog Variable)').
'symbol'('rdy4','rdy','src_span'(75,28,75,31,4513,3),'Ident (Prolog Variable)').
'symbol'('m6','m','src_span'(75,33,75,34,4518,1),'Ident (Prolog Variable)').
'symbol'('End','End','src_span'(86,1,86,4,5078,3),'Funktion or Process').
'symbol'('i7','i','src_span'(86,5,86,6,5082,1),'Ident (Prolog Variable)').
'symbol'('sp5','sp','src_span'(86,8,86,10,5085,2),'Ident (Prolog Variable)').
'symbol'('best5','best','src_span'(86,12,86,16,5089,4),'Ident (Prolog Variable)').
'symbol'('tok5','tok','src_span'(86,18,86,21,5095,3),'Ident (Prolog Variable)').
'symbol'('rdy5','rdy','src_span'(86,23,86,26,5100,3),'Ident (Prolog Variable)').
'symbol'('m7','m','src_span'(86,28,86,29,5105,1),'Ident (Prolog Variable)').
'symbol'('Next','Next','src_span'(101,1,101,5,5768,4),'Funktion or Process').
'symbol'('sp6','sp','src_span'(101,6,101,8,5773,2),'Ident (Prolog Variable)').
'symbol'('best6','best','src_span'(101,10,101,14,5777,4),'Ident (Prolog Variable)').
'symbol'('tok6','tok','src_span'(101,16,101,19,5783,3),'Ident (Prolog Variable)').
'symbol'('rdy6','rdy','src_span'(101,21,101,24,5788,3),'Ident (Prolog Variable)').
'symbol'('m8','m','src_span'(101,26,101,27,5793,1),'Ident (Prolog Variable)').
'symbol'('j','j','src_span'(101,42,101,43,5809,1),'Ident (Prolog Variable)').
'symbol'('p6','p','src_span'(101,44,101,45,5811,1),'Ident (Prolog Variable)').
'symbol'('FREE','FREE','src_span'(106,1,106,5,6093,4),'Ident (Groundrep.)').
'symbol'('b3','b','src_span'(106,17,106,18,6109,1),'Ident (Prolog Variable)').
'symbol'('FREE_FULL','FREE_FULL','src_span'(107,1,107,10,6152,9),'Funktion or Process').
'symbol'('b4','b','src_span'(107,11,107,12,6162,1),'Ident (Prolog Variable)').
'symbol'('x2','x','src_span'(107,49,107,50,6200,1),'Ident (Prolog Variable)').
'symbol'('READY','READY','src_span'(109,1,109,6,6224,5),'Ident (Groundrep.)').
'symbol'('READY_FULL','READY_FULL','src_span'(110,1,110,11,6283,10),'Ident (Groundrep.)').
'symbol'('MainApp','MainApp','src_span'(113,1,113,8,6446,7),'Ident (Groundrep.)').
'symbol'('MainAppN','MainAppN','src_span'(114,1,114,9,6499,8),'Funktion or Process').
'symbol'('n','n','src_span'(114,10,114,11,6508,1),'Ident (Prolog Variable)').
'symbol'('Reporter','Reporter','src_span'(118,1,118,9,6771,8),'Ident (Groundrep.)').
'symbol'('r','r','src_span'(118,25,118,26,6795,1),'Ident (Prolog Variable)').
'symbol'('r2','r','src_span'(119,28,119,29,6868,1),'Ident (Prolog Variable)').
'symbol'('m9','m','src_span'(120,35,120,36,6933,1),'Ident (Prolog Variable)').
'symbol'('b5','b','src_span'(120,37,120,38,6935,1),'Ident (Prolog Variable)').
'symbol'('ReporterStall','ReporterStall','src_span'(124,1,124,14,7174,13),'Ident (Groundrep.)').
'symbol'('r3','r','src_span'(124,30,124,31,7203,1),'Ident (Prolog Variable)').
'symbol'('r4','r','src_span'(125,33,125,34,7299,1),'Ident (Prolog Variable)').
'symbol'('m148','m','src_span'(126,40,126,41,7374,1),'Ident (Prolog Variable)').
'symbol'('b6','b','src_span'(126,42,126,43,7376,1),'Ident (Prolog Variable)').
'symbol'('PIPE','PIPE','src_span'(129,1,129,5,7484,4),'Funktion or Process').
'symbol'('Inf','Inf','src_span'(129,6,129,9,7489,3),'Ident (Prolog Variable)').
'symbol'('NETWORK','NETWORK','src_span'(130,1,130,8,7548,7),'Funktion or Process').
'symbol'('Inf2','Inf','src_span'(130,9,130,12,7556,3),'Ident (Prolog Variable)').
'symbol'('Rep','Rep','src_span'(130,14,130,17,7561,3),'Ident (Prolog Variable)').
'symbol'('Main','Main','src_span'(130,19,130,23,7566,4),'Ident (Prolog Variable)').
'symbol'('SYS','SYS','src_span'(134,1,134,4,7738,3),'Funktion or Process').
'symbol'('Inf3','Inf','src_span'(134,5,134,8,7742,3),'Ident (Prolog Variable)').
'symbol'('Rep2','Rep','src_span'(134,10,134,13,7747,3),'Ident (Prolog Variable)').
'symbol'('Main2','Main','src_span'(134,15,134,19,7752,4),'Ident (Prolog Variable)').
'symbol'('CYCLE','CYCLE','src_span'(136,1,136,6,7816,5),'Ident (Groundrep.)').
'symbol'('OBS','OBS','src_span'(144,1,144,4,8345,3),'Funktion or Process').
'symbol'('cam','cam','src_span'(144,5,144,8,8349,3),'Ident (Prolog Variable)').
'symbol'('pend','pend','src_span'(144,10,144,14,8354,4),'Ident (Prolog Variable)').
'symbol'('best7','best','src_span'(144,16,144,20,8360,4),'Ident (Prolog Variable)').
'symbol'('sp7','sp','src_span'(144,22,144,24,8366,2),'Ident (Prolog Variable)').
'symbol'('send','send','src_span'(144,26,144,30,8370,4),'Ident (Prolog Variable)').
'symbol'('slot','slot','src_span'(144,32,144,36,8376,4),'Ident (Prolog Variable)').
'symbol'('i8','i','src_span'(145,17,145,18,8400,1),'Ident (Prolog Variable)').
'symbol'('b7','b','src_span'(145,19,145,20,8402,1),'Ident (Prolog Variable)').
'symbol'('b8','b','src_span'(146,19,146,20,8499,1),'Ident (Prolog Variable)').
'symbol'('member','member','src_span'(146,61,146,67,8541,6),'BuiltIn primitive').
'symbol'('diff','diff','src_span'(147,49,147,53,8603,4),'BuiltIn primitive').
'symbol'('o','o','src_span'(148,13,148,14,8663,1),'Ident (Prolog Variable)').
'symbol'('b9','b','src_span'(148,15,148,16,8665,1),'Ident (Prolog Variable)').
'symbol'('b168','b','src_span'(152,15,152,16,8936,1),'Ident (Prolog Variable)').
'symbol'('m169','m','src_span'(153,25,153,26,9054,1),'Ident (Prolog Variable)').
'symbol'('b170','b','src_span'(153,27,153,28,9056,1),'Ident (Prolog Variable)').
'symbol'('b171','b','src_span'(155,14,155,15,9214,1),'Ident (Prolog Variable)').
'symbol'('b172','b','src_span'(156,15,156,16,9307,1),'Ident (Prolog Variable)').
'symbol'('ROLE_EVENTS','ROLE_EVENTS','src_span'(158,1,158,12,9402,11),'Ident (Groundrep.)').
'symbol'('OBSERVED','OBSERVED','src_span'(159,1,159,9,9504,8),'Funktion or Process').
'symbol'('P','P','src_span'(159,10,159,11,9513,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM','SYSTEM','src_span'(6,1,6,7,190,6),'Ident (Groundrep.)').
'symbol'('diff','diff','src_span'(13,12,13,16,487,4),'BuiltIn primitive').
'symbol'('MCOUNT','MCOUNT','src_span'(17,1,17,7,667,6),'Funktion or Process').
'symbol'('k','k','src_span'(17,8,17,9,674,1),'Ident (Prolog Variable)').
'symbol'('b175','b','src_span'(19,38,19,39,797,1),'Ident (Prolog Variable)').
'symbol'('INF_REPORTS','INF_REPORTS','src_span'(25,1,25,12,1089,11),'Ident (Groundrep.)').
'symbol'('TOKEN','TOKEN','src_span'(26,1,26,6,1168,5),'Ident (Groundrep.)').
'symbol'('r5','r','src_span'(26,13,26,14,1180,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM_STALL','SYSTEM_STALL','src_span'(36,1,36,13,1844,12),'Ident (Groundrep.)').
'symbol'('ReporterStop','ReporterStop','src_span'(45,1,45,13,2349,12),'Ident (Groundrep.)').
'symbol'('r6','r','src_span'(45,29,45,30,2377,1),'Ident (Prolog Variable)').
'symbol'('r7','r','src_span'(46,32,46,33,2458,1),'Ident (Prolog Variable)').
'symbol'('m179','m','src_span'(47,39,47,40,2531,1),'Ident (Prolog Variable)').
'symbol'('b180','b','src_span'(47,41,47,42,2533,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM_STOP','SYSTEM_STOP','src_span'(48,1,48,12,2573,11),'Ident (Groundrep.)').
'symbol'('STALL_VIEW','STALL_VIEW','src_span'(50,1,50,11,2623,10),'Ident (Groundrep.)').
'symbol'('PRE','PRE','src_span'(51,1,51,4,2696,3),'Ident (Groundrep.)').
'symbol'('k2','k','src_span'(52,23,52,24,2746,1),'Ident (Prolog Variable)').
'symbol'('k3','k','src_span'(53,23,53,24,2813,1),'Ident (Prolog Variable)').
'symbol'('b183','b','src_span'(53,38,53,39,2828,1),'Ident (Prolog Variable)').
'symbol'('MERGING','MERGING','src_span'(54,1,54,8,2898,7),'Ident (Groundrep.)').