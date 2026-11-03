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
'bindval'('ReporterStall','[]'('[]'('prefix'('src_span'(124,18,124,29,7191,11),['inGuard'(_r3,'val_of'('INF_TEXT','src_span'(124,32,124,40,7205,8)))],'report_chan','prefix'('src_span'(124,44,124,48,7217,4),['out'(_r3)],'line','|~|'('prefix'('src_span'(124,56,124,64,7229,8),[],'ready_in','val_of'('ReporterStall','src_span'(124,68,124,81,7241,13)),'src_span'(124,65,124,67,7237,25)),'stop'('src_span'(124,87,124,91,7260,4)),'src_span_operator'('no_loc_info_available','src_span'(124,83,124,86,7256,3))),'src_span'(124,51,124,53,7223,44)),'src_span'(124,41,124,43,7213,63)),'prefix'('src_span'(125,21,125,32,7287,11),['inGuard'(_r4,'val_of'('OTHER','src_span'(125,35,125,40,7301,5)))],'report_chan','prefix'('src_span'(125,44,125,48,7310,4),['out'(_r4)],'line','val_of'('ReporterStall','src_span'(125,54,125,67,7320,13)),'src_span'(125,51,125,53,7316,19)),'src_span'(125,41,125,43,7306,35)),'src_span_operator'('no_loc_info_available','src_span'(125,17,125,19,7283,2))),'prefix'('src_span'(126,21,126,39,7355,18),['in'(_m159),'in'(_b6)],'dotTuple'(['report_chan','wimage']),'prefix'('src_span'(126,47,126,51,7381,4),['out'('dotTuple'(['window',_m159]))],'line','prefix'('src_span'(126,64,126,70,7398,6),['out'(_b6)],'uplink','|~|'('prefix'('src_span'(127,23,127,30,7432,7),['out'(_b6)],'free_in','prefix'('src_span'(127,36,127,44,7445,8),[],'ready_in','val_of'('ReporterStall','src_span'(127,48,127,61,7457,13)),'src_span'(127,45,127,47,7453,25)),'src_span'(127,33,127,35,7441,31)),'stop'('src_span'(127,67,127,71,7476,4)),'src_span_operator'('no_loc_info_available','src_span'(127,63,127,66,7472,3))),'src_span'(126,73,127,20,7406,77)),'src_span'(126,61,126,63,7394,96)),'src_span'(126,44,126,46,7377,106)),'src_span_operator'('no_loc_info_available','src_span'(126,17,126,19,7351,2))),'src_span'(124,1,127,73,7174,308)).
'agent'('PIPE'(_Inf),'sharing'('closure'(['frame_chan','release_chan']),'val_of'('Camera','src_span'(129,17,129,23,7500,6)),_Inf,'src_span'(129,24,129,60,7507,36)),'src_span'(129,24,129,60,7507,36)).
'agent'('NETWORK'(_Inf2,_Rep,_Main),'sharing'('closure'(['ready_in','ready_out','ready_empty']),'sharing'('closure'(['free_in','free_out','poll_empty']),'sharing'('closure'(['report_chan']),'|||'('agent_call'('src_span'(131,8,131,12,7581,4),'PIPE',[_Inf2]),_Main,'src_span_operator'('no_loc_info_available','src_span'(131,18,131,21,7591,3))),_Rep,'src_span'(131,28,131,51,7601,23)),'val_of'('FREE','src_span'(132,48,132,52,7677,4)),'src_span'(132,6,132,47,7635,41)),'val_of'('READY','src_span'(133,50,133,55,7732,5)),'src_span'(133,5,133,49,7687,44)),'src_span'(133,5,133,49,7687,44)).
'agent'('SYS'(_Inf3,_Rep2,_Main2),'sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(134,23,134,26,7760,3)),'agent_call'('src_span'(134,54,134,61,7791,7),'NETWORK',[_Inf3,_Rep2,_Main2]),'src_span'(134,27,134,53,7764,26)),'src_span'(134,27,134,53,7764,26)).
'bindval'('CYCLE','prefix'('src_span'(136,9,136,23,7824,14),[],'g_trigger_chan','val_of'('CYCLE','src_span'(136,27,136,32,7842,5)),'src_span'(136,24,136,26,7838,23)),'src_span'(136,1,136,32,7816,31)).
'agent'('OBS'(_cam,_pend,_best7,_sp7,_send,_slot),'[]'('[]'('[]'('[]'('[]'('[]'('prefix'('src_span'(145,6,145,16,8389,10),['in'(_i8),'in'(_b7)],'frame_chan','ifte'('=='(_b7,_cam),'agent_call'('src_span'(145,42,145,45,8425,3),'OBS',['val_of'('NONE','src_span'(145,46,145,50,8429,4)),_b7,_best7,_sp7,_send,_slot]),'prefix'('src_span'(145,82,145,87,8465,5),[],'error','stop'('src_span'(145,91,145,95,8474,4)),'src_span'(145,88,145,90,8470,13)),'no_loc_info_available','no_loc_info_available','src_span'(145,77,145,81,8459,53)),'src_span'(145,21,145,23,8403,78)),'prefix'('src_span'(146,6,146,18,8486,12),['in'(_b8)],'release_chan','ifte'('bool_and'('bool_and'('=='(_cam,'val_of'('NONE','src_span'(146,35,146,39,8515,4))),'!='(_pend,'val_of'('NONE','src_span'(146,52,146,56,8532,4)))),'agent_call'('src_span'(146,61,146,67,8541,6),'member',[_b8,_sp7])),'agent_call'('src_span'(147,30,147,33,8584,3),'OBS',[_b8,_pend,_best7,'agent_call'('src_span'(147,49,147,53,8603,4),'diff',[_sp7,'setExp'('rangeEnum'([_b8]))]),_send,_slot]),'prefix'('src_span'(147,81,147,86,8635,5),[],'error','stop'('src_span'(147,90,147,94,8644,4)),'src_span'(147,87,147,89,8640,13)),'no_loc_info_available','no_loc_info_available','src_span'(147,76,147,80,8629,64)),'src_span'(146,21,146,23,8500,151)),'src_span_operator'('no_loc_info_available','src_span'(146,2,146,4,8482,2))),'prefix'('src_span'(148,6,148,12,8656,6),['in'(_o),'in'(_b9)],'scored','ifte'('!='(_b9,_pend),'prefix'('src_span'(148,39,148,44,8689,5),[],'error','stop'('src_span'(148,48,148,52,8698,4)),'src_span'(148,45,148,47,8694,13)),'ifte'('=='(_o,'better'),'agent_call'('src_span'(150,26,150,29,8768,3),'OBS',[_cam,'val_of'('NONE','src_span'(150,35,150,39,8777,4)),_b9,'ifte'('=='(_best7,'val_of'('NONE','src_span'(150,55,150,59,8797,4))),_sp7,'agent_call'('src_span'(150,73,150,78,8815,5),'union',[_sp7,'setExp'('rangeEnum'([_best7]))]),'no_loc_info_available','no_loc_info_available','src_span'(150,68,150,72,8809,25)),_send,_slot]),'agent_call'('src_span'(151,26,151,29,8871,3),'OBS',[_cam,'val_of'('NONE','src_span'(151,35,151,39,8880,4)),_best7,'agent_call'('src_span'(151,47,151,52,8892,5),'union',[_sp7,'setExp'('rangeEnum'([_b9]))]),_send,_slot]),'no_loc_info_available','no_loc_info_available','src_span'(150,104,151,25,8845,151)),'no_loc_info_available','no_loc_info_available','src_span'(148,53,149,25,8702,230)),'src_span'(148,17,148,19,8666,256)),'src_span_operator'('no_loc_info_available','src_span'(148,2,148,4,8652,2))),'prefix'('src_span'(152,6,152,14,8927,8),['in'(_b179)],'suppress','ifte'('=='(_b179,_best7),'agent_call'('src_span'(152,39,152,42,8960,3),'OBS',[_cam,_pend,'val_of'('NONE','src_span'(152,54,152,58,8975,4)),'agent_call'('src_span'(152,60,152,65,8981,5),'union',[_sp7,'setExp'('rangeEnum'([_b179]))]),_send,_slot]),'prefix'('src_span'(152,93,152,98,9014,5),[],'error','stop'('src_span'(152,102,152,106,9023,4)),'src_span'(152,99,152,101,9019,13)),'no_loc_info_available','no_loc_info_available','src_span'(152,88,152,92,9008,67)),'src_span'(152,17,152,19,8937,93)),'src_span_operator'('no_loc_info_available','src_span'(152,2,152,4,8923,2))),'prefix'('src_span'(153,6,153,24,9035,18),['in'(_m180),'in'(_b181)],'dotTuple'(['report_chan','wimage']),'ifte'('bool_and'('bool_and'('=='(_b181,_best7),'=='(_send,'val_of'('NONE','src_span'(153,58,153,62,9087,4)))),'=='(_slot,'val_of'('NONE','src_span'(153,75,153,79,9104,4)))),'agent_call'('src_span'(154,38,154,41,9146,3),'OBS',[_cam,_pend,'val_of'('NONE','src_span'(154,53,154,57,9161,4)),_sp7,_b181,_slot]),'prefix'('src_span'(154,77,154,82,9185,5),[],'error','stop'('src_span'(154,86,154,90,9194,4)),'src_span'(154,83,154,85,9190,13)),'no_loc_info_available','no_loc_info_available','src_span'(154,72,154,76,9179,52)),'src_span'(153,29,153,31,9057,144)),'src_span_operator'('no_loc_info_available','src_span'(153,2,153,4,9031,2))),'prefix'('src_span'(155,6,155,13,9206,7),['in'(_b182)],'free_in','ifte'('=='(_b182,_send),'agent_call'('src_span'(155,38,155,41,9238,3),'OBS',[_cam,_pend,_best7,_sp7,'val_of'('NONE','src_span'(155,63,155,67,9263,4)),_b182]),'prefix'('src_span'(155,77,155,82,9277,5),[],'error','stop'('src_span'(155,86,155,90,9286,4)),'src_span'(155,83,155,85,9282,13)),'no_loc_info_available','no_loc_info_available','src_span'(155,72,155,76,9271,52)),'src_span'(155,16,155,18,9215,78)),'src_span_operator'('no_loc_info_available','src_span'(155,2,155,4,9202,2))),'prefix'('src_span'(156,6,156,14,9298,8),['in'(_b183)],'free_out','ifte'('=='(_b183,_slot),'agent_call'('src_span'(156,39,156,42,9331,3),'OBS',[_cam,_pend,_best7,'agent_call'('src_span'(156,60,156,65,9352,5),'union',[_sp7,'setExp'('rangeEnum'([_b183]))]),_send,'val_of'('NONE','src_span'(156,82,156,86,9374,4))]),'prefix'('src_span'(156,93,156,98,9385,5),[],'error','stop'('src_span'(156,102,156,106,9394,4)),'src_span'(156,99,156,101,9390,13)),'no_loc_info_available','no_loc_info_available','src_span'(156,88,156,92,9379,67)),'src_span'(156,17,156,19,9308,93)),'src_span_operator'('no_loc_info_available','src_span'(156,2,156,4,9294,2))),'no_loc_info_available').
'bindval'('ROLE_EVENTS','closure'(['frame_chan','release_chan','scored','suppress','dotTuple'(['report_chan','wimage']),'free_in','free_out']),'src_span'(158,1,158,102,9402,101)).
'agent'('OBSERVED'(_P),'sharing'('val_of'('ROLE_EVENTS','src_span'(159,20,159,31,9523,11)),_P,'agent_call'('src_span'(159,35,159,38,9538,3),'OBS',['int'(0),'val_of'('NONE','src_span'(159,42,159,46,9545,4)),'val_of'('NONE','src_span'(159,48,159,52,9551,4)),'setExp'('rangeEnum'(['int'(1),'int'(2),'int'(3)])),'val_of'('NONE','src_span'(159,65,159,69,9568,4)),'val_of'('NONE','src_span'(159,71,159,75,9574,4))]),'src_span'(159,17,159,34,9520,17)),'src_span'(159,17,159,34,9520,17)).
'bindval'('Inference1','prefix'('src_span'(10,14,10,24,584,10),['in'(_i9),'in'(_p7)],'frame_chan','prefix'('src_span'(10,32,10,43,602,11),['out'('dotTuple'(['started','inference']))],'report_chan','agent_call'('src_span'(10,65,10,71,635,6),'Infer1',[_i9,_p7,'agent_call'('src_span'(10,78,10,82,648,4),'diff',['val_of'('IDS','src_span'(10,83,10,86,653,3)),'setExp'('rangeEnum'([_p7]))]),'val_of'('NONE','src_span'(10,94,10,98,664,4)),'true','true','int'(0)]),'src_span'(10,62,10,64,631,71)),'src_span'(10,29,10,31,598,88)),'src_span'(10,1,10,114,571,113)).
'agent'('Infer1'(_i187,_p8,_sp8,_best8,_tok7,_rdy7,_m193),'[]'('prefix'('src_span'(13,6,13,14,729,8),['in'(_b194)],'free_out','agent_call'('src_span'(13,20,13,30,743,10),'PollReady1',[_i187,_p8,'agent_call'('src_span'(13,37,13,42,760,5),'union',[_sp8,'setExp'('rangeEnum'([_b194]))]),_best8,'true',_rdy7,_m193]),'src_span'(13,17,13,19,739,58)),'prefix'('src_span'(14,9,14,19,805,10),[],'poll_empty','agent_call'('src_span'(14,23,14,33,819,10),'PollReady1',[_i187,_p8,_sp8,_best8,_tok7,_rdy7,_m193]),'src_span'(14,20,14,22,815,53)),'src_span_operator'('no_loc_info_available','src_span'(14,5,14,7,801,2))),'no_loc_info_available').
'agent'('PollReady1'(_i195,_p9,_sp9,_best9,_tok8,_rdy8,_m201),'[]'('prefix'('src_span'(17,6,17,15,908,9),[],'ready_out','agent_call'('src_span'(17,19,17,27,921,8),'Release1',[_i195,_p9,_sp9,_best9,_tok8,'true',_m201]),'src_span'(17,16,17,18,917,51)),'prefix'('src_span'(18,9,18,20,969,11),[],'ready_empty','agent_call'('src_span'(18,24,18,32,984,8),'Release1',[_i195,_p9,_sp9,_best9,_tok8,_rdy8,_m201]),'src_span'(18,21,18,23,980,52)),'src_span_operator'('no_loc_info_available','src_span'(18,5,18,7,965,2))),'no_loc_info_available').
'agent'('Release1'(_i202,_p203,_sp204,_best205,_tok9,_rdy9,_m208),'repInternalChoice'(['comprehensionGenerator'(_s2,'agent_call'('src_span'(21,13,21,18,1076,5),'union',[_sp204,'ifte'('=='(_best205,'val_of'('NONE','src_span'(21,34,21,38,1097,4))),'setExp'('rangeEnum'([])),'setExp'('rangeEnum'([_best205])),'no_loc_info_available','no_loc_info_available','src_span'(21,47,21,51,1109,14))]))],'prefix'('src_span'(22,9,22,21,1133,12),['out'(_s2)],'release_chan','agent_call'('src_span'(22,27,22,33,1151,6),'Score1',[_i202,_p203,'agent_call'('src_span'(22,40,22,44,1164,4),'diff',[_sp204,'setExp'('rangeEnum'([_s2]))]),_best205,_tok9,_rdy9,_m208]),'src_span'(22,24,22,26,1147,52)),'src_span'(21,9,21,61,1072,52)),'src_span'(21,5,22,73,1068,129)).
'agent'('Score1'(_i210,_p211,_sp212,_best213,_tok214,_rdy215,_m216),'ifte'('=='(_best213,'val_of'('NONE','src_span'(25,16,25,20,1252,4))),'|~|'('prefix'('src_span'(26,10,26,16,1271,6),['out'('failed'),'out'(_p211)],'scored','agent_call'('src_span'(26,29,26,33,1290,4),'End1',[_i210,'agent_call'('src_span'(26,37,26,42,1298,5),'union',[_sp212,'setExp'('rangeEnum'([_p211]))]),_best213,_tok214,_rdy215,_m216]),'src_span'(26,26,26,28,1286,48)),'prefix'('src_span'(27,14,27,20,1347,6),['out'('better'),'out'(_p211)],'scored','agent_call'('src_span'(27,33,27,37,1366,4),'End1',[_i210,_sp212,_p211,_tok214,_rdy215,_m216]),'src_span'(27,30,27,32,1362,33)),'src_span_operator'('no_loc_info_available','src_span'(27,9,27,12,1342,3))),'|~|'('|~|'('prefix'('src_span'(29,10,29,16,1413,6),['out'('failed'),'out'(_p211)],'scored','agent_call'('src_span'(29,29,29,33,1432,4),'End1',[_i210,'agent_call'('src_span'(29,37,29,42,1440,5),'union',[_sp212,'setExp'('rangeEnum'([_p211]))]),_best213,_tok214,_rdy215,_m216]),'src_span'(29,26,29,28,1428,48)),'prefix'('src_span'(30,14,30,20,1489,6),['out'('better'),'out'(_p211)],'scored','agent_call'('src_span'(30,33,30,37,1508,4),'End1',[_i210,'agent_call'('src_span'(30,41,30,46,1516,5),'union',[_sp212,'setExp'('rangeEnum'([_best213]))]),_p211,_tok214,_rdy215,_m216]),'src_span'(30,30,30,32,1504,48)),'src_span_operator'('no_loc_info_available','src_span'(30,9,30,12,1484,3))),'prefix'('src_span'(31,14,31,20,1565,6),['out'('worse'),'out'(_p211)],'scored','agent_call'('src_span'(31,32,31,36,1583,4),'End1',[_i210,'agent_call'('src_span'(31,40,31,45,1591,5),'union',[_sp212,'setExp'('rangeEnum'([_p211]))]),_best213,_tok214,_rdy215,_m216]),'src_span'(31,29,31,31,1579,48)),'src_span_operator'('no_loc_info_available','src_span'(31,9,31,12,1560,3))),'no_loc_info_available','no_loc_info_available','no_loc_info_available'),'src_span'(25,5,31,75,1241,385)).
'agent'('End1'(_i217,_sp218,_best219,_tok220,_rdy221,_m222),'ifte'(_rdy221,'ifte'('bool_and'('=='('%'(_i217,'val_of'('W','src_span'(37,16,37,17,1861,1))),'-'('val_of'('W','src_span'(37,21,37,22,1866,1)),'int'(1))),_tok220),'ifte'('=='(_best219,'val_of'('NONE','src_span'(38,24,38,28,1908,4))),'prefix'('src_span'(38,34,38,45,1918,11),['out'('dotTuple'(['window',_m222]))],'report_chan','agent_call'('src_span'(38,58,38,63,1942,5),'Next1',[_sp218,'val_of'('NONE','src_span'(38,68,38,72,1952,4)),_tok220,'false','int'(0)]),'src_span'(38,55,38,57,1938,43)),'|~|'('prefix'('src_span'(39,19,39,30,1991,11),['out'('dotTuple'(['wimage',_m222,_best219]))],'report_chan','agent_call'('src_span'(39,48,39,53,2020,5),'Next1',[_sp218,'val_of'('NONE','src_span'(39,58,39,62,2030,4)),'false','false','int'(0)]),'src_span'(39,45,39,47,2016,50)),'prefix'('src_span'(40,23,40,31,2076,8),['out'(_best219)],'suppress','prefix'('src_span'(40,40,40,51,2093,11),['out'('dotTuple'(['window',_m222]))],'report_chan','agent_call'('src_span'(40,64,40,69,2117,5),'Next1',['agent_call'('src_span'(40,70,40,75,2123,5),'union',[_sp218,'setExp'('rangeEnum'([_best219]))]),'val_of'('NONE','src_span'(40,89,40,93,2142,4)),_tok220,'false','int'(0)]),'src_span'(40,61,40,63,2113,58)),'src_span'(40,37,40,39,2089,78)),'src_span_operator'('no_loc_info_available','src_span'(40,18,40,21,2071,3))),'no_loc_info_available','no_loc_info_available','no_loc_info_available'),'ifte'('=='('%'(_i217,'val_of'('W','src_span'(41,21,41,22,2184,1))),'-'('val_of'('W','src_span'(41,26,41,27,2189,1)),'int'(1))),'prefix'('src_span'(42,13,42,18,2212,5),[],'merge','prefix'('src_span'(42,22,42,33,2221,11),['out'('scores')],'report_chan','agent_call'('src_span'(42,44,42,49,2243,5),'Next1',[_sp218,_best219,_tok220,'false','agent_call'('src_span'(42,72,42,75,2271,3),'sat',['+'(_m222,'int'(1))])]),'src_span'(42,41,42,43,2239,50)),'src_span'(42,19,42,21,2217,70)),'prefix'('src_span'(44,13,44,24,2308,11),['out'('scores')],'report_chan','agent_call'('src_span'(44,35,44,40,2330,5),'Next1',[_sp218,_best219,_tok220,'false',_m222]),'src_span'(44,32,44,34,2326,41)),'no_loc_info_available','no_loc_info_available','src_span'(42,84,44,12,2282,148)),'no_loc_info_available','no_loc_info_available','src_span'(40,111,41,13,2163,463)),'ifte'('=='('%'(_i217,'val_of'('W','src_span'(45,17,45,18,2377,1))),'-'('val_of'('W','src_span'(45,22,45,23,2382,1)),'int'(1))),'prefix'('src_span'(46,9,46,14,2401,5),[],'merge','agent_call'('src_span'(46,18,46,23,2410,5),'Next1',[_sp218,_best219,_tok220,_rdy221,'agent_call'('src_span'(46,44,46,47,2436,3),'sat',['+'(_m222,'int'(1))])]),'src_span'(46,15,46,17,2406,46)),'agent_call'('src_span'(48,9,48,14,2465,5),'Next1',[_sp218,_best219,_tok220,_rdy221,_m222]),'no_loc_info_available','no_loc_info_available','src_span'(46,56,48,8,2447,92)),'src_span'(36,5,36,11,1834,6),'src_span'(36,12,37,8,1840,523),'src_span'(44,66,45,9,2360,639)),'src_span'(36,5,48,37,1834,659)).
'agent'('Next1'(_sp223,_best224,_tok225,_rdy226,_m227),'prefix'('src_span'(50,32,50,42,2526,10),['in'(_j2),'in'(_p229)],'frame_chan','agent_call'('src_span'(50,50,50,56,2544,6),'Infer1',[_j2,_p229,_sp223,_best224,_tok225,_rdy226,_m227]),'src_span'(50,47,50,49,2540,41)),'src_span'(50,32,50,85,2526,53)).
'assertRef'('False','agent_call'('src_span'(53,8,53,11,2589,3),'RUN',['agent_call'('src_span'(53,12,53,16,2593,4),'diff',['Events','setExp'('rangeEnum'(['error','overflow']))])]),'Trace','agent_call'('src_span'(53,49,53,57,2630,8),'OBSERVED',['agent_call'('src_span'(53,58,53,61,2639,3),'SYS',['val_of'('Inference1','src_span'(53,62,53,72,2643,10)),'val_of'('Reporter','src_span'(53,74,53,82,2655,8)),'val_of'('MainApp','src_span'(53,84,53,91,2665,7))])]),'src_span'(53,1,53,93,2582,92)).
'bindval'('Inference2','prefix'('src_span'(58,14,58,24,2923,10),['in'(_i230),'in'(_p231)],'frame_chan','prefix'('src_span'(58,32,58,43,2941,11),['out'('dotTuple'(['started','inference']))],'report_chan','agent_call'('src_span'(58,65,58,71,2974,6),'Infer2',[_i230,_p231,'agent_call'('src_span'(58,78,58,82,2987,4),'diff',['val_of'('IDS','src_span'(58,83,58,86,2992,3)),'setExp'('rangeEnum'([_p231]))]),'val_of'('NONE','src_span'(58,94,58,98,3003,4)),'true','true','int'(0)]),'src_span'(58,62,58,64,2970,71)),'src_span'(58,29,58,31,2937,88)),'src_span'(58,1,58,114,2910,113)).
'agent'('Infer2'(_i232,_p233,_sp234,_best235,_tok236,_rdy237,_m238),'[]'('prefix'('src_span'(61,6,61,14,3068,8),['in'(_b239)],'free_out','agent_call'('src_span'(61,20,61,30,3082,10),'PollReady2',[_i232,_p233,'agent_call'('src_span'(61,37,61,42,3099,5),'union',[_sp234,'setExp'('rangeEnum'([_b239]))]),_best235,'true',_rdy237,_m238]),'src_span'(61,17,61,19,3078,58)),'prefix'('src_span'(62,9,62,19,3144,10),[],'poll_empty','agent_call'('src_span'(62,23,62,33,3158,10),'PollReady2',[_i232,_p233,_sp234,_best235,_tok236,_rdy237,_m238]),'src_span'(62,20,62,22,3154,53)),'src_span_operator'('no_loc_info_available','src_span'(62,5,62,7,3140,2))),'no_loc_info_available').
'agent'('PollReady2'(_i240,_p241,_sp242,_best243,_tok244,_rdy245,_m246),'[]'('prefix'('src_span'(65,6,65,15,3247,9),[],'ready_out','agent_call'('src_span'(65,19,65,27,3260,8),'Release2',[_i240,_p241,_sp242,_best243,_tok244,'true',_m246]),'src_span'(65,16,65,18,3256,51)),'prefix'('src_span'(66,9,66,20,3308,11),[],'ready_empty','agent_call'('src_span'(66,24,66,32,3323,8),'Release2',[_i240,_p241,_sp242,_best243,_tok244,_rdy245,_m246]),'src_span'(66,21,66,23,3319,52)),'src_span_operator'('no_loc_info_available','src_span'(66,5,66,7,3304,2))),'no_loc_info_available').
'agent'('Release2'(_i247,_p248,_sp249,_best250,_tok251,_rdy252,_m253),'repInternalChoice'(['comprehensionGenerator'(_s3,_sp249)],'prefix'('src_span'(69,18,69,30,3420,12),['out'(_s3)],'release_chan','agent_call'('src_span'(69,36,69,42,3438,6),'Score2',[_i247,_p248,'agent_call'('src_span'(69,49,69,53,3451,4),'diff',[_sp249,'setExp'('rangeEnum'([_s3]))]),_best250,_tok251,_rdy252,_m253]),'src_span'(69,33,69,35,3434,52)),'src_span'(69,9,69,17,3411,8)),'src_span'(69,5,69,82,3407,77)).
'agent'('Score2'(_i255,_p256,_sp257,_best258,_tok259,_rdy260,_m261),'ifte'('=='(_best258,'val_of'('NONE','src_span'(72,16,72,20,3539,4))),'|~|'('prefix'('src_span'(73,10,73,16,3558,6),['out'('failed'),'out'(_p256)],'scored','agent_call'('src_span'(73,29,73,33,3577,4),'End2',[_i255,'agent_call'('src_span'(73,37,73,42,3585,5),'union',[_sp257,'setExp'('rangeEnum'([_p256]))]),_best258,_tok259,_rdy260,_m261]),'src_span'(73,26,73,28,3573,48)),'prefix'('src_span'(74,14,74,20,3634,6),['out'('better'),'out'(_p256)],'scored','agent_call'('src_span'(74,33,74,37,3653,4),'End2',[_i255,_sp257,_p256,_tok259,_rdy260,_m261]),'src_span'(74,30,74,32,3649,33)),'src_span_operator'('no_loc_info_available','src_span'(74,9,74,12,3629,3))),'|~|'('|~|'('prefix'('src_span'(76,10,76,16,3700,6),['out'('failed'),'out'(_p256)],'scored','agent_call'('src_span'(76,29,76,33,3719,4),'End2',[_i255,'agent_call'('src_span'(76,37,76,42,3727,5),'union',[_sp257,'setExp'('rangeEnum'([_p256]))]),_best258,_tok259,_rdy260,_m261]),'src_span'(76,26,76,28,3715,48)),'prefix'('src_span'(77,14,77,20,3776,6),['out'('better'),'out'(_p256)],'scored','agent_call'('src_span'(77,33,77,37,3795,4),'End2',[_i255,'agent_call'('src_span'(77,41,77,46,3803,5),'union',[_sp257,'setExp'('rangeEnum'([_best258]))]),_p256,_tok259,_rdy260,_m261]),'src_span'(77,30,77,32,3791,48)),'src_span_operator'('no_loc_info_available','src_span'(77,9,77,12,3771,3))),'prefix'('src_span'(78,14,78,20,3852,6),['out'('worse'),'out'(_p256)],'scored','agent_call'('src_span'(78,32,78,36,3870,4),'End2',[_i255,'agent_call'('src_span'(78,40,78,45,3878,5),'union',[_sp257,'setExp'('rangeEnum'([_p256]))]),_best258,_tok259,_rdy260,_m261]),'src_span'(78,29,78,31,3866,48)),'src_span_operator'('no_loc_info_available','src_span'(78,9,78,12,3847,3))),'no_loc_info_available','no_loc_info_available','no_loc_info_available'),'src_span'(72,5,78,75,3528,385)).
'agent'('End2'(_i262,_sp263,_best264,_tok265,_rdy266,_m267),'ifte'(_rdy266,'ifte'('=='('%'(_i262,'val_of'('W','src_span'(84,16,84,17,4148,1))),'-'('val_of'('W','src_span'(84,21,84,22,4153,1)),'int'(1))),'ifte'('=='(_best264,'val_of'('NONE','src_span'(85,24,85,28,4187,4))),'prefix'('src_span'(85,34,85,45,4197,11),['out'('dotTuple'(['window',_m267]))],'report_chan','agent_call'('src_span'(85,58,85,63,4221,5),'Next2',[_sp263,'val_of'('NONE','src_span'(85,68,85,72,4231,4)),_tok265,'false','int'(0)]),'src_span'(85,55,85,57,4217,43)),'|~|'('prefix'('src_span'(86,19,86,30,4270,11),['out'('dotTuple'(['wimage',_m267,_best264]))],'report_chan','agent_call'('src_span'(86,48,86,53,4299,5),'Next2',[_sp263,'val_of'('NONE','src_span'(86,58,86,62,4309,4)),'false','false','int'(0)]),'src_span'(86,45,86,47,4295,50)),'prefix'('src_span'(87,23,87,31,4355,8),['out'(_best264)],'suppress','prefix'('src_span'(87,40,87,51,4372,11),['out'('dotTuple'(['window',_m267]))],'report_chan','agent_call'('src_span'(87,64,87,69,4396,5),'Next2',['agent_call'('src_span'(87,70,87,75,4402,5),'union',[_sp263,'setExp'('rangeEnum'([_best264]))]),'val_of'('NONE','src_span'(87,89,87,93,4421,4)),_tok265,'false','int'(0)]),'src_span'(87,61,87,63,4392,58)),'src_span'(87,37,87,39,4368,78)),'src_span_operator'('no_loc_info_available','src_span'(87,18,87,21,4350,3))),'no_loc_info_available','no_loc_info_available','no_loc_info_available'),'ifte'('=='('%'(_i262,'val_of'('W','src_span'(88,21,88,22,4463,1))),'-'('val_of'('W','src_span'(88,26,88,27,4468,1)),'int'(1))),'prefix'('src_span'(89,13,89,18,4491,5),[],'merge','prefix'('src_span'(89,22,89,33,4500,11),['out'('scores')],'report_chan','agent_call'('src_span'(89,44,89,49,4522,5),'Next2',[_sp263,_best264,_tok265,'false','agent_call'('src_span'(89,72,89,75,4550,3),'sat',['+'(_m267,'int'(1))])]),'src_span'(89,41,89,43,4518,50)),'src_span'(89,19,89,21,4496,70)),'prefix'('src_span'(91,13,91,24,4587,11),['out'('scores')],'report_chan','agent_call'('src_span'(91,35,91,40,4609,5),'Next2',[_sp263,_best264,_tok265,'false',_m267]),'src_span'(91,32,91,34,4605,41)),'no_loc_info_available','no_loc_info_available','src_span'(89,84,91,12,4561,148)),'no_loc_info_available','no_loc_info_available','src_span'(87,111,88,13,4442,463)),'ifte'('=='('%'(_i262,'val_of'('W','src_span'(92,17,92,18,4656,1))),'-'('val_of'('W','src_span'(92,22,92,23,4661,1)),'int'(1))),'prefix'('src_span'(93,9,93,14,4680,5),[],'merge','agent_call'('src_span'(93,18,93,23,4689,5),'Next2',[_sp263,_best264,_tok265,_rdy266,'agent_call'('src_span'(93,44,93,47,4715,3),'sat',['+'(_m267,'int'(1))])]),'src_span'(93,15,93,17,4685,46)),'agent_call'('src_span'(95,9,95,14,4744,5),'Next2',[_sp263,_best264,_tok265,_rdy266,_m267]),'no_loc_info_available','no_loc_info_available','src_span'(93,56,95,8,4726,92)),'src_span'(83,5,83,11,4121,6),'src_span'(83,12,84,8,4127,515),'src_span'(91,66,92,9,4639,631)),'src_span'(83,5,95,37,4121,651)).
'agent'('Next2'(_sp268,_best269,_tok270,_rdy271,_m272),'prefix'('src_span'(97,32,97,42,4805,10),['in'(_j3),'in'(_p274)],'frame_chan','agent_call'('src_span'(97,50,97,56,4823,6),'Infer2',[_j3,_p274,_sp268,_best269,_tok270,_rdy271,_m272]),'src_span'(97,47,97,49,4819,41)),'src_span'(97,32,97,85,4805,53)).
'assertRef'('False','agent_call'('src_span'(100,8,100,11,4868,3),'RUN',['agent_call'('src_span'(100,12,100,16,4872,4),'diff',['Events','setExp'('rangeEnum'(['error','overflow']))])]),'Trace','agent_call'('src_span'(100,49,100,57,4909,8),'OBSERVED',['agent_call'('src_span'(100,58,100,61,4918,3),'SYS',['val_of'('Inference2','src_span'(100,62,100,72,4922,10)),'val_of'('Reporter','src_span'(100,74,100,82,4934,8)),'val_of'('MainApp','src_span'(100,84,100,91,4944,7))])]),'src_span'(100,1,100,93,4861,92)).
'bindval'('Inference4','prefix'('src_span'(104,14,104,24,5141,10),['in'(_i275),'in'(_p276)],'frame_chan','prefix'('src_span'(104,32,104,43,5159,11),['out'('dotTuple'(['started','inference']))],'report_chan','agent_call'('src_span'(104,65,104,71,5192,6),'Infer4',[_i275,_p276,'agent_call'('src_span'(104,78,104,82,5205,4),'diff',['val_of'('IDS','src_span'(104,83,104,86,5210,3)),'setExp'('rangeEnum'([_p276]))]),'val_of'('NONE','src_span'(104,94,104,98,5221,4)),'true','true','int'(0)]),'src_span'(104,62,104,64,5188,71)),'src_span'(104,29,104,31,5155,88)),'src_span'(104,1,104,114,5128,113)).
'agent'('Infer4'(_i277,_p278,_sp279,_best280,_tok281,_rdy282,_m283),'[]'('prefix'('src_span'(107,6,107,14,5286,8),['in'(_b284)],'free_out','agent_call'('src_span'(107,20,107,30,5300,10),'PollReady4',[_i277,_p278,'agent_call'('src_span'(107,37,107,42,5317,5),'union',[_sp279,'setExp'('rangeEnum'([_b284]))]),_best280,'true',_rdy282,_m283]),'src_span'(107,17,107,19,5296,58)),'prefix'('src_span'(108,9,108,19,5362,10),[],'poll_empty','agent_call'('src_span'(108,23,108,33,5376,10),'PollReady4',[_i277,_p278,_sp279,_best280,_tok281,_rdy282,_m283]),'src_span'(108,20,108,22,5372,53)),'src_span_operator'('no_loc_info_available','src_span'(108,5,108,7,5358,2))),'no_loc_info_available').
'agent'('PollReady4'(_i285,_p286,_sp287,_best288,_tok289,_rdy290,_m291),'[]'('prefix'('src_span'(111,6,111,15,5465,9),[],'ready_out','agent_call'('src_span'(111,19,111,27,5478,8),'Release4',[_i285,_p286,_sp287,_best288,_tok289,'true',_m291]),'src_span'(111,16,111,18,5474,51)),'prefix'('src_span'(112,9,112,20,5526,11),[],'ready_empty','agent_call'('src_span'(112,24,112,32,5541,8),'Release4',[_i285,_p286,_sp287,_best288,_tok289,_rdy290,_m291]),'src_span'(112,21,112,23,5537,52)),'src_span_operator'('no_loc_info_available','src_span'(112,5,112,7,5522,2))),'no_loc_info_available').
'agent'('Release4'(_i292,_p293,_sp294,_best295,_tok296,_rdy297,_m298),'repInternalChoice'(['comprehensionGenerator'(_s4,_sp294)],'prefix'('src_span'(115,18,115,30,5638,12),['out'(_s4)],'release_chan','agent_call'('src_span'(115,36,115,42,5656,6),'Score4',[_i292,_p293,'agent_call'('src_span'(115,49,115,53,5669,4),'diff',[_sp294,'setExp'('rangeEnum'([_s4]))]),_best295,_tok296,_rdy297,_m298]),'src_span'(115,33,115,35,5652,52)),'src_span'(115,9,115,17,5629,8)),'src_span'(115,5,115,82,5625,77)).
'agent'('Score4'(_i300,_p301,_sp302,_best303,_tok304,_rdy305,_m306),'ifte'('=='(_best303,'val_of'('NONE','src_span'(118,16,118,20,5757,4))),'|~|'('prefix'('src_span'(119,10,119,16,5776,6),['out'('failed'),'out'(_p301)],'scored','agent_call'('src_span'(119,29,119,33,5795,4),'End4',[_i300,'agent_call'('src_span'(119,37,119,42,5803,5),'union',[_sp302,'setExp'('rangeEnum'([_p301]))]),_best303,_tok304,_rdy305,_m306]),'src_span'(119,26,119,28,5791,48)),'prefix'('src_span'(120,14,120,20,5852,6),['out'('better'),'out'(_p301)],'scored','agent_call'('src_span'(120,33,120,37,5871,4),'End4',[_i300,_sp302,_p301,_tok304,_rdy305,_m306]),'src_span'(120,30,120,32,5867,33)),'src_span_operator'('no_loc_info_available','src_span'(120,9,120,12,5847,3))),'|~|'('|~|'('prefix'('src_span'(122,10,122,16,5918,6),['out'('failed'),'out'(_p301)],'scored','agent_call'('src_span'(122,29,122,33,5937,4),'End4',[_i300,'agent_call'('src_span'(122,37,122,42,5945,5),'union',[_sp302,'setExp'('rangeEnum'([_p301]))]),_best303,_tok304,_rdy305,_m306]),'src_span'(122,26,122,28,5933,48)),'prefix'('src_span'(123,14,123,20,5994,6),['out'('better'),'out'(_p301)],'scored','agent_call'('src_span'(123,33,123,37,6013,4),'End4',[_i300,'agent_call'('src_span'(123,41,123,46,6021,5),'union',[_sp302,'setExp'('rangeEnum'([_best303]))]),_p301,_tok304,_rdy305,_m306]),'src_span'(123,30,123,32,6009,48)),'src_span_operator'('no_loc_info_available','src_span'(123,9,123,12,5989,3))),'prefix'('src_span'(124,14,124,20,6070,6),['out'('worse'),'out'(_p301)],'scored','agent_call'('src_span'(124,32,124,36,6088,4),'End4',[_i300,'agent_call'('src_span'(124,40,124,45,6096,5),'union',[_sp302,'setExp'('rangeEnum'([_p301]))]),_best303,_tok304,_rdy305,_m306]),'src_span'(124,29,124,31,6084,48)),'src_span_operator'('no_loc_info_available','src_span'(124,9,124,12,6065,3))),'no_loc_info_available','no_loc_info_available','no_loc_info_available'),'src_span'(118,5,124,75,5746,385)).
'agent'('End4'(_i307,_sp308,_best309,_tok310,_rdy311,_m312),'ifte'(_rdy311,'ifte'('bool_and'('=='('%'(_i307,'val_of'('W','src_span'(130,16,130,17,6366,1))),'-'('val_of'('W','src_span'(130,21,130,22,6371,1)),'int'(1))),_tok310),'ifte'('=='(_best309,'val_of'('NONE','src_span'(131,24,131,28,6413,4))),'prefix'('src_span'(131,34,131,45,6423,11),['out'('dotTuple'(['window',_m312]))],'report_chan','agent_call'('src_span'(131,58,131,63,6447,5),'Next4',[_sp308,'val_of'('NONE','src_span'(131,68,131,72,6457,4)),_tok310,'false','int'(0)]),'src_span'(131,55,131,57,6443,43)),'|~|'('prefix'('src_span'(132,19,132,30,6496,11),['out'('dotTuple'(['wimage',_m312,_best309]))],'report_chan','agent_call'('src_span'(132,48,132,53,6525,5),'Next4',[_sp308,'val_of'('NONE','src_span'(132,58,132,62,6535,4)),'false','false','int'(0)]),'src_span'(132,45,132,47,6521,50)),'prefix'('src_span'(133,23,133,31,6581,8),['out'(_best309)],'suppress','prefix'('src_span'(133,40,133,51,6598,11),['out'('dotTuple'(['window',_m312]))],'report_chan','agent_call'('src_span'(133,64,133,69,6622,5),'Next4',['agent_call'('src_span'(133,70,133,75,6628,5),'union',[_sp308,'setExp'('rangeEnum'([_best309]))]),'val_of'('NONE','src_span'(133,89,133,93,6647,4)),_tok310,'false','int'(0)]),'src_span'(133,61,133,63,6618,58)),'src_span'(133,37,133,39,6594,78)),'src_span_operator'('no_loc_info_available','src_span'(133,18,133,21,6576,3))),'no_loc_info_available','no_loc_info_available','no_loc_info_available'),'ifte'('=='('%'(_i307,'val_of'('W','src_span'(134,21,134,22,6689,1))),'-'('val_of'('W','src_span'(134,26,134,27,6694,1)),'int'(1))),'prefix'('src_span'(135,13,135,18,6717,5),[],'merge','prefix'('src_span'(135,22,135,33,6726,11),['out'('scores')],'report_chan','agent_call'('src_span'(135,44,135,49,6748,5),'Next4',[_sp308,_best309,_tok310,'false','agent_call'('src_span'(135,72,135,75,6776,3),'sat',['+'(_m312,'int'(1))])]),'src_span'(135,41,135,43,6744,50)),'src_span'(135,19,135,21,6722,70)),'prefix'('src_span'(137,13,137,24,6813,11),['out'('scores')],'report_chan','agent_call'('src_span'(137,35,137,40,6835,5),'Next4',[_sp308,_best309,_tok310,'false',_m312]),'src_span'(137,32,137,34,6831,41)),'no_loc_info_available','no_loc_info_available','src_span'(135,84,137,12,6787,148)),'no_loc_info_available','no_loc_info_available','src_span'(133,111,134,13,6668,463)),'ifte'('=='('%'(_i307,'val_of'('W','src_span'(138,17,138,18,6882,1))),'-'('val_of'('W','src_span'(138,22,138,23,6887,1)),'int'(1))),'prefix'('src_span'(139,9,139,14,6906,5),[],'merge','prefix'('src_span'(139,18,139,29,6915,11),['out'('scores')],'report_chan','agent_call'('src_span'(139,40,139,45,6937,5),'Next4',[_sp308,_best309,_tok310,_rdy311,'agent_call'('src_span'(139,66,139,69,6963,3),'sat',['+'(_m312,'int'(1))])]),'src_span'(139,37,139,39,6933,48)),'src_span'(139,15,139,17,6911,68)),'prefix'('src_span'(141,9,141,20,6992,11),['out'('scores')],'report_chan','agent_call'('src_span'(141,31,141,36,7014,5),'Next4',[_sp308,_best309,_tok310,_rdy311,_m312]),'src_span'(141,28,141,30,7010,39)),'no_loc_info_available','no_loc_info_available','src_span'(139,78,141,8,6974,136)),'src_span'(129,5,129,11,6339,6),'src_span'(129,12,130,8,6345,523),'src_span'(137,66,138,9,6865,683)),'src_span'(129,5,141,59,6339,703)).
'agent'('Next4'(_sp313,_best314,_tok315,_rdy316,_m317),'prefix'('src_span'(143,32,143,42,7075,10),['in'(_j4),'in'(_p319)],'frame_chan','agent_call'('src_span'(143,50,143,56,7093,6),'Infer4',[_j4,_p319,_sp313,_best314,_tok315,_rdy316,_m317]),'src_span'(143,47,143,49,7089,41)),'src_span'(143,32,143,85,7075,53)).
'assertRef'('False','val_of'('CYCLE','src_span'(146,8,146,13,7138,5)),'FailureDivergence','\x5c\'('agent_call'('src_span'(146,19,146,22,7149,3),'SYS',['val_of'('Inference4','src_span'(146,23,146,33,7153,10)),'val_of'('ReporterStall','src_span'(146,35,146,48,7165,13)),'agent_call'('src_span'(146,50,146,58,7180,8),'MainAppN',['int'(2)])]),'agent_call'('src_span'(146,65,146,69,7195,4),'diff',['Events','setExp'('rangeEnum'(['g_trigger_chan']))]),'src_span_operator'('no_loc_info_available','src_span'(146,63,146,64,7193,1))),'src_span'(146,1,146,95,7131,94)).
'comment'('lineComment'('-- Positive controls for Uplink.csp: plausible wrong designs. Each must FAIL its check, showing'),'src_position'(1,1,0,95)).
'comment'('lineComment'('-- that the checks of the real model can detect these faults. Each control is the Inference of'),'src_position'(2,1,96,94)).
'comment'('lineComment'('-- Uplink_defs.csp with one part changed (the variants are copies with a suffix).'),'src_position'(3,1,191,81)).
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
'comment'('lineComment'('-- Control 1 (must break the buffer roles): Camera may be retargeted to the window\x27\s best. The'),'src_position'(7,1,301,94)).
'comment'('lineComment'('-- release picks from the spares and the best, as if the best buffer were free; Inference still'),'src_position'(8,1,396,95)).
'comment'('lineComment'('-- keeps it as the best, so the DMA overwrites the JPEG that may be sent next.'),'src_position'(9,1,492,78)).
'comment'('lineComment'('-- The filter (best >= T and at least K frames >= T) depends on the scores, so the model'),'src_position'(33,1,1628,88)).
'comment'('lineComment'('-- chooses internally between sending and suppressing a window that has a best.'),'src_position'(34,1,1717,79)).
'comment'('lineComment'('-- expected: false'),'src_position'(53,96,2677,18)).
'comment'('lineComment'('-- Control 2 (must break the buffer roles): Inference sends a Window report with an image when'),'src_position'(55,1,2697,94)).
'comment'('lineComment'('-- it holds the ready token but not the free token, i.e. before it has read back the buffer of'),'src_position'(56,1,2792,94)).
'comment'('lineComment'('-- the previous image.'),'src_position'(57,1,2887,22)).
'comment'('lineComment'('-- The filter (best >= T and at least K frames >= T) depends on the scores, so the model'),'src_position'(80,1,3915,88)).
'comment'('lineComment'('-- chooses internally between sending and suppressing a window that has a best.'),'src_position'(81,1,4004,79)).
'comment'('lineComment'('-- expected: false'),'src_position'(100,96,4956,18)).
'comment'('lineComment'('-- Control 4 (must stall Camera when the uplink stalls): Inference writes its Scores report on'),'src_position'(102,1,4976,94)).
'comment'('lineComment'('-- every frame, whether or not it holds the ready token.'),'src_position'(103,1,5071,56)).
'comment'('lineComment'('-- The filter (best >= T and at least K frames >= T) depends on the scores, so the model'),'src_position'(126,1,6133,88)).
'comment'('lineComment'('-- chooses internally between sending and suppressing a window that has a best.'),'src_position'(127,1,6222,79)).
'comment'('lineComment'('-- expected: false'),'src_position'(146,98,7228,18)).
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
'symbol'('m159','m','src_span'(126,40,126,41,7374,1),'Ident (Prolog Variable)').
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
'symbol'('b179','b','src_span'(152,15,152,16,8936,1),'Ident (Prolog Variable)').
'symbol'('m180','m','src_span'(153,25,153,26,9054,1),'Ident (Prolog Variable)').
'symbol'('b181','b','src_span'(153,27,153,28,9056,1),'Ident (Prolog Variable)').
'symbol'('b182','b','src_span'(155,14,155,15,9214,1),'Ident (Prolog Variable)').
'symbol'('b183','b','src_span'(156,15,156,16,9307,1),'Ident (Prolog Variable)').
'symbol'('ROLE_EVENTS','ROLE_EVENTS','src_span'(158,1,158,12,9402,11),'Ident (Groundrep.)').
'symbol'('OBSERVED','OBSERVED','src_span'(159,1,159,9,9504,8),'Funktion or Process').
'symbol'('P','P','src_span'(159,10,159,11,9513,1),'Ident (Prolog Variable)').
'symbol'('Inference1','Inference1','src_span'(10,1,10,11,571,10),'Ident (Groundrep.)').
'symbol'('i9','i','src_span'(10,25,10,26,595,1),'Ident (Prolog Variable)').
'symbol'('p7','p','src_span'(10,27,10,28,597,1),'Ident (Prolog Variable)').
'symbol'('diff','diff','src_span'(10,78,10,82,648,4),'BuiltIn primitive').
'symbol'('Infer1','Infer1','src_span'(12,1,12,7,686,6),'Funktion or Process').
'symbol'('i187','i','src_span'(12,8,12,9,693,1),'Ident (Prolog Variable)').
'symbol'('p8','p','src_span'(12,11,12,12,696,1),'Ident (Prolog Variable)').
'symbol'('sp8','sp','src_span'(12,14,12,16,699,2),'Ident (Prolog Variable)').
'symbol'('best8','best','src_span'(12,18,12,22,703,4),'Ident (Prolog Variable)').
'symbol'('tok7','tok','src_span'(12,24,12,27,709,3),'Ident (Prolog Variable)').
'symbol'('rdy7','rdy','src_span'(12,29,12,32,714,3),'Ident (Prolog Variable)').
'symbol'('m193','m','src_span'(12,34,12,35,719,1),'Ident (Prolog Variable)').
'symbol'('b194','b','src_span'(13,15,13,16,738,1),'Ident (Prolog Variable)').
'symbol'('PollReady1','PollReady1','src_span'(16,1,16,11,861,10),'Funktion or Process').
'symbol'('i195','i','src_span'(16,12,16,13,872,1),'Ident (Prolog Variable)').
'symbol'('p9','p','src_span'(16,15,16,16,875,1),'Ident (Prolog Variable)').
'symbol'('sp9','sp','src_span'(16,18,16,20,878,2),'Ident (Prolog Variable)').
'symbol'('best9','best','src_span'(16,22,16,26,882,4),'Ident (Prolog Variable)').
'symbol'('tok8','tok','src_span'(16,28,16,31,888,3),'Ident (Prolog Variable)').
'symbol'('rdy8','rdy','src_span'(16,33,16,36,893,3),'Ident (Prolog Variable)').
'symbol'('m201','m','src_span'(16,38,16,39,898,1),'Ident (Prolog Variable)').
'symbol'('Release1','Release1','src_span'(20,1,20,9,1024,8),'Funktion or Process').
'symbol'('i202','i','src_span'(20,10,20,11,1033,1),'Ident (Prolog Variable)').
'symbol'('p203','p','src_span'(20,13,20,14,1036,1),'Ident (Prolog Variable)').
'symbol'('sp204','sp','src_span'(20,16,20,18,1039,2),'Ident (Prolog Variable)').
'symbol'('best205','best','src_span'(20,20,20,24,1043,4),'Ident (Prolog Variable)').
'symbol'('tok9','tok','src_span'(20,26,20,29,1049,3),'Ident (Prolog Variable)').
'symbol'('rdy9','rdy','src_span'(20,31,20,34,1054,3),'Ident (Prolog Variable)').
'symbol'('m208','m','src_span'(20,36,20,37,1059,1),'Ident (Prolog Variable)').
'symbol'('s2','s','src_span'(21,9,21,10,1072,1),'Ident (Prolog Variable)').
'symbol'('diff','diff','src_span'(22,40,22,44,1164,4),'BuiltIn primitive').
'symbol'('Score1','Score1','src_span'(24,1,24,7,1199,6),'Funktion or Process').
'symbol'('i210','i','src_span'(24,8,24,9,1206,1),'Ident (Prolog Variable)').
'symbol'('p211','p','src_span'(24,11,24,12,1209,1),'Ident (Prolog Variable)').
'symbol'('sp212','sp','src_span'(24,14,24,16,1212,2),'Ident (Prolog Variable)').
'symbol'('best213','best','src_span'(24,18,24,22,1216,4),'Ident (Prolog Variable)').
'symbol'('tok214','tok','src_span'(24,24,24,27,1222,3),'Ident (Prolog Variable)').
'symbol'('rdy215','rdy','src_span'(24,29,24,32,1227,3),'Ident (Prolog Variable)').
'symbol'('m216','m','src_span'(24,34,24,35,1232,1),'Ident (Prolog Variable)').
'symbol'('End1','End1','src_span'(35,1,35,5,1797,4),'Funktion or Process').
'symbol'('i217','i','src_span'(35,6,35,7,1802,1),'Ident (Prolog Variable)').
'symbol'('sp218','sp','src_span'(35,9,35,11,1805,2),'Ident (Prolog Variable)').
'symbol'('best219','best','src_span'(35,13,35,17,1809,4),'Ident (Prolog Variable)').
'symbol'('tok220','tok','src_span'(35,19,35,22,1815,3),'Ident (Prolog Variable)').
'symbol'('rdy221','rdy','src_span'(35,24,35,27,1820,3),'Ident (Prolog Variable)').
'symbol'('m222','m','src_span'(35,29,35,30,1825,1),'Ident (Prolog Variable)').
'symbol'('Next1','Next1','src_span'(50,1,50,6,2495,5),'Funktion or Process').
'symbol'('sp223','sp','src_span'(50,7,50,9,2501,2),'Ident (Prolog Variable)').
'symbol'('best224','best','src_span'(50,11,50,15,2505,4),'Ident (Prolog Variable)').
'symbol'('tok225','tok','src_span'(50,17,50,20,2511,3),'Ident (Prolog Variable)').
'symbol'('rdy226','rdy','src_span'(50,22,50,25,2516,3),'Ident (Prolog Variable)').
'symbol'('m227','m','src_span'(50,27,50,28,2521,1),'Ident (Prolog Variable)').
'symbol'('j2','j','src_span'(50,43,50,44,2537,1),'Ident (Prolog Variable)').
'symbol'('p229','p','src_span'(50,45,50,46,2539,1),'Ident (Prolog Variable)').
'symbol'('diff','diff','src_span'(53,12,53,16,2593,4),'BuiltIn primitive').
'symbol'('Inference2','Inference2','src_span'(58,1,58,11,2910,10),'Ident (Groundrep.)').
'symbol'('i230','i','src_span'(58,25,58,26,2934,1),'Ident (Prolog Variable)').
'symbol'('p231','p','src_span'(58,27,58,28,2936,1),'Ident (Prolog Variable)').
'symbol'('Infer2','Infer2','src_span'(60,1,60,7,3025,6),'Funktion or Process').
'symbol'('i232','i','src_span'(60,8,60,9,3032,1),'Ident (Prolog Variable)').
'symbol'('p233','p','src_span'(60,11,60,12,3035,1),'Ident (Prolog Variable)').
'symbol'('sp234','sp','src_span'(60,14,60,16,3038,2),'Ident (Prolog Variable)').
'symbol'('best235','best','src_span'(60,18,60,22,3042,4),'Ident (Prolog Variable)').
'symbol'('tok236','tok','src_span'(60,24,60,27,3048,3),'Ident (Prolog Variable)').
'symbol'('rdy237','rdy','src_span'(60,29,60,32,3053,3),'Ident (Prolog Variable)').
'symbol'('m238','m','src_span'(60,34,60,35,3058,1),'Ident (Prolog Variable)').
'symbol'('b239','b','src_span'(61,15,61,16,3077,1),'Ident (Prolog Variable)').
'symbol'('PollReady2','PollReady2','src_span'(64,1,64,11,3200,10),'Funktion or Process').
'symbol'('i240','i','src_span'(64,12,64,13,3211,1),'Ident (Prolog Variable)').
'symbol'('p241','p','src_span'(64,15,64,16,3214,1),'Ident (Prolog Variable)').
'symbol'('sp242','sp','src_span'(64,18,64,20,3217,2),'Ident (Prolog Variable)').
'symbol'('best243','best','src_span'(64,22,64,26,3221,4),'Ident (Prolog Variable)').
'symbol'('tok244','tok','src_span'(64,28,64,31,3227,3),'Ident (Prolog Variable)').
'symbol'('rdy245','rdy','src_span'(64,33,64,36,3232,3),'Ident (Prolog Variable)').
'symbol'('m246','m','src_span'(64,38,64,39,3237,1),'Ident (Prolog Variable)').
'symbol'('Release2','Release2','src_span'(68,1,68,9,3363,8),'Funktion or Process').
'symbol'('i247','i','src_span'(68,10,68,11,3372,1),'Ident (Prolog Variable)').
'symbol'('p248','p','src_span'(68,13,68,14,3375,1),'Ident (Prolog Variable)').
'symbol'('sp249','sp','src_span'(68,16,68,18,3378,2),'Ident (Prolog Variable)').
'symbol'('best250','best','src_span'(68,20,68,24,3382,4),'Ident (Prolog Variable)').
'symbol'('tok251','tok','src_span'(68,26,68,29,3388,3),'Ident (Prolog Variable)').
'symbol'('rdy252','rdy','src_span'(68,31,68,34,3393,3),'Ident (Prolog Variable)').
'symbol'('m253','m','src_span'(68,36,68,37,3398,1),'Ident (Prolog Variable)').
'symbol'('s3','s','src_span'(69,9,69,10,3411,1),'Ident (Prolog Variable)').
'symbol'('Score2','Score2','src_span'(71,1,71,7,3486,6),'Funktion or Process').
'symbol'('i255','i','src_span'(71,8,71,9,3493,1),'Ident (Prolog Variable)').
'symbol'('p256','p','src_span'(71,11,71,12,3496,1),'Ident (Prolog Variable)').
'symbol'('sp257','sp','src_span'(71,14,71,16,3499,2),'Ident (Prolog Variable)').
'symbol'('best258','best','src_span'(71,18,71,22,3503,4),'Ident (Prolog Variable)').
'symbol'('tok259','tok','src_span'(71,24,71,27,3509,3),'Ident (Prolog Variable)').
'symbol'('rdy260','rdy','src_span'(71,29,71,32,3514,3),'Ident (Prolog Variable)').
'symbol'('m261','m','src_span'(71,34,71,35,3519,1),'Ident (Prolog Variable)').
'symbol'('End2','End2','src_span'(82,1,82,5,4084,4),'Funktion or Process').
'symbol'('i262','i','src_span'(82,6,82,7,4089,1),'Ident (Prolog Variable)').
'symbol'('sp263','sp','src_span'(82,9,82,11,4092,2),'Ident (Prolog Variable)').
'symbol'('best264','best','src_span'(82,13,82,17,4096,4),'Ident (Prolog Variable)').
'symbol'('tok265','tok','src_span'(82,19,82,22,4102,3),'Ident (Prolog Variable)').
'symbol'('rdy266','rdy','src_span'(82,24,82,27,4107,3),'Ident (Prolog Variable)').
'symbol'('m267','m','src_span'(82,29,82,30,4112,1),'Ident (Prolog Variable)').
'symbol'('Next2','Next2','src_span'(97,1,97,6,4774,5),'Funktion or Process').
'symbol'('sp268','sp','src_span'(97,7,97,9,4780,2),'Ident (Prolog Variable)').
'symbol'('best269','best','src_span'(97,11,97,15,4784,4),'Ident (Prolog Variable)').
'symbol'('tok270','tok','src_span'(97,17,97,20,4790,3),'Ident (Prolog Variable)').
'symbol'('rdy271','rdy','src_span'(97,22,97,25,4795,3),'Ident (Prolog Variable)').
'symbol'('m272','m','src_span'(97,27,97,28,4800,1),'Ident (Prolog Variable)').
'symbol'('j3','j','src_span'(97,43,97,44,4816,1),'Ident (Prolog Variable)').
'symbol'('p274','p','src_span'(97,45,97,46,4818,1),'Ident (Prolog Variable)').
'symbol'('Inference4','Inference4','src_span'(104,1,104,11,5128,10),'Ident (Groundrep.)').
'symbol'('i275','i','src_span'(104,25,104,26,5152,1),'Ident (Prolog Variable)').
'symbol'('p276','p','src_span'(104,27,104,28,5154,1),'Ident (Prolog Variable)').
'symbol'('Infer4','Infer4','src_span'(106,1,106,7,5243,6),'Funktion or Process').
'symbol'('i277','i','src_span'(106,8,106,9,5250,1),'Ident (Prolog Variable)').
'symbol'('p278','p','src_span'(106,11,106,12,5253,1),'Ident (Prolog Variable)').
'symbol'('sp279','sp','src_span'(106,14,106,16,5256,2),'Ident (Prolog Variable)').
'symbol'('best280','best','src_span'(106,18,106,22,5260,4),'Ident (Prolog Variable)').
'symbol'('tok281','tok','src_span'(106,24,106,27,5266,3),'Ident (Prolog Variable)').
'symbol'('rdy282','rdy','src_span'(106,29,106,32,5271,3),'Ident (Prolog Variable)').
'symbol'('m283','m','src_span'(106,34,106,35,5276,1),'Ident (Prolog Variable)').
'symbol'('b284','b','src_span'(107,15,107,16,5295,1),'Ident (Prolog Variable)').
'symbol'('PollReady4','PollReady4','src_span'(110,1,110,11,5418,10),'Funktion or Process').
'symbol'('i285','i','src_span'(110,12,110,13,5429,1),'Ident (Prolog Variable)').
'symbol'('p286','p','src_span'(110,15,110,16,5432,1),'Ident (Prolog Variable)').
'symbol'('sp287','sp','src_span'(110,18,110,20,5435,2),'Ident (Prolog Variable)').
'symbol'('best288','best','src_span'(110,22,110,26,5439,4),'Ident (Prolog Variable)').
'symbol'('tok289','tok','src_span'(110,28,110,31,5445,3),'Ident (Prolog Variable)').
'symbol'('rdy290','rdy','src_span'(110,33,110,36,5450,3),'Ident (Prolog Variable)').
'symbol'('m291','m','src_span'(110,38,110,39,5455,1),'Ident (Prolog Variable)').
'symbol'('Release4','Release4','src_span'(114,1,114,9,5581,8),'Funktion or Process').
'symbol'('i292','i','src_span'(114,10,114,11,5590,1),'Ident (Prolog Variable)').
'symbol'('p293','p','src_span'(114,13,114,14,5593,1),'Ident (Prolog Variable)').
'symbol'('sp294','sp','src_span'(114,16,114,18,5596,2),'Ident (Prolog Variable)').
'symbol'('best295','best','src_span'(114,20,114,24,5600,4),'Ident (Prolog Variable)').
'symbol'('tok296','tok','src_span'(114,26,114,29,5606,3),'Ident (Prolog Variable)').
'symbol'('rdy297','rdy','src_span'(114,31,114,34,5611,3),'Ident (Prolog Variable)').
'symbol'('m298','m','src_span'(114,36,114,37,5616,1),'Ident (Prolog Variable)').
'symbol'('s4','s','src_span'(115,9,115,10,5629,1),'Ident (Prolog Variable)').
'symbol'('Score4','Score4','src_span'(117,1,117,7,5704,6),'Funktion or Process').
'symbol'('i300','i','src_span'(117,8,117,9,5711,1),'Ident (Prolog Variable)').
'symbol'('p301','p','src_span'(117,11,117,12,5714,1),'Ident (Prolog Variable)').
'symbol'('sp302','sp','src_span'(117,14,117,16,5717,2),'Ident (Prolog Variable)').
'symbol'('best303','best','src_span'(117,18,117,22,5721,4),'Ident (Prolog Variable)').
'symbol'('tok304','tok','src_span'(117,24,117,27,5727,3),'Ident (Prolog Variable)').
'symbol'('rdy305','rdy','src_span'(117,29,117,32,5732,3),'Ident (Prolog Variable)').
'symbol'('m306','m','src_span'(117,34,117,35,5737,1),'Ident (Prolog Variable)').
'symbol'('End4','End4','src_span'(128,1,128,5,6302,4),'Funktion or Process').
'symbol'('i307','i','src_span'(128,6,128,7,6307,1),'Ident (Prolog Variable)').
'symbol'('sp308','sp','src_span'(128,9,128,11,6310,2),'Ident (Prolog Variable)').
'symbol'('best309','best','src_span'(128,13,128,17,6314,4),'Ident (Prolog Variable)').
'symbol'('tok310','tok','src_span'(128,19,128,22,6320,3),'Ident (Prolog Variable)').
'symbol'('rdy311','rdy','src_span'(128,24,128,27,6325,3),'Ident (Prolog Variable)').
'symbol'('m312','m','src_span'(128,29,128,30,6330,1),'Ident (Prolog Variable)').
'symbol'('Next4','Next4','src_span'(143,1,143,6,7044,5),'Funktion or Process').
'symbol'('sp313','sp','src_span'(143,7,143,9,7050,2),'Ident (Prolog Variable)').
'symbol'('best314','best','src_span'(143,11,143,15,7054,4),'Ident (Prolog Variable)').
'symbol'('tok315','tok','src_span'(143,17,143,20,7060,3),'Ident (Prolog Variable)').
'symbol'('rdy316','rdy','src_span'(143,22,143,25,7065,3),'Ident (Prolog Variable)').
'symbol'('m317','m','src_span'(143,27,143,28,7070,1),'Ident (Prolog Variable)').
'symbol'('j4','j','src_span'(143,43,143,44,7086,1),'Ident (Prolog Variable)').
'symbol'('p319','p','src_span'(143,45,143,46,7088,1),'Ident (Prolog Variable)').