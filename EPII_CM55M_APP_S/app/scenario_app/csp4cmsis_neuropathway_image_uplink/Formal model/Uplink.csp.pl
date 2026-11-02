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
'bindval'('W','int'(2),'src_span'(9,1,9,14,593,13)).
'bindval'('MAX_INDEX','int'(4),'src_span'(10,1,10,14,607,13)).
'bindval'('IDS','setExp'('rangeClosed'('int'(0),'int'(3))),'src_span'(11,1,11,19,621,18)).
'bindval'('NONE','int'(4),'src_span'(12,1,12,14,640,13)).
'bindval'('MAXM','int'(2),'src_span'(13,1,13,14,700,13)).
'agent'('sat'(_m),'ifte'('>'(_m,'val_of'('MAXM','src_span'(15,17,15,21,731,4))),'val_of'('MAXM','src_span'(15,27,15,31,741,4)),_m,'src_span'(15,10,15,21,724,11),'src_span'(15,22,15,26,735,18),'src_span'(15,32,15,36,745,11)),'src_span'(15,10,15,38,724,28)).
'dataTypeDef'('source_t',['constructor'('camera'),'constructor'('inference')]).
'dataTypeDef'('outcome_t',['constructor'('better'),'constructor'('worse'),'constructor'('failed')]).
'dataTypeDef'('report_t',['constructorC'('started','dotTupleType'(['source_t'])),'constructor'('stack'),'constructorC'('window','dotTupleType'(['setExp'('rangeClosed'('int'(0),'val_of'('MAXM','src_span'(19,60,19,64,947,4))))])),'constructorC'('image','dotTupleType'(['val_of'('IDS','src_span'(19,74,19,77,961,3))]))]).
'bindval'('TEXT','agent_call'('src_span'(21,8,21,12,973,4),'diff',['report_t','closure'(['image'])]),'src_span'(21,1,21,35,966,34)).
'channel'('g_trigger_chan','type'('dotUnitType')).
'channel'('frame_chan','type'('dotTupleType'(['setExp'('rangeClosed'('int'(0),'-'('val_of'('MAX_INDEX','src_span'(24,28,24,37,1111,9)),'int'(1)))),'val_of'('IDS','src_span'(24,41,24,44,1124,3))]))).
'channel'('release_chan','type'('dotTupleType'(['val_of'('IDS','src_span'(25,24,25,27,1202,3))]))).
'channel'('free_in','type'('dotTupleType'(['val_of'('IDS','src_span'(26,24,26,27,1306,3))]))).
'channel'('free_out','type'('dotTupleType'(['val_of'('IDS','src_span'(27,24,27,27,1385,3))]))).
'channel'('poll_empty','type'('dotUnitType')).
'channel'('report_chan','type'('dotTupleType'(['report_t']))).
'channel'('line','type'('dotTupleType'(['report_t']))).
'channel'('uplink','type'('dotTupleType'(['val_of'('IDS','src_span'(31,24,31,27,1749,3))]))).
'channel'('scored','type'('dotTupleType'(['outcome_t','val_of'('IDS','src_span'(32,34,32,37,1852,3))]))).
'channel'('merge','type'('dotUnitType')).
'channel'('camera_log','type'('dotUnitType')).
'channel'('stack_tick','type'('dotUnitType')).
'channel'('overflow','type'('dotUnitType')).
'channel'('error','type'('dotUnitType')).
'bindval'('ENV','prefix'('src_span'(37,7,37,21,2067,14),[],'g_trigger_chan','val_of'('ENV','src_span'(37,25,37,28,2085,3)),'src_span'(37,22,37,24,2081,21)),'src_span'(37,1,37,28,2061,27)).
'agent'('RUN'(_A),'repChoice'(['comprehensionGenerator'(_x,_A)],'prefix'('src_span'(39,21,39,22,2110,1),[],_x,'agent_call'('src_span'(39,26,39,29,2115,3),'RUN',[_A]),'src_span'(39,23,39,25,2111,11)),'src_span'(39,13,39,20,2102,7)),'src_span'(39,10,39,32,2099,22)).
'bindval'('Camera','prefix'('src_span'(42,10,42,20,2219,10),[],'camera_log','prefix'('src_span'(42,24,42,35,2233,11),['out'('dotTuple'(['started','camera']))],'report_chan','agent_call'('src_span'(42,54,42,64,2263,10),'CameraLoop',['int'(0),'int'(0)]),'src_span'(42,51,42,53,2259,35)),'src_span'(42,21,42,23,2229,60)),'src_span'(42,1,42,70,2210,69)).
'agent'('CameraLoop'(_i,_b),'prefix'('src_span'(43,20,43,34,2299,14),[],'g_trigger_chan','prefix'('src_span'(43,38,43,48,2317,10),['out'(_i),'out'(_b)],'frame_chan','prefix'('src_span'(43,56,43,68,2335,12),['in'(_nb)],'release_chan','agent_call'('src_span'(43,75,43,85,2354,10),'CameraLoop',['%'('+'(_i,'int'(1)),'val_of'('MAX_INDEX','src_span'(43,96,43,105,2375,9))),_nb]),'src_span'(43,72,43,74,2350,42)),'src_span'(43,53,43,55,2331,60)),'src_span'(43,35,43,37,2313,90)),'src_span'(43,20,43,110,2299,90)).
'bindval'('Inference','prefix'('src_span'(49,13,49,23,2718,10),['in'(_i2),'in'(_p)],'frame_chan','prefix'('src_span'(49,31,49,42,2736,11),['out'('dotTuple'(['started','inference']))],'report_chan','agent_call'('src_span'(49,64,49,69,2769,5),'Infer',[_i2,_p,'agent_call'('src_span'(49,76,49,80,2781,4),'diff',['val_of'('IDS','src_span'(49,81,49,84,2786,3)),'setExp'('rangeEnum'([_p]))]),'val_of'('NONE','src_span'(49,92,49,96,2797,4)),'true','int'(0)]),'src_span'(49,61,49,63,2765,64)),'src_span'(49,28,49,30,2732,81)),'src_span'(49,1,49,106,2706,105)).
'agent'('Infer'(_i3,_p2,_sp,_best,_tok,_m2),'[]'('prefix'('src_span'(52,6,52,14,2850,8),['in'(_b2)],'free_out','agent_call'('src_span'(52,20,52,27,2864,7),'Release',[_i3,_p2,'agent_call'('src_span'(52,34,52,39,2878,5),'union',[_sp,'setExp'('rangeEnum'([_b2]))]),_best,'true',_m2]),'src_span'(52,17,52,19,2860,50)),'prefix'('src_span'(53,9,53,19,2918,10),[],'poll_empty','agent_call'('src_span'(53,23,53,30,2932,7),'Release',[_i3,_p2,_sp,_best,_tok,_m2]),'src_span'(53,20,53,22,2928,45)),'src_span_operator'('no_loc_info_available','src_span'(53,5,53,7,2914,2))),'no_loc_info_available').
'agent'('Release'(_i4,_p3,_sp2,_best2,_tok2,_m3),'repInternalChoice'(['comprehensionGenerator'(_s,_sp2)],'prefix'('src_span'(55,48,55,60,3013,12),['out'(_s)],'release_chan','agent_call'('src_span'(55,66,55,71,3031,5),'Score',[_i4,_p3,'agent_call'('src_span'(55,78,55,82,3043,4),'diff',[_sp2,'setExp'('rangeEnum'([_s]))]),_best2,_tok2,_m3]),'src_span'(55,63,55,65,3027,46)),'src_span'(55,39,55,47,3004,8)),'src_span'(55,35,55,106,3000,71)).
'agent'('Score'(_i5,_p4,_sp3,_best3,_tok3,_m4),'ifte'('=='(_best3,'val_of'('NONE','src_span'(58,16,58,20,3120,4))),'|~|'('prefix'('src_span'(59,10,59,16,3139,6),['out'('failed'),'out'(_p4)],'scored','agent_call'('src_span'(59,29,59,32,3158,3),'End',[_i5,'agent_call'('src_span'(59,36,59,41,3165,5),'union',[_sp3,'setExp'('rangeEnum'([_p4]))]),_best3,_tok3,_m4]),'src_span'(59,26,59,28,3154,42)),'prefix'('src_span'(60,14,60,20,3209,6),['out'('better'),'out'(_p4)],'scored','agent_call'('src_span'(60,33,60,36,3228,3),'End',[_i5,_sp3,_p4,_tok3,_m4]),'src_span'(60,30,60,32,3224,27)),'src_span_operator'('no_loc_info_available','src_span'(60,9,60,12,3204,3))),'|~|'('|~|'('prefix'('src_span'(62,10,62,16,3269,6),['out'('failed'),'out'(_p4)],'scored','agent_call'('src_span'(62,29,62,32,3288,3),'End',[_i5,'agent_call'('src_span'(62,36,62,41,3295,5),'union',[_sp3,'setExp'('rangeEnum'([_p4]))]),_best3,_tok3,_m4]),'src_span'(62,26,62,28,3284,42)),'prefix'('src_span'(63,14,63,20,3339,6),['out'('better'),'out'(_p4)],'scored','agent_call'('src_span'(63,33,63,36,3358,3),'End',[_i5,'agent_call'('src_span'(63,40,63,45,3365,5),'union',[_sp3,'setExp'('rangeEnum'([_best3]))]),_p4,_tok3,_m4]),'src_span'(63,30,63,32,3354,42)),'src_span_operator'('no_loc_info_available','src_span'(63,9,63,12,3334,3))),'prefix'('src_span'(64,14,64,20,3409,6),['out'('worse'),'out'(_p4)],'scored','agent_call'('src_span'(64,32,64,35,3427,3),'End',[_i5,'agent_call'('src_span'(64,39,64,44,3434,5),'union',[_sp3,'setExp'('rangeEnum'([_p4]))]),_best3,_tok3,_m4]),'src_span'(64,29,64,31,3423,42)),'src_span_operator'('no_loc_info_available','src_span'(64,9,64,12,3404,3))),'no_loc_info_available','no_loc_info_available','no_loc_info_available'),'src_span'(58,5,64,69,3109,355)).
'agent'('End'(_i6,_sp4,_best4,_tok4,_m5),'ifte'('=='('%'(_i6,'val_of'('W','src_span'(67,12,67,13,3504,1))),'-'('val_of'('W','src_span'(67,17,67,18,3509,1)),'int'(1))),'ifte'(_tok4,'prefix'('src_span'(69,13,69,24,3552,11),['out'('dotTuple'(['window',_m5]))],'report_chan','ifte'('!='(_best4,'val_of'('NONE','src_span'(70,29,70,33,3604,4))),'prefix'('src_span'(70,39,70,50,3614,11),['out'('dotTuple'(['image',_best4]))],'report_chan','agent_call'('src_span'(70,65,70,69,3640,4),'Next',[_sp4,'val_of'('NONE','src_span'(70,74,70,78,3649,4)),'false','int'(0)]),'src_span'(70,62,70,64,3636,39)),'agent_call'('src_span'(71,23,71,27,3687,4),'Next',[_sp4,'val_of'('NONE','src_span'(71,32,71,36,3696,4)),'true','int'(0)]),'no_loc_info_available','no_loc_info_available','src_span'(70,90,71,22,3664,96)),'src_span'(69,34,70,16,3572,148)),'prefix'('src_span'(73,13,73,18,3737,5),[],'merge','agent_call'('src_span'(73,22,73,26,3746,4),'Next',[_sp4,_best4,'false','agent_call'('src_span'(73,44,73,47,3768,3),'sat',['+'(_m5,'int'(1))])]),'src_span'(73,19,73,21,3742,42)),'src_span'(68,9,68,15,3528,6),'src_span'(68,16,69,12,3534,180),'src_span'(71,48,73,12,3711,227)),'agent_call'('src_span'(75,9,75,13,3797,4),'Next',[_sp4,_best4,_tok4,_m5]),'no_loc_info_available','no_loc_info_available','src_span'(73,56,75,8,3779,291)),'src_span'(67,5,75,31,3497,322)).
'agent'('Next'(_sp5,_best5,_tok5,_m6),'prefix'('src_span'(77,26,77,36,3846,10),['in'(_j),'in'(_p5)],'frame_chan','agent_call'('src_span'(77,44,77,49,3864,5),'Infer',[_j,_p5,_sp5,_best5,_tok5,_m6]),'src_span'(77,41,77,43,3860,35)),'src_span'(77,26,77,73,3846,47)).
'bindval'('FREE','[]'('prefix'('src_span'(82,9,82,16,4133,7),['in'(_b3)],'free_in','agent_call'('src_span'(82,22,82,31,4146,9),'FREE_FULL',[_b3]),'src_span'(82,19,82,21,4142,18)),'prefix'('src_span'(82,40,82,50,4164,10),[],'poll_empty','val_of'('FREE','src_span'(82,54,82,58,4178,4)),'src_span'(82,51,82,53,4174,18)),'src_span_operator'('no_loc_info_available','src_span'(82,36,82,38,4160,2))),'src_span'(82,1,82,59,4125,58)).
'agent'('FREE_FULL'(_b4),'[]'('prefix'('src_span'(83,17,83,25,4200,8),['out'(_b4)],'free_out','val_of'('FREE','src_span'(83,31,83,35,4214,4)),'src_span'(83,28,83,30,4210,10)),'prefix'('src_span'(83,41,83,48,4224,7),['in'(_x2)],'free_in','prefix'('src_span'(83,54,83,62,4237,8),[],'overflow','stop'('src_span'(83,66,83,70,4249,4)),'src_span'(83,63,83,65,4245,16)),'src_span'(83,51,83,53,4233,22)),'src_span_operator'('no_loc_info_available','src_span'(83,37,83,39,4220,2))),'no_loc_info_available').
'bindval'('MainApp','prefix'('src_span'(86,11,86,21,4336,10),[],'stack_tick','prefix'('src_span'(86,25,86,36,4350,11),['out'('stack')],'report_chan','val_of'('MainApp','src_span'(86,46,86,53,4371,7)),'src_span'(86,43,86,45,4367,17)),'src_span'(86,22,86,24,4346,42)),'src_span'(86,1,86,53,4326,52)).
'bindval'('Reporter','[]'('prefix'('src_span'(89,13,89,24,4485,11),['inGuard'(_r,'val_of'('TEXT','src_span'(89,27,89,31,4499,4)))],'report_chan','prefix'('src_span'(89,35,89,39,4507,4),['out'(_r)],'line','val_of'('Reporter','src_span'(89,45,89,53,4517,8)),'src_span'(89,42,89,44,4513,14)),'src_span'(89,32,89,34,4503,29)),'prefix'('src_span'(90,16,90,33,4542,17),['in'(_b5)],'dotTuple'(['report_chan','image']),'prefix'('src_span'(90,39,90,45,4565,6),['out'(_b5)],'uplink','prefix'('src_span'(90,51,90,58,4577,7),['out'(_b5)],'free_in','val_of'('Reporter','src_span'(90,64,90,72,4590,8)),'src_span'(90,61,90,63,4586,14)),'src_span'(90,48,90,50,4573,27)),'src_span'(90,36,90,38,4561,39)),'src_span_operator'('no_loc_info_available','src_span'(90,12,90,14,4538,2))),'src_span'(89,1,90,73,4473,126)).
'agent'('WRITERS'(_Rep),'|||'('sharing'('closure'(['frame_chan','release_chan']),'val_of'('Camera','src_span'(92,18,92,24,4618,6)),'val_of'('Inference','src_span'(92,62,92,71,4662,9)),'src_span'(92,25,92,61,4625,36)),'val_of'('MainApp','src_span'(92,77,92,84,4677,7)),'src_span_operator'('no_loc_info_available','src_span'(92,73,92,76,4673,3))),'src_span'(92,16,92,85,4616,69)).
'agent'('NETWORK'(_Rep2),'sharing'('closure'(['free_in','free_out','poll_empty']),'sharing'('closure'(['report_chan']),'agent_call'('src_span'(93,17,93,24,4702,7),'WRITERS',[_Rep2]),_Rep2,'src_span'(93,30,93,53,4715,23)),'val_of'('FREE','src_span'(93,101,93,105,4786,4)),'src_span'(93,59,93,100,4744,41)),'src_span'(93,59,93,100,4744,41)).
'bindval'('SYSTEM','sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(94,16,94,19,4806,3)),'agent_call'('src_span'(94,47,94,54,4837,7),'NETWORK',['val_of'('Reporter','src_span'(94,55,94,63,4845,8))]),'src_span'(94,20,94,46,4810,26)),'src_span'(94,1,94,64,4791,63)).
'assertModelCheckExt'('False','val_of'('SYSTEM','src_span'(96,8,96,14,4863,6)),'DeadlockFree','F').
'assertModelCheck'('False','val_of'('SYSTEM','src_span'(97,8,97,14,4898,6)),'LivelockFree').
'agent'('OBS'(_cam,_pend,_best6,_sp6,_send,_slot),'[]'('[]'('[]'('[]'('[]'('prefix'('src_span'(105,6,105,16,5446,10),['in'(_i7),'in'(_b6)],'frame_chan','ifte'('=='(_b6,_cam),'agent_call'('src_span'(105,42,105,45,5482,3),'OBS',['val_of'('NONE','src_span'(105,46,105,50,5486,4)),_b6,_best6,_sp6,_send,_slot]),'prefix'('src_span'(105,82,105,87,5522,5),[],'error','stop'('src_span'(105,91,105,95,5531,4)),'src_span'(105,88,105,90,5527,13)),'no_loc_info_available','no_loc_info_available','src_span'(105,77,105,81,5516,53)),'src_span'(105,21,105,23,5460,78)),'prefix'('src_span'(106,6,106,18,5543,12),['in'(_b7)],'release_chan','ifte'('bool_and'('bool_and'('=='(_cam,'val_of'('NONE','src_span'(106,35,106,39,5572,4))),'!='(_pend,'val_of'('NONE','src_span'(106,52,106,56,5589,4)))),'agent_call'('src_span'(106,61,106,67,5598,6),'member',[_b7,_sp6])),'agent_call'('src_span'(107,30,107,33,5641,3),'OBS',[_b7,_pend,_best6,'agent_call'('src_span'(107,49,107,53,5660,4),'diff',[_sp6,'setExp'('rangeEnum'([_b7]))]),_send,_slot]),'prefix'('src_span'(107,81,107,86,5692,5),[],'error','stop'('src_span'(107,90,107,94,5701,4)),'src_span'(107,87,107,89,5697,13)),'no_loc_info_available','no_loc_info_available','src_span'(107,76,107,80,5686,64)),'src_span'(106,21,106,23,5557,151)),'src_span_operator'('no_loc_info_available','src_span'(106,2,106,4,5539,2))),'prefix'('src_span'(108,6,108,12,5713,6),['in'(_o),'in'(_b8)],'scored','ifte'('!='(_b8,_pend),'prefix'('src_span'(108,39,108,44,5746,5),[],'error','stop'('src_span'(108,48,108,52,5755,4)),'src_span'(108,45,108,47,5751,13)),'ifte'('=='(_o,'better'),'agent_call'('src_span'(110,26,110,29,5825,3),'OBS',[_cam,'val_of'('NONE','src_span'(110,35,110,39,5834,4)),_b8,'ifte'('=='(_best6,'val_of'('NONE','src_span'(110,55,110,59,5854,4))),_sp6,'agent_call'('src_span'(110,73,110,78,5872,5),'union',[_sp6,'setExp'('rangeEnum'([_best6]))]),'no_loc_info_available','no_loc_info_available','src_span'(110,68,110,72,5866,25)),_send,_slot]),'agent_call'('src_span'(111,26,111,29,5928,3),'OBS',[_cam,'val_of'('NONE','src_span'(111,35,111,39,5937,4)),_best6,'agent_call'('src_span'(111,47,111,52,5949,5),'union',[_sp6,'setExp'('rangeEnum'([_b8]))]),_send,_slot]),'no_loc_info_available','no_loc_info_available','src_span'(110,104,111,25,5902,151)),'no_loc_info_available','no_loc_info_available','src_span'(108,53,109,25,5759,230)),'src_span'(108,17,108,19,5723,256)),'src_span_operator'('no_loc_info_available','src_span'(108,2,108,4,5709,2))),'prefix'('src_span'(112,6,112,23,5984,17),['in'(_b9)],'dotTuple'(['report_chan','image']),'ifte'('bool_and'('bool_and'('=='(_b9,_best6),'=='(_send,'val_of'('NONE','src_span'(112,55,112,59,6033,4)))),'=='(_slot,'val_of'('NONE','src_span'(112,72,112,76,6050,4)))),'agent_call'('src_span'(113,35,113,38,6089,3),'OBS',[_cam,_pend,'val_of'('NONE','src_span'(113,50,113,54,6104,4)),_sp6,_b9,_slot]),'prefix'('src_span'(113,74,113,79,6128,5),[],'error','stop'('src_span'(113,83,113,87,6137,4)),'src_span'(113,80,113,82,6133,13)),'no_loc_info_available','no_loc_info_available','src_span'(113,69,113,73,6122,52)),'src_span'(112,26,112,28,6003,141)),'src_span_operator'('no_loc_info_available','src_span'(112,2,112,4,5980,2))),'prefix'('src_span'(114,6,114,13,6149,7),['in'(_b132)],'free_in','ifte'('=='(_b132,_send),'agent_call'('src_span'(114,38,114,41,6181,3),'OBS',[_cam,_pend,_best6,_sp6,'val_of'('NONE','src_span'(114,63,114,67,6206,4)),_b132]),'prefix'('src_span'(114,77,114,82,6220,5),[],'error','stop'('src_span'(114,86,114,90,6229,4)),'src_span'(114,83,114,85,6225,13)),'no_loc_info_available','no_loc_info_available','src_span'(114,72,114,76,6214,52)),'src_span'(114,16,114,18,6158,78)),'src_span_operator'('no_loc_info_available','src_span'(114,2,114,4,6145,2))),'prefix'('src_span'(115,6,115,14,6241,8),['in'(_b133)],'free_out','ifte'('=='(_b133,_slot),'agent_call'('src_span'(115,39,115,42,6274,3),'OBS',[_cam,_pend,_best6,'agent_call'('src_span'(115,60,115,65,6295,5),'union',[_sp6,'setExp'('rangeEnum'([_b133]))]),_send,'val_of'('NONE','src_span'(115,82,115,86,6317,4))]),'prefix'('src_span'(115,93,115,98,6328,5),[],'error','stop'('src_span'(115,102,115,106,6337,4)),'src_span'(115,99,115,101,6333,13)),'no_loc_info_available','no_loc_info_available','src_span'(115,88,115,92,6322,67)),'src_span'(115,17,115,19,6251,93)),'src_span_operator'('no_loc_info_available','src_span'(115,2,115,4,6237,2))),'no_loc_info_available').
'bindval'('ROLE_EVENTS','closure'(['frame_chan','release_chan','scored','dotTuple'(['report_chan','image']),'free_in','free_out']),'src_span'(117,1,117,91,6345,90)).
'bindval'('SYSTEM_OBS','sharing'('val_of'('ROLE_EVENTS','src_span'(118,25,118,36,6460,11)),'val_of'('SYSTEM','src_span'(118,15,118,21,6450,6)),'agent_call'('src_span'(118,40,118,43,6475,3),'OBS',['int'(0),'val_of'('NONE','src_span'(118,47,118,51,6482,4)),'val_of'('NONE','src_span'(118,53,118,57,6488,4)),'setExp'('rangeEnum'(['int'(1),'int'(2),'int'(3)])),'val_of'('NONE','src_span'(118,70,118,74,6505,4)),'val_of'('NONE','src_span'(118,76,118,80,6511,4))]),'src_span'(118,22,118,39,6457,17)),'src_span'(118,1,118,81,6436,80)).
'assertRef'('False','agent_call'('src_span'(120,8,120,11,6525,3),'RUN',['agent_call'('src_span'(120,12,120,16,6529,4),'diff',['Events','setExp'('rangeEnum'(['error','overflow']))])]),'Trace','val_of'('SYSTEM_OBS','src_span'(120,49,120,59,6566,10)),'src_span'(120,1,120,59,6518,58)).
'agent'('MCOUNT'(_k),'[]'('prefix'('src_span'(124,14,124,19,6778,5),[],'merge','agent_call'('src_span'(124,23,124,29,6787,6),'MCOUNT',['agent_call'('src_span'(124,30,124,33,6794,3),'sat',['+'(_k,'int'(1))])]),'src_span'(124,20,124,22,6783,27)),'prefix'('src_span'(124,47,124,65,6811,18),['out'(_k)],'dotTuple'(['report_chan','window']),'agent_call'('src_span'(124,71,124,77,6835,6),'MCOUNT',['int'(0)]),'src_span'(124,68,124,70,6831,15)),'src_span_operator'('no_loc_info_available','src_span'(124,43,124,45,6807,2))),'no_loc_info_available').
'assertRef'('False','agent_call'('src_span'(126,8,126,14,6854,6),'MCOUNT',['int'(0)]),'Trace','\x5c\'('val_of'('SYSTEM','src_span'(126,22,126,28,6868,6)),'agent_call'('src_span'(126,31,126,35,6877,4),'diff',['Events','closure'(['merge','dotTuple'(['report_chan','window'])])]),'src_span_operator'('no_loc_info_available','src_span'(126,29,126,30,6875,1))),'src_span'(126,1,126,76,6847,75)).
'bindval'('ReporterStall','[]'('prefix'('src_span'(133,18,133,29,7414,11),['inGuard'(_r2,'val_of'('TEXT','src_span'(133,32,133,36,7428,4)))],'report_chan','prefix'('src_span'(133,40,133,44,7436,4),['out'(_r2)],'line','val_of'('ReporterStall','src_span'(133,50,133,63,7446,13)),'src_span'(133,47,133,49,7442,19)),'src_span'(133,37,133,39,7432,34)),'prefix'('src_span'(134,21,134,38,7481,17),['in'(_b136)],'dotTuple'(['report_chan','image']),'prefix'('src_span'(134,44,134,50,7504,6),['out'(_b136)],'uplink','|~|'('prefix'('src_span'(134,58,134,65,7518,7),['out'(_b136)],'free_in','val_of'('ReporterStall','src_span'(134,71,134,84,7531,13)),'src_span'(134,68,134,70,7527,19)),'stop'('src_span'(134,90,134,94,7550,4)),'src_span_operator'('no_loc_info_available','src_span'(134,86,134,89,7546,3))),'src_span'(134,53,134,55,7512,45)),'src_span'(134,41,134,43,7500,57)),'src_span_operator'('no_loc_info_available','src_span'(134,17,134,19,7477,2))),'src_span'(133,1,134,96,7397,159)).
'bindval'('SYSTEM_STALL','sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(135,17,135,20,7573,3)),'agent_call'('src_span'(135,48,135,55,7604,7),'NETWORK',['val_of'('ReporterStall','src_span'(135,56,135,69,7612,13))]),'src_span'(135,21,135,47,7577,26)),'src_span'(135,1,135,70,7557,69)).
'bindval'('CYCLE','prefix'('src_span'(137,9,137,23,7636,14),[],'g_trigger_chan','val_of'('CYCLE','src_span'(137,27,137,32,7654,5)),'src_span'(137,24,137,26,7650,23)),'src_span'(137,1,137,32,7628,31)).
'assertModelCheckExt'('False','val_of'('SYSTEM_STALL','src_span'(139,8,139,20,7668,12)),'DeadlockFree','F').
'assertRef'('False','val_of'('CYCLE','src_span'(140,8,140,13,7709,5)),'Failure','\x5c\'('val_of'('SYSTEM_STALL','src_span'(140,18,140,30,7719,12)),'agent_call'('src_span'(140,33,140,37,7734,4),'diff',['Events','setExp'('rangeEnum'(['g_trigger_chan']))]),'src_span_operator'('no_loc_info_available','src_span'(140,31,140,32,7732,1))),'src_span'(140,1,140,63,7702,62)).
'bindval'('ReporterStop','[]'('prefix'('src_span'(144,17,144,28,7949,11),['inGuard'(_r3,'val_of'('TEXT','src_span'(144,31,144,35,7963,4)))],'report_chan','prefix'('src_span'(144,39,144,43,7971,4),['out'(_r3)],'line','val_of'('ReporterStop','src_span'(144,49,144,61,7981,12)),'src_span'(144,46,144,48,7977,18)),'src_span'(144,36,144,38,7967,33)),'prefix'('src_span'(145,20,145,37,8014,17),['in'(_b138)],'dotTuple'(['report_chan','image']),'prefix'('src_span'(145,43,145,49,8037,6),['out'(_b138)],'uplink','stop'('src_span'(145,55,145,59,8049,4)),'src_span'(145,52,145,54,8045,10)),'src_span'(145,40,145,42,8033,22)),'src_span_operator'('no_loc_info_available','src_span'(145,16,145,18,8010,2))),'src_span'(144,1,145,60,7933,121)).
'bindval'('NETWORK_STOP','sharing'('closure'(['free_in','free_out','poll_empty']),'sharing'('closure'(['report_chan']),'sharing'('closure'(['frame_chan','release_chan']),'val_of'('Camera','src_span'(146,18,146,24,8072,6)),'val_of'('Inference','src_span'(146,62,146,71,8116,9)),'src_span'(146,25,146,61,8079,36)),'val_of'('ReporterStop','src_span'(146,97,146,109,8151,12)),'src_span'(146,73,146,96,8127,23)),'val_of'('FREE','src_span'(147,58,147,62,8222,4)),'src_span'(147,16,147,57,8180,41)),'src_span'(146,1,147,62,8055,171)).
'bindval'('SYSTEM_STOP','sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(148,16,148,19,8242,3)),'val_of'('NETWORK_STOP','src_span'(148,47,148,59,8273,12)),'src_span'(148,20,148,46,8246,26)),'src_span'(148,1,148,59,8227,58)).
'bindval'('STALL_VIEW','closure'(['dotTuple'(['report_chan','window']),'dotTuple'(['report_chan','image']),'uplink','merge']),'src_span'(150,1,150,72,8287,71)).
'bindval'('PRE','repInternalChoice'(['comprehensionGenerator'(_k2,'setExp'('rangeClosed'('int'(0),'val_of'('MAXM','src_span'(151,26,151,30,8384,4)))))],'prefix'('src_span'(151,34,151,52,8392,18),['out'(_k2)],'dotTuple'(['report_chan','window']),'|~|'('val_of'('PRE','src_span'(152,19,152,22,8434,3)),'repInternalChoice'(['comprehensionGenerator'(_b140,'val_of'('IDS','src_span'(152,36,152,39,8451,3)))],'prefix'('src_span'(152,42,152,59,8457,17),['out'(_b140)],'dotTuple'(['report_chan','image']),'|||'('prefix'('src_span'(152,67,152,73,8482,6),['out'(_b140)],'uplink','stop'('src_span'(152,79,152,83,8494,4)),'src_span'(152,76,152,78,8490,10)),'val_of'('MERGING','src_span'(152,89,152,96,8504,7)),'src_span_operator'('no_loc_info_available','src_span'(152,85,152,88,8500,3))),'src_span'(152,62,152,64,8476,38)),'src_span'(152,32,152,41,8447,9)),'src_span_operator'('no_loc_info_available','src_span'(152,23,152,26,8438,3))),'src_span'(151,55,152,17,8412,104)),'src_span'(151,18,151,33,8376,15)),'src_span'(151,1,152,99,8359,155)).
'bindval'('MERGING','prefix'('src_span'(153,14,153,19,8528,5),[],'merge','val_of'('MERGING','src_span'(153,23,153,30,8537,7)),'src_span'(153,20,153,22,8533,16)),'src_span'(153,1,153,30,8515,29)).
'assertRef'('False','val_of'('PRE','src_span'(155,8,155,11,8553,3)),'FailureDivergence','\x5c\'('val_of'('SYSTEM_STOP','src_span'(155,17,155,28,8562,11)),'agent_call'('src_span'(155,31,155,35,8576,4),'diff',['Events','val_of'('STALL_VIEW','src_span'(155,44,155,54,8589,10))]),'src_span_operator'('no_loc_info_available','src_span'(155,29,155,30,8574,1))),'src_span'(155,1,155,55,8546,54)).
'comment'('lineComment'('-- Uplink (csp4cmsis_neuropathway_image_uplink, Stage 3): Camera -> Inference -> Reporter, plus'),'src_position'(1,1,0,95)).
'comment'('lineComment'('-- MainApp, with the four JPEG buffers as tokens. Buffer ids travel with the frames'),'src_position'(2,1,96,83)).
'comment'('lineComment'('-- (frame_chan), back to Camera as the next DMA target (release_chan), to the Reporter with the'),'src_position'(3,1,180,95)).
'comment'('lineComment'('-- Image report (report_chan) and back to Inference when the send is done (free_chan, one slot).'),'src_position'(4,1,276,96)).
'comment'('lineComment'('-- Inference writes to report_chan only while it holds the free token.'),'src_position'(5,1,373,70)).
'comment'('lineComment'('-- Bounded for exhaustive checking: windows of W = 2 frames (20 on the board), frame indices'),'src_position'(6,1,444,92)).
'comment'('lineComment'('-- 0..3 wrapping, the merged count saturating at MAXM.'),'src_position'(7,1,537,54)).
'comment'('lineComment'('-- no buffer'),'src_position'(12,48,687,12)).
'comment'('lineComment'('-- the frame\x27\s score against the window\x27\s best'),'src_position'(18,48,841,46)).
'comment'('lineComment'('-- frame-ready interrupt -> Camera'),'src_position'(23,48,1049,34)).
'comment'('lineComment'('-- Camera -> Inference: frame index, its buffer'),'src_position'(24,48,1131,47)).
'comment'('lineComment'('-- Inference -> Camera: raw buffer free, next DMA target'),'src_position'(25,48,1226,56)).
'comment'('lineComment'('-- Reporter -> free_chan\x27\s slot'),'src_position'(26,48,1330,31)).
'comment'('lineComment'('-- free_chan\x27\s slot -> Inference (poll, value ready)'),'src_position'(27,48,1409,52)).
'comment'('lineComment'('-- free_chan\x27\s slot -> Inference (poll, SKIP taken)'),'src_position'(28,48,1509,51)).
'comment'('lineComment'('-- Camera, Inference, MainApp -> Reporter'),'src_position'(29,48,1608,41)).
'comment'('lineComment'('-- the Reporter\x27\s text lines'),'src_position'(30,48,1697,28)).
'comment'('lineComment'('-- the Reporter sends the JPEG in this buffer'),'src_position'(31,48,1773,45)).
'comment'('lineComment'('-- Inference has scored the frame in this buffer'),'src_position'(32,48,1866,48)).
'comment'('lineComment'('-- Inference merges a window (uplink busy)'),'src_position'(33,48,1962,42)).
'comment'('lineComment'('-- Camera: the next DMA target is buffer 0 at start, then whatever Inference releases.'),'src_position'(41,1,2123,86)).
'comment'('lineComment'('-- Inference: sp = spare buffers, best = the window\x27\s best (NONE if none yet), tok = holds the'),'src_position'(45,1,2391,94)).
'comment'('lineComment'('-- free token, m = windows merged since the last Window line. Per frame: poll free_chan, rescale'),'src_position'(46,1,2486,96)).
'comment'('lineComment'('-- and release a spare as the next DMA target, score, and on a window\x27\s last frame either report'),'src_position'(47,1,2583,96)).
'comment'('lineComment'('-- (token held) or merge.'),'src_position'(48,1,2680,25)).
'comment'('lineComment'('-- free_chan: a one-slot buffered channel. Inference\x27\s PRI ALT with SKIP sees either the value'),'src_position'(79,1,3895,94)).
'comment'('lineComment'('-- (free_out) or an empty slot (poll_empty), never both. A second write to a full slot would'),'src_position'(80,1,3990,92)).
'comment'('lineComment'('-- block the Reporter; overflow marks it.'),'src_position'(81,1,4083,41)).
'comment'('lineComment'('-- MainApp: one stack report per timer tick, over its own writer end.'),'src_position'(85,1,4256,69)).
'comment'('lineComment'('-- Reporter: a text line per text report; for an Image, send the JPEG and return the buffer.'),'src_position'(88,1,4380,92)).
'comment'('lineComment'('-- Buffer roles: an observer that follows each id through the events, from the role it must be'),'src_position'(99,1,4925,94)).
'comment'('lineComment'('-- in to the next one: next (Camera\x27\s DMA target), pending (being scored), best, sending (from the'),'src_position'(100,1,5020,98)).
'comment'('lineComment'('-- Image report until Inference has read it back; slot = in free_chan), and spare. It starts with'),'src_position'(101,1,5119,97)).
'comment'('lineComment'('-- 0 as next and 1..3 spare and moves exactly one id per event, so as long as no event finds an id'),'src_position'(102,1,5217,98)).
'comment'('lineComment'('-- in the wrong role (error), the four ids are always a permutation across the roles.'),'src_position'(103,1,5316,85)).
'comment'('lineComment'('-- The merged count: every Window line carries the number of windows merged since the previous'),'src_position'(122,1,6578,94)).
'comment'('lineComment'('-- line (saturating at MAXM). Nothing forces the Reporter to finish soon, so merges happen.'),'src_position'(123,1,6673,91)).
'comment'('lineComment'('-- Uplink stalled: after any image the Reporter may stop for ever, without returning the buffer'),'src_position'(128,1,6924,95)).
'comment'('lineComment'('-- and without reading report_chan again (MainApp\x27\s stack report then blocks too). Camera and'),'src_position'(129,1,7020,93)).
'comment'('lineComment'('-- Inference must keep cycling: the frame-ready trigger is never refused. Camera takes a trigger'),'src_position'(130,1,7114,96)).
'comment'('lineComment'('-- only after it has passed the previous frame on and Inference has released a buffer, and'),'src_position'(131,1,7211,90)).
'comment'('lineComment'('-- Inference releases only between frames it has finished, including any write to report_chan.'),'src_position'(132,1,7302,94)).
'comment'('lineComment'('-- Uplink stalled after the first image, MainApp left out (it only blocks): from then on only'),'src_position'(142,1,7766,93)).
'comment'('lineComment'('-- the merges go on, one per window, for ever; no Window line, no Image.'),'src_position'(143,1,7860,72)).
'symbol'('W','W','src_span'(9,1,9,2,593,1),'Ident (Groundrep.)').
'symbol'('MAX_INDEX','MAX_INDEX','src_span'(10,1,10,10,607,9),'Ident (Groundrep.)').
'symbol'('IDS','IDS','src_span'(11,1,11,4,621,3),'Ident (Groundrep.)').
'symbol'('NONE','NONE','src_span'(12,1,12,5,640,4),'Ident (Groundrep.)').
'symbol'('MAXM','MAXM','src_span'(13,1,13,5,700,4),'Ident (Groundrep.)').
'symbol'('sat','sat','src_span'(15,1,15,4,715,3),'Funktion or Process').
'symbol'('m','m','src_span'(15,5,15,6,719,1),'Ident (Prolog Variable)').
'symbol'('source_t','source_t','src_span'(17,10,17,18,763,8),'Datatype').
'symbol'('camera','camera','src_span'(17,22,17,28,775,6),'Constructor of Datatype').
'symbol'('inference','inference','src_span'(17,31,17,40,784,9),'Constructor of Datatype').
'symbol'('outcome_t','outcome_t','src_span'(18,10,18,19,803,9),'Datatype').
'symbol'('better','better','src_span'(18,22,18,28,815,6),'Constructor of Datatype').
'symbol'('worse','worse','src_span'(18,31,18,36,824,5),'Constructor of Datatype').
'symbol'('failed','failed','src_span'(18,39,18,45,832,6),'Constructor of Datatype').
'symbol'('report_t','report_t','src_span'(19,10,19,18,897,8),'Datatype').
'symbol'('started','started','src_span'(19,22,19,29,909,7),'Constructor of Datatype').
'symbol'('stack','stack','src_span'(19,41,19,46,928,5),'Constructor of Datatype').
'symbol'('window','window','src_span'(19,49,19,55,936,6),'Constructor of Datatype').
'symbol'('image','image','src_span'(19,68,19,73,955,5),'Constructor of Datatype').
'symbol'('TEXT','TEXT','src_span'(21,1,21,5,966,4),'Ident (Groundrep.)').
'symbol'('diff','diff','src_span'(21,8,21,12,973,4),'BuiltIn primitive').
'symbol'('g_trigger_chan','g_trigger_chan','src_span'(23,9,23,23,1010,14),'Channel').
'symbol'('frame_chan','frame_chan','src_span'(24,9,24,19,1092,10),'Channel').
'symbol'('release_chan','release_chan','src_span'(25,9,25,21,1187,12),'Channel').
'symbol'('free_in','free_in','src_span'(26,9,26,16,1291,7),'Channel').
'symbol'('free_out','free_out','src_span'(27,9,27,17,1370,8),'Channel').
'symbol'('poll_empty','poll_empty','src_span'(28,9,28,19,1470,10),'Channel').
'symbol'('report_chan','report_chan','src_span'(29,9,29,20,1569,11),'Channel').
'symbol'('line','line','src_span'(30,9,30,13,1658,4),'Channel').
'symbol'('uplink','uplink','src_span'(31,9,31,15,1734,6),'Channel').
'symbol'('scored','scored','src_span'(32,9,32,15,1827,6),'Channel').
'symbol'('merge','merge','src_span'(33,9,33,14,1923,5),'Channel').
'symbol'('camera_log','camera_log','src_span'(34,9,34,19,2013,10),'Channel').
'symbol'('stack_tick','stack_tick','src_span'(34,21,34,31,2025,10),'Channel').
'symbol'('overflow','overflow','src_span'(35,9,35,17,2044,8),'Channel').
'symbol'('error','error','src_span'(35,19,35,24,2054,5),'Channel').
'symbol'('ENV','ENV','src_span'(37,1,37,4,2061,3),'Ident (Groundrep.)').
'symbol'('RUN','RUN','src_span'(39,1,39,4,2090,3),'Funktion or Process').
'symbol'('A','A','src_span'(39,5,39,6,2094,1),'Ident (Prolog Variable)').
'symbol'('x','x','src_span'(39,13,39,14,2102,1),'Ident (Prolog Variable)').
'symbol'('Camera','Camera','src_span'(42,1,42,7,2210,6),'Ident (Groundrep.)').
'symbol'('CameraLoop','CameraLoop','src_span'(43,1,43,11,2280,10),'Funktion or Process').
'symbol'('i','i','src_span'(43,12,43,13,2291,1),'Ident (Prolog Variable)').
'symbol'('b','b','src_span'(43,15,43,16,2294,1),'Ident (Prolog Variable)').
'symbol'('nb','nb','src_span'(43,69,43,71,2348,2),'Ident (Prolog Variable)').
'symbol'('Inference','Inference','src_span'(49,1,49,10,2706,9),'Ident (Groundrep.)').
'symbol'('i2','i','src_span'(49,24,49,25,2729,1),'Ident (Prolog Variable)').
'symbol'('p','p','src_span'(49,26,49,27,2731,1),'Ident (Prolog Variable)').
'symbol'('Infer','Infer','src_span'(51,1,51,6,2813,5),'Funktion or Process').
'symbol'('i3','i','src_span'(51,7,51,8,2819,1),'Ident (Prolog Variable)').
'symbol'('p2','p','src_span'(51,10,51,11,2822,1),'Ident (Prolog Variable)').
'symbol'('sp','sp','src_span'(51,13,51,15,2825,2),'Ident (Prolog Variable)').
'symbol'('best','best','src_span'(51,17,51,21,2829,4),'Ident (Prolog Variable)').
'symbol'('tok','tok','src_span'(51,23,51,26,2835,3),'Ident (Prolog Variable)').
'symbol'('m2','m','src_span'(51,28,51,29,2840,1),'Ident (Prolog Variable)').
'symbol'('b2','b','src_span'(52,15,52,16,2859,1),'Ident (Prolog Variable)').
'symbol'('union','union','src_span'(52,34,52,39,2878,5),'BuiltIn primitive').
'symbol'('Release','Release','src_span'(55,1,55,8,2966,7),'Funktion or Process').
'symbol'('i4','i','src_span'(55,9,55,10,2974,1),'Ident (Prolog Variable)').
'symbol'('p3','p','src_span'(55,12,55,13,2977,1),'Ident (Prolog Variable)').
'symbol'('sp2','sp','src_span'(55,15,55,17,2980,2),'Ident (Prolog Variable)').
'symbol'('best2','best','src_span'(55,19,55,23,2984,4),'Ident (Prolog Variable)').
'symbol'('tok2','tok','src_span'(55,25,55,28,2990,3),'Ident (Prolog Variable)').
'symbol'('m3','m','src_span'(55,30,55,31,2995,1),'Ident (Prolog Variable)').
'symbol'('s','s','src_span'(55,39,55,40,3004,1),'Ident (Prolog Variable)').
'symbol'('Score','Score','src_span'(57,1,57,6,3073,5),'Funktion or Process').
'symbol'('i5','i','src_span'(57,7,57,8,3079,1),'Ident (Prolog Variable)').
'symbol'('p4','p','src_span'(57,10,57,11,3082,1),'Ident (Prolog Variable)').
'symbol'('sp3','sp','src_span'(57,13,57,15,3085,2),'Ident (Prolog Variable)').
'symbol'('best3','best','src_span'(57,17,57,21,3089,4),'Ident (Prolog Variable)').
'symbol'('tok3','tok','src_span'(57,23,57,26,3095,3),'Ident (Prolog Variable)').
'symbol'('m4','m','src_span'(57,28,57,29,3100,1),'Ident (Prolog Variable)').
'symbol'('union','union','src_span'(59,36,59,41,3165,5),'BuiltIn primitive').
'symbol'('union','union','src_span'(62,36,62,41,3295,5),'BuiltIn primitive').
'symbol'('union','union','src_span'(63,40,63,45,3365,5),'BuiltIn primitive').
'symbol'('union','union','src_span'(64,39,64,44,3434,5),'BuiltIn primitive').
'symbol'('End','End','src_span'(66,1,66,4,3466,3),'Funktion or Process').
'symbol'('i6','i','src_span'(66,5,66,6,3470,1),'Ident (Prolog Variable)').
'symbol'('sp4','sp','src_span'(66,8,66,10,3473,2),'Ident (Prolog Variable)').
'symbol'('best4','best','src_span'(66,12,66,16,3477,4),'Ident (Prolog Variable)').
'symbol'('tok4','tok','src_span'(66,18,66,21,3483,3),'Ident (Prolog Variable)').
'symbol'('m5','m','src_span'(66,23,66,24,3488,1),'Ident (Prolog Variable)').
'symbol'('Next','Next','src_span'(77,1,77,5,3821,4),'Funktion or Process').
'symbol'('sp5','sp','src_span'(77,6,77,8,3826,2),'Ident (Prolog Variable)').
'symbol'('best5','best','src_span'(77,10,77,14,3830,4),'Ident (Prolog Variable)').
'symbol'('tok5','tok','src_span'(77,16,77,19,3836,3),'Ident (Prolog Variable)').
'symbol'('m6','m','src_span'(77,21,77,22,3841,1),'Ident (Prolog Variable)').
'symbol'('j','j','src_span'(77,37,77,38,3857,1),'Ident (Prolog Variable)').
'symbol'('p5','p','src_span'(77,39,77,40,3859,1),'Ident (Prolog Variable)').
'symbol'('FREE','FREE','src_span'(82,1,82,5,4125,4),'Ident (Groundrep.)').
'symbol'('b3','b','src_span'(82,17,82,18,4141,1),'Ident (Prolog Variable)').
'symbol'('FREE_FULL','FREE_FULL','src_span'(83,1,83,10,4184,9),'Funktion or Process').
'symbol'('b4','b','src_span'(83,11,83,12,4194,1),'Ident (Prolog Variable)').
'symbol'('x2','x','src_span'(83,49,83,50,4232,1),'Ident (Prolog Variable)').
'symbol'('MainApp','MainApp','src_span'(86,1,86,8,4326,7),'Ident (Groundrep.)').
'symbol'('Reporter','Reporter','src_span'(89,1,89,9,4473,8),'Ident (Groundrep.)').
'symbol'('r','r','src_span'(89,25,89,26,4497,1),'Ident (Prolog Variable)').
'symbol'('b5','b','src_span'(90,34,90,35,4560,1),'Ident (Prolog Variable)').
'symbol'('WRITERS','WRITERS','src_span'(92,1,92,8,4601,7),'Funktion or Process').
'symbol'('Rep','Rep','src_span'(92,9,92,12,4609,3),'Ident (Prolog Variable)').
'symbol'('NETWORK','NETWORK','src_span'(93,1,93,8,4686,7),'Funktion or Process').
'symbol'('Rep2','Rep','src_span'(93,9,93,12,4694,3),'Ident (Prolog Variable)').
'symbol'('SYSTEM','SYSTEM','src_span'(94,1,94,7,4791,6),'Ident (Groundrep.)').
'symbol'('OBS','OBS','src_span'(104,1,104,4,5402,3),'Funktion or Process').
'symbol'('cam','cam','src_span'(104,5,104,8,5406,3),'Ident (Prolog Variable)').
'symbol'('pend','pend','src_span'(104,10,104,14,5411,4),'Ident (Prolog Variable)').
'symbol'('best6','best','src_span'(104,16,104,20,5417,4),'Ident (Prolog Variable)').
'symbol'('sp6','sp','src_span'(104,22,104,24,5423,2),'Ident (Prolog Variable)').
'symbol'('send','send','src_span'(104,26,104,30,5427,4),'Ident (Prolog Variable)').
'symbol'('slot','slot','src_span'(104,32,104,36,5433,4),'Ident (Prolog Variable)').
'symbol'('i7','i','src_span'(105,17,105,18,5457,1),'Ident (Prolog Variable)').
'symbol'('b6','b','src_span'(105,19,105,20,5459,1),'Ident (Prolog Variable)').
'symbol'('b7','b','src_span'(106,19,106,20,5556,1),'Ident (Prolog Variable)').
'symbol'('member','member','src_span'(106,61,106,67,5598,6),'BuiltIn primitive').
'symbol'('o','o','src_span'(108,13,108,14,5720,1),'Ident (Prolog Variable)').
'symbol'('b8','b','src_span'(108,15,108,16,5722,1),'Ident (Prolog Variable)').
'symbol'('union','union','src_span'(110,73,110,78,5872,5),'BuiltIn primitive').
'symbol'('b9','b','src_span'(112,24,112,25,6002,1),'Ident (Prolog Variable)').
'symbol'('b132','b','src_span'(114,14,114,15,6157,1),'Ident (Prolog Variable)').
'symbol'('b133','b','src_span'(115,15,115,16,6250,1),'Ident (Prolog Variable)').
'symbol'('union','union','src_span'(115,60,115,65,6295,5),'BuiltIn primitive').
'symbol'('ROLE_EVENTS','ROLE_EVENTS','src_span'(117,1,117,12,6345,11),'Ident (Groundrep.)').
'symbol'('SYSTEM_OBS','SYSTEM_OBS','src_span'(118,1,118,11,6436,10),'Ident (Groundrep.)').
'symbol'('MCOUNT','MCOUNT','src_span'(124,1,124,7,6765,6),'Funktion or Process').
'symbol'('k','k','src_span'(124,8,124,9,6772,1),'Ident (Prolog Variable)').
'symbol'('ReporterStall','ReporterStall','src_span'(133,1,133,14,7397,13),'Ident (Groundrep.)').
'symbol'('r2','r','src_span'(133,30,133,31,7426,1),'Ident (Prolog Variable)').
'symbol'('b136','b','src_span'(134,39,134,40,7499,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM_STALL','SYSTEM_STALL','src_span'(135,1,135,13,7557,12),'Ident (Groundrep.)').
'symbol'('CYCLE','CYCLE','src_span'(137,1,137,6,7628,5),'Ident (Groundrep.)').
'symbol'('ReporterStop','ReporterStop','src_span'(144,1,144,13,7933,12),'Ident (Groundrep.)').
'symbol'('r3','r','src_span'(144,29,144,30,7961,1),'Ident (Prolog Variable)').
'symbol'('b138','b','src_span'(145,38,145,39,8032,1),'Ident (Prolog Variable)').
'symbol'('NETWORK_STOP','NETWORK_STOP','src_span'(146,1,146,13,8055,12),'Ident (Groundrep.)').
'symbol'('SYSTEM_STOP','SYSTEM_STOP','src_span'(148,1,148,12,8227,11),'Ident (Groundrep.)').
'symbol'('STALL_VIEW','STALL_VIEW','src_span'(150,1,150,11,8287,10),'Ident (Groundrep.)').
'symbol'('PRE','PRE','src_span'(151,1,151,4,8359,3),'Ident (Groundrep.)').
'symbol'('k2','k','src_span'(151,18,151,19,8376,1),'Ident (Prolog Variable)').
'symbol'('b140','b','src_span'(152,32,152,33,8447,1),'Ident (Prolog Variable)').
'symbol'('MERGING','MERGING','src_span'(153,1,153,8,8515,7),'Ident (Groundrep.)').