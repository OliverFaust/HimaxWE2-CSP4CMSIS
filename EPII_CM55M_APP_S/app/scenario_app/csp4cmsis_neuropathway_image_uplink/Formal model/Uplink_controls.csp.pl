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
'bindval'('W','int'(2),'src_span'(5,1,5,14,254,13)).
'bindval'('MAX_INDEX','int'(4),'src_span'(6,1,6,14,268,13)).
'bindval'('IDS','setExp'('rangeClosed'('int'(0),'int'(3))),'src_span'(7,1,7,19,282,18)).
'bindval'('NONE','int'(4),'src_span'(8,1,8,14,301,13)).
'bindval'('MAXM','int'(2),'src_span'(9,1,9,14,361,13)).
'agent'('sat'(_m),'ifte'('>'(_m,'val_of'('MAXM','src_span'(11,17,11,21,392,4))),'val_of'('MAXM','src_span'(11,27,11,31,402,4)),_m,'src_span'(11,10,11,21,385,11),'src_span'(11,22,11,26,396,18),'src_span'(11,32,11,36,406,11)),'src_span'(11,10,11,38,385,28)).
'dataTypeDef'('source_t',['constructor'('camera'),'constructor'('inference')]).
'dataTypeDef'('outcome_t',['constructor'('better'),'constructor'('worse'),'constructor'('failed')]).
'dataTypeDef'('report_t',['constructorC'('started','dotTupleType'(['source_t'])),'constructor'('stack'),'constructorC'('window','dotTupleType'(['setExp'('rangeClosed'('int'(0),'val_of'('MAXM','src_span'(15,60,15,64,608,4))))])),'constructorC'('image','dotTupleType'(['val_of'('IDS','src_span'(15,74,15,77,622,3))]))]).
'bindval'('TEXT','agent_call'('src_span'(17,8,17,12,634,4),'diff',['report_t','closure'(['image'])]),'src_span'(17,1,17,35,627,34)).
'channel'('g_trigger_chan','type'('dotUnitType')).
'channel'('frame_chan','type'('dotTupleType'(['setExp'('rangeClosed'('int'(0),'-'('val_of'('MAX_INDEX','src_span'(20,28,20,37,772,9)),'int'(1)))),'val_of'('IDS','src_span'(20,41,20,44,785,3))]))).
'channel'('release_chan','type'('dotTupleType'(['val_of'('IDS','src_span'(21,24,21,27,863,3))]))).
'channel'('free_in','type'('dotTupleType'(['val_of'('IDS','src_span'(22,24,22,27,967,3))]))).
'channel'('free_out','type'('dotTupleType'(['val_of'('IDS','src_span'(23,24,23,27,1046,3))]))).
'channel'('poll_empty','type'('dotUnitType')).
'channel'('report_chan','type'('dotTupleType'(['report_t']))).
'channel'('line','type'('dotTupleType'(['report_t']))).
'channel'('uplink','type'('dotTupleType'(['val_of'('IDS','src_span'(27,24,27,27,1410,3))]))).
'channel'('scored','type'('dotTupleType'(['outcome_t','val_of'('IDS','src_span'(28,34,28,37,1513,3))]))).
'channel'('merge','type'('dotUnitType')).
'channel'('camera_log','type'('dotUnitType')).
'channel'('stack_tick','type'('dotUnitType')).
'channel'('overflow','type'('dotUnitType')).
'channel'('error','type'('dotUnitType')).
'bindval'('ENV','prefix'('src_span'(33,7,33,21,1728,14),[],'g_trigger_chan','val_of'('ENV','src_span'(33,25,33,28,1746,3)),'src_span'(33,22,33,24,1742,21)),'src_span'(33,1,33,28,1722,27)).
'agent'('RUN'(_A),'repChoice'(['comprehensionGenerator'(_x,_A)],'prefix'('src_span'(35,21,35,22,1771,1),[],_x,'agent_call'('src_span'(35,26,35,29,1776,3),'RUN',[_A]),'src_span'(35,23,35,25,1772,11)),'src_span'(35,13,35,20,1763,7)),'src_span'(35,10,35,32,1760,22)).
'bindval'('Camera','prefix'('src_span'(38,10,38,20,1880,10),[],'camera_log','prefix'('src_span'(38,24,38,35,1894,11),['out'('dotTuple'(['started','camera']))],'report_chan','agent_call'('src_span'(38,54,38,64,1924,10),'CameraLoop',['int'(0),'int'(0)]),'src_span'(38,51,38,53,1920,35)),'src_span'(38,21,38,23,1890,60)),'src_span'(38,1,38,70,1871,69)).
'agent'('CameraLoop'(_i,_b),'prefix'('src_span'(39,20,39,34,1960,14),[],'g_trigger_chan','prefix'('src_span'(39,38,39,48,1978,10),['out'(_i),'out'(_b)],'frame_chan','prefix'('src_span'(39,56,39,68,1996,12),['in'(_nb)],'release_chan','agent_call'('src_span'(39,75,39,85,2015,10),'CameraLoop',['%'('+'(_i,'int'(1)),'val_of'('MAX_INDEX','src_span'(39,96,39,105,2036,9))),_nb]),'src_span'(39,72,39,74,2011,42)),'src_span'(39,53,39,55,1992,60)),'src_span'(39,35,39,37,1974,90)),'src_span'(39,20,39,110,1960,90)).
'bindval'('Inference','prefix'('src_span'(45,13,45,23,2379,10),['in'(_i2),'in'(_p)],'frame_chan','prefix'('src_span'(45,31,45,42,2397,11),['out'('dotTuple'(['started','inference']))],'report_chan','agent_call'('src_span'(45,64,45,69,2430,5),'Infer',[_i2,_p,'agent_call'('src_span'(45,76,45,80,2442,4),'diff',['val_of'('IDS','src_span'(45,81,45,84,2447,3)),'setExp'('rangeEnum'([_p]))]),'val_of'('NONE','src_span'(45,92,45,96,2458,4)),'true','int'(0)]),'src_span'(45,61,45,63,2426,64)),'src_span'(45,28,45,30,2393,81)),'src_span'(45,1,45,106,2367,105)).
'agent'('Infer'(_i3,_p2,_sp,_best,_tok,_m2),'[]'('prefix'('src_span'(48,6,48,14,2511,8),['in'(_b2)],'free_out','agent_call'('src_span'(48,20,48,27,2525,7),'Release',[_i3,_p2,'agent_call'('src_span'(48,34,48,39,2539,5),'union',[_sp,'setExp'('rangeEnum'([_b2]))]),_best,'true',_m2]),'src_span'(48,17,48,19,2521,50)),'prefix'('src_span'(49,9,49,19,2579,10),[],'poll_empty','agent_call'('src_span'(49,23,49,30,2593,7),'Release',[_i3,_p2,_sp,_best,_tok,_m2]),'src_span'(49,20,49,22,2589,45)),'src_span_operator'('no_loc_info_available','src_span'(49,5,49,7,2575,2))),'no_loc_info_available').
'agent'('Release'(_i4,_p3,_sp2,_best2,_tok2,_m3),'repInternalChoice'(['comprehensionGenerator'(_s,_sp2)],'prefix'('src_span'(51,48,51,60,2674,12),['out'(_s)],'release_chan','agent_call'('src_span'(51,66,51,71,2692,5),'Score',[_i4,_p3,'agent_call'('src_span'(51,78,51,82,2704,4),'diff',[_sp2,'setExp'('rangeEnum'([_s]))]),_best2,_tok2,_m3]),'src_span'(51,63,51,65,2688,46)),'src_span'(51,39,51,47,2665,8)),'src_span'(51,35,51,106,2661,71)).
'agent'('Score'(_i5,_p4,_sp3,_best3,_tok3,_m4),'ifte'('=='(_best3,'val_of'('NONE','src_span'(54,16,54,20,2781,4))),'|~|'('prefix'('src_span'(55,10,55,16,2800,6),['out'('failed'),'out'(_p4)],'scored','agent_call'('src_span'(55,29,55,32,2819,3),'End',[_i5,'agent_call'('src_span'(55,36,55,41,2826,5),'union',[_sp3,'setExp'('rangeEnum'([_p4]))]),_best3,_tok3,_m4]),'src_span'(55,26,55,28,2815,42)),'prefix'('src_span'(56,14,56,20,2870,6),['out'('better'),'out'(_p4)],'scored','agent_call'('src_span'(56,33,56,36,2889,3),'End',[_i5,_sp3,_p4,_tok3,_m4]),'src_span'(56,30,56,32,2885,27)),'src_span_operator'('no_loc_info_available','src_span'(56,9,56,12,2865,3))),'|~|'('|~|'('prefix'('src_span'(58,10,58,16,2930,6),['out'('failed'),'out'(_p4)],'scored','agent_call'('src_span'(58,29,58,32,2949,3),'End',[_i5,'agent_call'('src_span'(58,36,58,41,2956,5),'union',[_sp3,'setExp'('rangeEnum'([_p4]))]),_best3,_tok3,_m4]),'src_span'(58,26,58,28,2945,42)),'prefix'('src_span'(59,14,59,20,3000,6),['out'('better'),'out'(_p4)],'scored','agent_call'('src_span'(59,33,59,36,3019,3),'End',[_i5,'agent_call'('src_span'(59,40,59,45,3026,5),'union',[_sp3,'setExp'('rangeEnum'([_best3]))]),_p4,_tok3,_m4]),'src_span'(59,30,59,32,3015,42)),'src_span_operator'('no_loc_info_available','src_span'(59,9,59,12,2995,3))),'prefix'('src_span'(60,14,60,20,3070,6),['out'('worse'),'out'(_p4)],'scored','agent_call'('src_span'(60,32,60,35,3088,3),'End',[_i5,'agent_call'('src_span'(60,39,60,44,3095,5),'union',[_sp3,'setExp'('rangeEnum'([_p4]))]),_best3,_tok3,_m4]),'src_span'(60,29,60,31,3084,42)),'src_span_operator'('no_loc_info_available','src_span'(60,9,60,12,3065,3))),'no_loc_info_available','no_loc_info_available','no_loc_info_available'),'src_span'(54,5,60,69,2770,355)).
'agent'('End'(_i6,_sp4,_best4,_tok4,_m5),'ifte'('=='('%'(_i6,'val_of'('W','src_span'(63,12,63,13,3165,1))),'-'('val_of'('W','src_span'(63,17,63,18,3170,1)),'int'(1))),'ifte'(_tok4,'prefix'('src_span'(65,13,65,24,3213,11),['out'('dotTuple'(['window',_m5]))],'report_chan','ifte'('!='(_best4,'val_of'('NONE','src_span'(66,29,66,33,3265,4))),'prefix'('src_span'(66,39,66,50,3275,11),['out'('dotTuple'(['image',_best4]))],'report_chan','agent_call'('src_span'(66,65,66,69,3301,4),'Next',[_sp4,'val_of'('NONE','src_span'(66,74,66,78,3310,4)),'false','int'(0)]),'src_span'(66,62,66,64,3297,39)),'agent_call'('src_span'(67,23,67,27,3348,4),'Next',[_sp4,'val_of'('NONE','src_span'(67,32,67,36,3357,4)),'true','int'(0)]),'no_loc_info_available','no_loc_info_available','src_span'(66,90,67,22,3325,96)),'src_span'(65,34,66,16,3233,148)),'prefix'('src_span'(69,13,69,18,3398,5),[],'merge','agent_call'('src_span'(69,22,69,26,3407,4),'Next',[_sp4,_best4,'false','agent_call'('src_span'(69,44,69,47,3429,3),'sat',['+'(_m5,'int'(1))])]),'src_span'(69,19,69,21,3403,42)),'src_span'(64,9,64,15,3189,6),'src_span'(64,16,65,12,3195,180),'src_span'(67,48,69,12,3372,227)),'agent_call'('src_span'(71,9,71,13,3458,4),'Next',[_sp4,_best4,_tok4,_m5]),'no_loc_info_available','no_loc_info_available','src_span'(69,56,71,8,3440,291)),'src_span'(63,5,71,31,3158,322)).
'agent'('Next'(_sp5,_best5,_tok5,_m6),'prefix'('src_span'(73,26,73,36,3507,10),['in'(_j),'in'(_p5)],'frame_chan','agent_call'('src_span'(73,44,73,49,3525,5),'Infer',[_j,_p5,_sp5,_best5,_tok5,_m6]),'src_span'(73,41,73,43,3521,35)),'src_span'(73,26,73,73,3507,47)).
'bindval'('FREE','[]'('prefix'('src_span'(78,9,78,16,3794,7),['in'(_b3)],'free_in','agent_call'('src_span'(78,22,78,31,3807,9),'FREE_FULL',[_b3]),'src_span'(78,19,78,21,3803,18)),'prefix'('src_span'(78,40,78,50,3825,10),[],'poll_empty','val_of'('FREE','src_span'(78,54,78,58,3839,4)),'src_span'(78,51,78,53,3835,18)),'src_span_operator'('no_loc_info_available','src_span'(78,36,78,38,3821,2))),'src_span'(78,1,78,59,3786,58)).
'agent'('FREE_FULL'(_b4),'[]'('prefix'('src_span'(79,17,79,25,3861,8),['out'(_b4)],'free_out','val_of'('FREE','src_span'(79,31,79,35,3875,4)),'src_span'(79,28,79,30,3871,10)),'prefix'('src_span'(79,41,79,48,3885,7),['in'(_x2)],'free_in','prefix'('src_span'(79,54,79,62,3898,8),[],'overflow','stop'('src_span'(79,66,79,70,3910,4)),'src_span'(79,63,79,65,3906,16)),'src_span'(79,51,79,53,3894,22)),'src_span_operator'('no_loc_info_available','src_span'(79,37,79,39,3881,2))),'no_loc_info_available').
'bindval'('MainApp','prefix'('src_span'(82,11,82,21,3997,10),[],'stack_tick','prefix'('src_span'(82,25,82,36,4011,11),['out'('stack')],'report_chan','val_of'('MainApp','src_span'(82,46,82,53,4032,7)),'src_span'(82,43,82,45,4028,17)),'src_span'(82,22,82,24,4007,42)),'src_span'(82,1,82,53,3987,52)).
'bindval'('Reporter','[]'('prefix'('src_span'(85,13,85,24,4146,11),['inGuard'(_r,'val_of'('TEXT','src_span'(85,27,85,31,4160,4)))],'report_chan','prefix'('src_span'(85,35,85,39,4168,4),['out'(_r)],'line','val_of'('Reporter','src_span'(85,45,85,53,4178,8)),'src_span'(85,42,85,44,4174,14)),'src_span'(85,32,85,34,4164,29)),'prefix'('src_span'(86,16,86,33,4203,17),['in'(_b5)],'dotTuple'(['report_chan','image']),'prefix'('src_span'(86,39,86,45,4226,6),['out'(_b5)],'uplink','prefix'('src_span'(86,51,86,58,4238,7),['out'(_b5)],'free_in','val_of'('Reporter','src_span'(86,64,86,72,4251,8)),'src_span'(86,61,86,63,4247,14)),'src_span'(86,48,86,50,4234,27)),'src_span'(86,36,86,38,4222,39)),'src_span_operator'('no_loc_info_available','src_span'(86,12,86,14,4199,2))),'src_span'(85,1,86,73,4134,126)).
'agent'('OBS'(_cam,_pend,_best6,_sp6,_send,_slot),'[]'('[]'('[]'('[]'('[]'('prefix'('src_span'(94,6,94,16,4783,10),['in'(_i7),'in'(_b6)],'frame_chan','ifte'('=='(_b6,_cam),'agent_call'('src_span'(94,42,94,45,4819,3),'OBS',['val_of'('NONE','src_span'(94,46,94,50,4823,4)),_b6,_best6,_sp6,_send,_slot]),'prefix'('src_span'(94,82,94,87,4859,5),[],'error','stop'('src_span'(94,91,94,95,4868,4)),'src_span'(94,88,94,90,4864,13)),'no_loc_info_available','no_loc_info_available','src_span'(94,77,94,81,4853,53)),'src_span'(94,21,94,23,4797,78)),'prefix'('src_span'(95,6,95,18,4880,12),['in'(_b7)],'release_chan','ifte'('bool_and'('bool_and'('=='(_cam,'val_of'('NONE','src_span'(95,35,95,39,4909,4))),'!='(_pend,'val_of'('NONE','src_span'(95,52,95,56,4926,4)))),'agent_call'('src_span'(95,61,95,67,4935,6),'member',[_b7,_sp6])),'agent_call'('src_span'(96,30,96,33,4978,3),'OBS',[_b7,_pend,_best6,'agent_call'('src_span'(96,49,96,53,4997,4),'diff',[_sp6,'setExp'('rangeEnum'([_b7]))]),_send,_slot]),'prefix'('src_span'(96,81,96,86,5029,5),[],'error','stop'('src_span'(96,90,96,94,5038,4)),'src_span'(96,87,96,89,5034,13)),'no_loc_info_available','no_loc_info_available','src_span'(96,76,96,80,5023,64)),'src_span'(95,21,95,23,4894,151)),'src_span_operator'('no_loc_info_available','src_span'(95,2,95,4,4876,2))),'prefix'('src_span'(97,6,97,12,5050,6),['in'(_o),'in'(_b8)],'scored','ifte'('!='(_b8,_pend),'prefix'('src_span'(97,39,97,44,5083,5),[],'error','stop'('src_span'(97,48,97,52,5092,4)),'src_span'(97,45,97,47,5088,13)),'ifte'('=='(_o,'better'),'agent_call'('src_span'(99,26,99,29,5162,3),'OBS',[_cam,'val_of'('NONE','src_span'(99,35,99,39,5171,4)),_b8,'ifte'('=='(_best6,'val_of'('NONE','src_span'(99,55,99,59,5191,4))),_sp6,'agent_call'('src_span'(99,73,99,78,5209,5),'union',[_sp6,'setExp'('rangeEnum'([_best6]))]),'no_loc_info_available','no_loc_info_available','src_span'(99,68,99,72,5203,25)),_send,_slot]),'agent_call'('src_span'(100,26,100,29,5265,3),'OBS',[_cam,'val_of'('NONE','src_span'(100,35,100,39,5274,4)),_best6,'agent_call'('src_span'(100,47,100,52,5286,5),'union',[_sp6,'setExp'('rangeEnum'([_b8]))]),_send,_slot]),'no_loc_info_available','no_loc_info_available','src_span'(99,104,100,25,5239,151)),'no_loc_info_available','no_loc_info_available','src_span'(97,53,98,25,5096,230)),'src_span'(97,17,97,19,5060,256)),'src_span_operator'('no_loc_info_available','src_span'(97,2,97,4,5046,2))),'prefix'('src_span'(101,6,101,23,5321,17),['in'(_b9)],'dotTuple'(['report_chan','image']),'ifte'('bool_and'('bool_and'('=='(_b9,_best6),'=='(_send,'val_of'('NONE','src_span'(101,55,101,59,5370,4)))),'=='(_slot,'val_of'('NONE','src_span'(101,72,101,76,5387,4)))),'agent_call'('src_span'(102,35,102,38,5426,3),'OBS',[_cam,_pend,'val_of'('NONE','src_span'(102,50,102,54,5441,4)),_sp6,_b9,_slot]),'prefix'('src_span'(102,74,102,79,5465,5),[],'error','stop'('src_span'(102,83,102,87,5474,4)),'src_span'(102,80,102,82,5470,13)),'no_loc_info_available','no_loc_info_available','src_span'(102,69,102,73,5459,52)),'src_span'(101,26,101,28,5340,141)),'src_span_operator'('no_loc_info_available','src_span'(101,2,101,4,5317,2))),'prefix'('src_span'(103,6,103,13,5486,7),['in'(_b133)],'free_in','ifte'('=='(_b133,_send),'agent_call'('src_span'(103,38,103,41,5518,3),'OBS',[_cam,_pend,_best6,_sp6,'val_of'('NONE','src_span'(103,63,103,67,5543,4)),_b133]),'prefix'('src_span'(103,77,103,82,5557,5),[],'error','stop'('src_span'(103,86,103,90,5566,4)),'src_span'(103,83,103,85,5562,13)),'no_loc_info_available','no_loc_info_available','src_span'(103,72,103,76,5551,52)),'src_span'(103,16,103,18,5495,78)),'src_span_operator'('no_loc_info_available','src_span'(103,2,103,4,5482,2))),'prefix'('src_span'(104,6,104,14,5578,8),['in'(_b134)],'free_out','ifte'('=='(_b134,_slot),'agent_call'('src_span'(104,39,104,42,5611,3),'OBS',[_cam,_pend,_best6,'agent_call'('src_span'(104,60,104,65,5632,5),'union',[_sp6,'setExp'('rangeEnum'([_b134]))]),_send,'val_of'('NONE','src_span'(104,82,104,86,5654,4))]),'prefix'('src_span'(104,93,104,98,5665,5),[],'error','stop'('src_span'(104,102,104,106,5674,4)),'src_span'(104,99,104,101,5670,13)),'no_loc_info_available','no_loc_info_available','src_span'(104,88,104,92,5659,67)),'src_span'(104,17,104,19,5588,93)),'src_span_operator'('no_loc_info_available','src_span'(104,2,104,4,5574,2))),'no_loc_info_available').
'bindval'('ROLE_EVENTS','closure'(['frame_chan','release_chan','scored','dotTuple'(['report_chan','image']),'free_in','free_out']),'src_span'(106,1,106,91,5682,90)).
'bindval'('ReporterStall','[]'('prefix'('src_span'(108,18,108,29,5791,11),['inGuard'(_r2,'val_of'('TEXT','src_span'(108,32,108,36,5805,4)))],'report_chan','prefix'('src_span'(108,40,108,44,5813,4),['out'(_r2)],'line','val_of'('ReporterStall','src_span'(108,50,108,63,5823,13)),'src_span'(108,47,108,49,5819,19)),'src_span'(108,37,108,39,5809,34)),'prefix'('src_span'(109,21,109,38,5858,17),['in'(_b136)],'dotTuple'(['report_chan','image']),'prefix'('src_span'(109,44,109,50,5881,6),['out'(_b136)],'uplink','|~|'('prefix'('src_span'(109,58,109,65,5895,7),['out'(_b136)],'free_in','val_of'('ReporterStall','src_span'(109,71,109,84,5908,13)),'src_span'(109,68,109,70,5904,19)),'stop'('src_span'(109,90,109,94,5927,4)),'src_span_operator'('no_loc_info_available','src_span'(109,86,109,89,5923,3))),'src_span'(109,53,109,55,5889,45)),'src_span'(109,41,109,43,5877,57)),'src_span_operator'('no_loc_info_available','src_span'(109,17,109,19,5854,2))),'src_span'(108,1,109,96,5774,159)).
'bindval'('CYCLE','prefix'('src_span'(111,9,111,23,5943,14),[],'g_trigger_chan','val_of'('CYCLE','src_span'(111,27,111,32,5961,5)),'src_span'(111,24,111,26,5957,23)),'src_span'(111,1,111,32,5935,31)).
'agent'('Release1'(_i8,_p6,_sp7,_best7,_tok6,_m7),'repInternalChoice'(['comprehensionGenerator'(_s2,'agent_call'('src_span'(117,13,117,18,6285,5),'union',[_sp7,'ifte'('=='(_best7,'val_of'('NONE','src_span'(117,34,117,38,6306,4))),'setExp'('rangeEnum'([])),'setExp'('rangeEnum'([_best7])),'no_loc_info_available','no_loc_info_available','src_span'(117,47,117,51,6318,14))]))],'prefix'('src_span'(118,9,118,21,6342,12),['out'(_s2)],'release_chan','agent_call'('src_span'(118,27,118,33,6360,6),'Score1',[_i8,_p6,'agent_call'('src_span'(118,40,118,44,6373,4),'diff',[_sp7,'setExp'('rangeEnum'([_s2]))]),_best7,_tok6,_m7]),'src_span'(118,24,118,26,6356,47)),'src_span'(117,9,117,61,6281,52)),'src_span'(117,5,118,68,6277,124)).
'bindval'('Inference1','prefix'('src_span'(119,14,119,24,6415,10),['in'(_i9),'in'(_p7)],'frame_chan','prefix'('src_span'(119,32,119,43,6433,11),['out'('dotTuple'(['started','inference']))],'report_chan','agent_call'('src_span'(119,65,119,71,6466,6),'Infer1',[_i9,_p7,'agent_call'('src_span'(119,78,119,82,6479,4),'diff',['val_of'('IDS','src_span'(119,83,119,86,6484,3)),'setExp'('rangeEnum'([_p7]))]),'val_of'('NONE','src_span'(119,94,119,98,6495,4)),'true','int'(0)]),'src_span'(119,62,119,64,6462,65)),'src_span'(119,29,119,31,6429,82)),'src_span'(119,1,119,108,6402,107)).
'agent'('Infer1'(_i146,_p8,_sp8,_best8,_tok7,_m8),'[]'('prefix'('src_span'(121,6,121,14,6548,8),['in'(_b152)],'free_out','agent_call'('src_span'(121,20,121,28,6562,8),'Release1',[_i146,_p8,'agent_call'('src_span'(121,35,121,40,6577,5),'union',[_sp8,'setExp'('rangeEnum'([_b152]))]),_best8,'true',_m8]),'src_span'(121,17,121,19,6558,51)),'prefix'('src_span'(122,9,122,19,6617,10),[],'poll_empty','agent_call'('src_span'(122,23,122,31,6631,8),'Release1',[_i146,_p8,_sp8,_best8,_tok7,_m8]),'src_span'(122,20,122,22,6627,46)),'src_span_operator'('no_loc_info_available','src_span'(122,5,122,7,6613,2))),'no_loc_info_available').
'agent'('Score1'(_i153,_p9,_sp9,_best9,_tok8,_m9),'ifte'('=='(_best9,'val_of'('NONE','src_span'(124,16,124,20,6713,4))),'|~|'('prefix'('src_span'(125,10,125,16,6732,6),['out'('failed'),'out'(_p9)],'scored','agent_call'('src_span'(125,29,125,33,6751,4),'End1',[_i153,'agent_call'('src_span'(125,37,125,42,6759,5),'union',[_sp9,'setExp'('rangeEnum'([_p9]))]),_best9,_tok8,_m9]),'src_span'(125,26,125,28,6747,43)),'prefix'('src_span'(126,14,126,20,6803,6),['out'('better'),'out'(_p9)],'scored','agent_call'('src_span'(126,33,126,37,6822,4),'End1',[_i153,_sp9,_p9,_tok8,_m9]),'src_span'(126,30,126,32,6818,28)),'src_span_operator'('no_loc_info_available','src_span'(126,9,126,12,6798,3))),'|~|'('|~|'('prefix'('src_span'(128,10,128,16,6864,6),['out'('failed'),'out'(_p9)],'scored','agent_call'('src_span'(128,29,128,33,6883,4),'End1',[_i153,'agent_call'('src_span'(128,37,128,42,6891,5),'union',[_sp9,'setExp'('rangeEnum'([_p9]))]),_best9,_tok8,_m9]),'src_span'(128,26,128,28,6879,43)),'prefix'('src_span'(129,14,129,20,6935,6),['out'('better'),'out'(_p9)],'scored','agent_call'('src_span'(129,33,129,37,6954,4),'End1',[_i153,'agent_call'('src_span'(129,41,129,46,6962,5),'union',[_sp9,'setExp'('rangeEnum'([_best9]))]),_p9,_tok8,_m9]),'src_span'(129,30,129,32,6950,43)),'src_span_operator'('no_loc_info_available','src_span'(129,9,129,12,6930,3))),'prefix'('src_span'(130,14,130,20,7006,6),['out'('worse'),'out'(_p9)],'scored','agent_call'('src_span'(130,32,130,36,7024,4),'End1',[_i153,'agent_call'('src_span'(130,40,130,45,7032,5),'union',[_sp9,'setExp'('rangeEnum'([_p9]))]),_best9,_tok8,_m9]),'src_span'(130,29,130,31,7020,43)),'src_span_operator'('no_loc_info_available','src_span'(130,9,130,12,7001,3))),'no_loc_info_available','no_loc_info_available','no_loc_info_available'),'src_span'(124,5,130,70,6702,360)).
'agent'('End1'(_i159,_sp160,_best161,_tok9,_m163),'ifte'('=='('%'(_i159,'val_of'('W','src_span'(132,12,132,13,7102,1))),'-'('val_of'('W','src_span'(132,17,132,18,7107,1)),'int'(1))),'ifte'(_tok9,'prefix'('src_span'(134,13,134,24,7150,11),['out'('dotTuple'(['window',_m163]))],'report_chan','ifte'('!='(_best161,'val_of'('NONE','src_span'(135,29,135,33,7202,4))),'prefix'('src_span'(135,39,135,50,7212,11),['out'('dotTuple'(['image',_best161]))],'report_chan','agent_call'('src_span'(135,65,135,70,7238,5),'Next1',[_sp160,'val_of'('NONE','src_span'(135,75,135,79,7248,4)),'false','int'(0)]),'src_span'(135,62,135,64,7234,40)),'agent_call'('src_span'(136,23,136,28,7286,5),'Next1',[_sp160,'val_of'('NONE','src_span'(136,33,136,37,7296,4)),'true','int'(0)]),'no_loc_info_available','no_loc_info_available','src_span'(135,91,136,22,7263,98)),'src_span'(134,34,135,16,7170,150)),'prefix'('src_span'(138,13,138,18,7337,5),[],'merge','agent_call'('src_span'(138,22,138,27,7346,5),'Next1',[_sp160,_best161,'false','agent_call'('src_span'(138,45,138,48,7369,3),'sat',['+'(_m163,'int'(1))])]),'src_span'(138,19,138,21,7342,43)),'src_span'(133,9,133,15,7126,6),'src_span'(133,16,134,12,7132,182),'src_span'(136,49,138,12,7311,230)),'agent_call'('src_span'(140,9,140,14,7398,5),'Next1',[_sp160,_best161,_tok9,_m163]),'no_loc_info_available','no_loc_info_available','src_span'(138,57,140,8,7380,295)),'src_span'(132,5,140,32,7095,326)).
'agent'('Next1'(_sp164,_best165,_tok166,_m167),'prefix'('src_span'(141,27,141,37,7448,10),['in'(_j2),'in'(_p169)],'frame_chan','agent_call'('src_span'(141,45,141,51,7466,6),'Infer1',[_j2,_p169,_sp164,_best165,_tok166,_m167]),'src_span'(141,42,141,44,7462,36)),'src_span'(141,27,141,75,7448,48)).
'bindval'('SYSTEM1','sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(143,11,143,14,7508,3)),'sharing'('closure'(['free_in','free_out','poll_empty']),'sharing'('closure'(['report_chan']),'|||'('sharing'('closure'(['frame_chan','release_chan']),'val_of'('Camera','src_span'(144,9,144,15,7547,6)),'val_of'('Inference1','src_span'(144,53,144,63,7591,10)),'src_span'(144,16,144,52,7554,36)),'val_of'('MainApp','src_span'(144,69,144,76,7607,7)),'src_span_operator'('no_loc_info_available','src_span'(144,65,144,68,7603,3))),'val_of'('Reporter','src_span'(144,102,144,110,7640,8)),'src_span'(144,78,144,101,7616,23)),'val_of'('FREE','src_span'(145,48,145,52,7697,4)),'src_span'(145,6,145,47,7655,41)),'src_span'(143,15,143,41,7512,26)),'src_span'(143,1,145,53,7498,204)).
'bindval'('SYSTEM1_OBS','sharing'('val_of'('ROLE_EVENTS','src_span'(146,26,146,37,7728,11)),'val_of'('SYSTEM1','src_span'(146,15,146,22,7717,7)),'agent_call'('src_span'(146,41,146,44,7743,3),'OBS',['int'(0),'val_of'('NONE','src_span'(146,48,146,52,7750,4)),'val_of'('NONE','src_span'(146,54,146,58,7756,4)),'setExp'('rangeEnum'(['int'(1),'int'(2),'int'(3)])),'val_of'('NONE','src_span'(146,71,146,75,7773,4)),'val_of'('NONE','src_span'(146,77,146,81,7779,4))]),'src_span'(146,23,146,40,7725,17)),'src_span'(146,1,146,82,7703,81)).
'assertRef'('False','agent_call'('src_span'(148,8,148,11,7793,3),'RUN',['agent_call'('src_span'(148,12,148,16,7797,4),'diff',['Events','setExp'('rangeEnum'(['error','overflow']))])]),'Trace','val_of'('SYSTEM1_OBS','src_span'(148,49,148,60,7834,11)),'src_span'(148,1,148,60,7786,59)).
'agent'('End2'(_i170,_sp171,_best172,_tok173,_m174),'ifte'('=='('%'(_i170,'val_of'('W','src_span'(153,12,153,13,8103,1))),'-'('val_of'('W','src_span'(153,17,153,18,8108,1)),'int'(1))),'prefix'('src_span'(154,9,154,20,8127,11),['out'('dotTuple'(['window',_m174]))],'report_chan','ifte'('!='(_best172,'val_of'('NONE','src_span'(155,25,155,29,8175,4))),'prefix'('src_span'(155,35,155,46,8185,11),['out'('dotTuple'(['image',_best172]))],'report_chan','agent_call'('src_span'(155,61,155,66,8211,5),'Next2',[_sp171,'val_of'('NONE','src_span'(155,71,155,75,8221,4)),'false','int'(0)]),'src_span'(155,58,155,60,8207,40)),'agent_call'('src_span'(156,19,156,24,8255,5),'Next2',[_sp171,'val_of'('NONE','src_span'(156,29,156,33,8265,4)),_tok173,'int'(0)]),'no_loc_info_available','no_loc_info_available','src_span'(155,87,156,18,8236,93)),'src_span'(154,30,155,12,8147,141)),'agent_call'('src_span'(158,9,158,14,8297,5),'Next2',[_sp171,_best172,_tok173,_m174]),'no_loc_info_available','no_loc_info_available','src_span'(156,44,158,8,8279,193)),'src_span'(153,5,158,32,8096,224)).
'bindval'('Inference2','prefix'('src_span'(159,14,159,24,8334,10),['in'(_i175),'in'(_p176)],'frame_chan','prefix'('src_span'(159,32,159,43,8352,11),['out'('dotTuple'(['started','inference']))],'report_chan','agent_call'('src_span'(159,65,159,71,8385,6),'Infer2',[_i175,_p176,'agent_call'('src_span'(159,78,159,82,8398,4),'diff',['val_of'('IDS','src_span'(159,83,159,86,8403,3)),'setExp'('rangeEnum'([_p176]))]),'val_of'('NONE','src_span'(159,94,159,98,8414,4)),'true','int'(0)]),'src_span'(159,62,159,64,8381,65)),'src_span'(159,29,159,31,8348,82)),'src_span'(159,1,159,108,8321,107)).
'agent'('Infer2'(_i177,_p178,_sp179,_best180,_tok181,_m182),'[]'('prefix'('src_span'(161,6,161,14,8467,8),['in'(_b183)],'free_out','agent_call'('src_span'(161,20,161,28,8481,8),'Release2',[_i177,_p178,'agent_call'('src_span'(161,35,161,40,8496,5),'union',[_sp179,'setExp'('rangeEnum'([_b183]))]),_best180,'true',_m182]),'src_span'(161,17,161,19,8477,51)),'prefix'('src_span'(162,9,162,19,8536,10),[],'poll_empty','agent_call'('src_span'(162,23,162,31,8550,8),'Release2',[_i177,_p178,_sp179,_best180,_tok181,_m182]),'src_span'(162,20,162,22,8546,46)),'src_span_operator'('no_loc_info_available','src_span'(162,5,162,7,8532,2))),'no_loc_info_available').
'agent'('Release2'(_i184,_p185,_sp186,_best187,_tok188,_m189),'repInternalChoice'(['comprehensionGenerator'(_s3,_sp186)],'prefix'('src_span'(163,49,163,61,8632,12),['out'(_s3)],'release_chan','agent_call'('src_span'(163,67,163,73,8650,6),'Score2',[_i184,_p185,'agent_call'('src_span'(163,80,163,84,8663,4),'diff',[_sp186,'setExp'('rangeEnum'([_s3]))]),_best187,_tok188,_m189]),'src_span'(163,64,163,66,8646,47)),'src_span'(163,40,163,48,8623,8)),'src_span'(163,36,163,108,8619,72)).
'agent'('Score2'(_i191,_p192,_sp193,_best194,_tok195,_m196),'ifte'('=='(_best194,'val_of'('NONE','src_span'(165,16,165,20,8740,4))),'|~|'('prefix'('src_span'(166,10,166,16,8759,6),['out'('failed'),'out'(_p192)],'scored','agent_call'('src_span'(166,29,166,33,8778,4),'End2',[_i191,'agent_call'('src_span'(166,37,166,42,8786,5),'union',[_sp193,'setExp'('rangeEnum'([_p192]))]),_best194,_tok195,_m196]),'src_span'(166,26,166,28,8774,43)),'prefix'('src_span'(167,14,167,20,8830,6),['out'('better'),'out'(_p192)],'scored','agent_call'('src_span'(167,33,167,37,8849,4),'End2',[_i191,_sp193,_p192,_tok195,_m196]),'src_span'(167,30,167,32,8845,28)),'src_span_operator'('no_loc_info_available','src_span'(167,9,167,12,8825,3))),'|~|'('|~|'('prefix'('src_span'(169,10,169,16,8891,6),['out'('failed'),'out'(_p192)],'scored','agent_call'('src_span'(169,29,169,33,8910,4),'End2',[_i191,'agent_call'('src_span'(169,37,169,42,8918,5),'union',[_sp193,'setExp'('rangeEnum'([_p192]))]),_best194,_tok195,_m196]),'src_span'(169,26,169,28,8906,43)),'prefix'('src_span'(170,14,170,20,8962,6),['out'('better'),'out'(_p192)],'scored','agent_call'('src_span'(170,33,170,37,8981,4),'End2',[_i191,'agent_call'('src_span'(170,41,170,46,8989,5),'union',[_sp193,'setExp'('rangeEnum'([_best194]))]),_p192,_tok195,_m196]),'src_span'(170,30,170,32,8977,43)),'src_span_operator'('no_loc_info_available','src_span'(170,9,170,12,8957,3))),'prefix'('src_span'(171,14,171,20,9033,6),['out'('worse'),'out'(_p192)],'scored','agent_call'('src_span'(171,32,171,36,9051,4),'End2',[_i191,'agent_call'('src_span'(171,40,171,45,9059,5),'union',[_sp193,'setExp'('rangeEnum'([_p192]))]),_best194,_tok195,_m196]),'src_span'(171,29,171,31,9047,43)),'src_span_operator'('no_loc_info_available','src_span'(171,9,171,12,9028,3))),'no_loc_info_available','no_loc_info_available','no_loc_info_available'),'src_span'(165,5,171,70,8729,360)).
'agent'('Next2'(_sp197,_best198,_tok199,_m200),'prefix'('src_span'(172,27,172,37,9116,10),['in'(_j3),'in'(_p202)],'frame_chan','agent_call'('src_span'(172,45,172,51,9134,6),'Infer2',[_j3,_p202,_sp197,_best198,_tok199,_m200]),'src_span'(172,42,172,44,9130,36)),'src_span'(172,27,172,75,9116,48)).
'bindval'('SYSTEM2_STALL','sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(174,17,174,20,9182,3)),'sharing'('closure'(['free_in','free_out','poll_empty']),'sharing'('closure'(['report_chan']),'|||'('sharing'('closure'(['frame_chan','release_chan']),'val_of'('Camera','src_span'(175,9,175,15,9221,6)),'val_of'('Inference2','src_span'(175,53,175,63,9265,10)),'src_span'(175,16,175,52,9228,36)),'val_of'('MainApp','src_span'(175,69,175,76,9281,7)),'src_span_operator'('no_loc_info_available','src_span'(175,65,175,68,9277,3))),'val_of'('ReporterStall','src_span'(175,102,175,115,9314,13)),'src_span'(175,78,175,101,9290,23)),'val_of'('FREE','src_span'(176,48,176,52,9376,4)),'src_span'(176,6,176,47,9334,41)),'src_span'(174,21,174,47,9186,26)),'src_span'(174,1,176,53,9166,215)).
'assertRef'('False','val_of'('CYCLE','src_span'(178,8,178,13,9390,5)),'Failure','\x5c\'('val_of'('SYSTEM2_STALL','src_span'(178,18,178,31,9400,13)),'agent_call'('src_span'(178,34,178,38,9416,4),'diff',['Events','setExp'('rangeEnum'(['g_trigger_chan']))]),'src_span_operator'('no_loc_info_available','src_span'(178,32,178,33,9414,1))),'src_span'(178,1,178,64,9383,63)).
'comment'('lineComment'('-- Positive controls for Uplink.csp: plausible wrong designs. Each must FAIL its check, showing'),'src_position'(1,1,0,95)).
'comment'('lineComment'('-- that the checks of the real model can detect these faults. The definitions below are those of'),'src_position'(2,1,96,96)).
'comment'('lineComment'('-- Uplink.csp; each control replaces one part of Inference.'),'src_position'(3,1,193,59)).
'comment'('lineComment'('-- no buffer'),'src_position'(8,48,348,12)).
'comment'('lineComment'('-- the frame\x27\s score against the window\x27\s best'),'src_position'(14,48,502,46)).
'comment'('lineComment'('-- frame-ready interrupt -> Camera'),'src_position'(19,48,710,34)).
'comment'('lineComment'('-- Camera -> Inference: frame index, its buffer'),'src_position'(20,48,792,47)).
'comment'('lineComment'('-- Inference -> Camera: raw buffer free, next DMA target'),'src_position'(21,48,887,56)).
'comment'('lineComment'('-- Reporter -> free_chan\x27\s slot'),'src_position'(22,48,991,31)).
'comment'('lineComment'('-- free_chan\x27\s slot -> Inference (poll, value ready)'),'src_position'(23,48,1070,52)).
'comment'('lineComment'('-- free_chan\x27\s slot -> Inference (poll, SKIP taken)'),'src_position'(24,48,1170,51)).
'comment'('lineComment'('-- Camera, Inference, MainApp -> Reporter'),'src_position'(25,48,1269,41)).
'comment'('lineComment'('-- the Reporter\x27\s text lines'),'src_position'(26,48,1358,28)).
'comment'('lineComment'('-- the Reporter sends the JPEG in this buffer'),'src_position'(27,48,1434,45)).
'comment'('lineComment'('-- Inference has scored the frame in this buffer'),'src_position'(28,48,1527,48)).
'comment'('lineComment'('-- Inference merges a window (uplink busy)'),'src_position'(29,48,1623,42)).
'comment'('lineComment'('-- Camera: the next DMA target is buffer 0 at start, then whatever Inference releases.'),'src_position'(37,1,1784,86)).
'comment'('lineComment'('-- Inference: sp = spare buffers, best = the window\x27\s best (NONE if none yet), tok = holds the'),'src_position'(41,1,2052,94)).
'comment'('lineComment'('-- free token, m = windows merged since the last Window line. Per frame: poll free_chan, rescale'),'src_position'(42,1,2147,96)).
'comment'('lineComment'('-- and release a spare as the next DMA target, score, and on a window\x27\s last frame either report'),'src_position'(43,1,2244,96)).
'comment'('lineComment'('-- (token held) or merge.'),'src_position'(44,1,2341,25)).
'comment'('lineComment'('-- free_chan: a one-slot buffered channel. Inference\x27\s PRI ALT with SKIP sees either the value'),'src_position'(75,1,3556,94)).
'comment'('lineComment'('-- (free_out) or an empty slot (poll_empty), never both. A second write to a full slot would'),'src_position'(76,1,3651,92)).
'comment'('lineComment'('-- block the Reporter; overflow marks it.'),'src_position'(77,1,3744,41)).
'comment'('lineComment'('-- MainApp: one stack report per timer tick, over its own writer end.'),'src_position'(81,1,3917,69)).
'comment'('lineComment'('-- Reporter: a text line per text report; for an Image, send the JPEG and return the buffer.'),'src_position'(84,1,4041,92)).
'comment'('lineComment'('-- Buffer roles: an observer that follows each id through the events, from the role it must be'),'src_position'(88,1,4262,94)).
'comment'('lineComment'('-- in to the next one: next (Camera\x27\s DMA target), pending (being scored), best, sending (from the'),'src_position'(89,1,4357,98)).
'comment'('lineComment'('-- Image report until Inference has read it back; slot = in free_chan), and spare. It starts with'),'src_position'(90,1,4456,97)).
'comment'('lineComment'('-- 0 as next and 1..3 spare and moves exactly one id per event, so as long as no event finds an id'),'src_position'(91,1,4554,98)).
'comment'('lineComment'('-- in the wrong role (error), the four ids are always a permutation across the roles.'),'src_position'(92,1,4653,85)).
'comment'('lineComment'('-- Control 1 (must break the buffer roles): Camera may be retargeted to the window\x27\s best. The'),'src_position'(113,1,5968,94)).
'comment'('lineComment'('-- release picks from the spares and the best, as if the best buffer were free; Inference still'),'src_position'(114,1,6063,95)).
'comment'('lineComment'('-- keeps it as the best, so the DMA overwrites the JPEG that may be sent next.'),'src_position'(115,1,6159,78)).
'comment'('lineComment'('-- expected: false'),'src_position'(148,70,7855,18)).
'comment'('lineComment'('-- Control 2 (must stall Camera when the uplink stalls): Inference writes the Window line and'),'src_position'(150,1,7875,93)).
'comment'('lineComment'('-- the Image on every window\x27\s last frame, without waiting for the free token, as Stage 2 did.'),'src_position'(151,1,7969,94)).
'comment'('lineComment'('-- expected: false'),'src_position'(178,68,9450,18)).
'symbol'('W','W','src_span'(5,1,5,2,254,1),'Ident (Groundrep.)').
'symbol'('MAX_INDEX','MAX_INDEX','src_span'(6,1,6,10,268,9),'Ident (Groundrep.)').
'symbol'('IDS','IDS','src_span'(7,1,7,4,282,3),'Ident (Groundrep.)').
'symbol'('NONE','NONE','src_span'(8,1,8,5,301,4),'Ident (Groundrep.)').
'symbol'('MAXM','MAXM','src_span'(9,1,9,5,361,4),'Ident (Groundrep.)').
'symbol'('sat','sat','src_span'(11,1,11,4,376,3),'Funktion or Process').
'symbol'('m','m','src_span'(11,5,11,6,380,1),'Ident (Prolog Variable)').
'symbol'('source_t','source_t','src_span'(13,10,13,18,424,8),'Datatype').
'symbol'('camera','camera','src_span'(13,22,13,28,436,6),'Constructor of Datatype').
'symbol'('inference','inference','src_span'(13,31,13,40,445,9),'Constructor of Datatype').
'symbol'('outcome_t','outcome_t','src_span'(14,10,14,19,464,9),'Datatype').
'symbol'('better','better','src_span'(14,22,14,28,476,6),'Constructor of Datatype').
'symbol'('worse','worse','src_span'(14,31,14,36,485,5),'Constructor of Datatype').
'symbol'('failed','failed','src_span'(14,39,14,45,493,6),'Constructor of Datatype').
'symbol'('report_t','report_t','src_span'(15,10,15,18,558,8),'Datatype').
'symbol'('started','started','src_span'(15,22,15,29,570,7),'Constructor of Datatype').
'symbol'('stack','stack','src_span'(15,41,15,46,589,5),'Constructor of Datatype').
'symbol'('window','window','src_span'(15,49,15,55,597,6),'Constructor of Datatype').
'symbol'('image','image','src_span'(15,68,15,73,616,5),'Constructor of Datatype').
'symbol'('TEXT','TEXT','src_span'(17,1,17,5,627,4),'Ident (Groundrep.)').
'symbol'('diff','diff','src_span'(17,8,17,12,634,4),'BuiltIn primitive').
'symbol'('g_trigger_chan','g_trigger_chan','src_span'(19,9,19,23,671,14),'Channel').
'symbol'('frame_chan','frame_chan','src_span'(20,9,20,19,753,10),'Channel').
'symbol'('release_chan','release_chan','src_span'(21,9,21,21,848,12),'Channel').
'symbol'('free_in','free_in','src_span'(22,9,22,16,952,7),'Channel').
'symbol'('free_out','free_out','src_span'(23,9,23,17,1031,8),'Channel').
'symbol'('poll_empty','poll_empty','src_span'(24,9,24,19,1131,10),'Channel').
'symbol'('report_chan','report_chan','src_span'(25,9,25,20,1230,11),'Channel').
'symbol'('line','line','src_span'(26,9,26,13,1319,4),'Channel').
'symbol'('uplink','uplink','src_span'(27,9,27,15,1395,6),'Channel').
'symbol'('scored','scored','src_span'(28,9,28,15,1488,6),'Channel').
'symbol'('merge','merge','src_span'(29,9,29,14,1584,5),'Channel').
'symbol'('camera_log','camera_log','src_span'(30,9,30,19,1674,10),'Channel').
'symbol'('stack_tick','stack_tick','src_span'(30,21,30,31,1686,10),'Channel').
'symbol'('overflow','overflow','src_span'(31,9,31,17,1705,8),'Channel').
'symbol'('error','error','src_span'(31,19,31,24,1715,5),'Channel').
'symbol'('ENV','ENV','src_span'(33,1,33,4,1722,3),'Ident (Groundrep.)').
'symbol'('RUN','RUN','src_span'(35,1,35,4,1751,3),'Funktion or Process').
'symbol'('A','A','src_span'(35,5,35,6,1755,1),'Ident (Prolog Variable)').
'symbol'('x','x','src_span'(35,13,35,14,1763,1),'Ident (Prolog Variable)').
'symbol'('Camera','Camera','src_span'(38,1,38,7,1871,6),'Ident (Groundrep.)').
'symbol'('CameraLoop','CameraLoop','src_span'(39,1,39,11,1941,10),'Funktion or Process').
'symbol'('i','i','src_span'(39,12,39,13,1952,1),'Ident (Prolog Variable)').
'symbol'('b','b','src_span'(39,15,39,16,1955,1),'Ident (Prolog Variable)').
'symbol'('nb','nb','src_span'(39,69,39,71,2009,2),'Ident (Prolog Variable)').
'symbol'('Inference','Inference','src_span'(45,1,45,10,2367,9),'Ident (Groundrep.)').
'symbol'('i2','i','src_span'(45,24,45,25,2390,1),'Ident (Prolog Variable)').
'symbol'('p','p','src_span'(45,26,45,27,2392,1),'Ident (Prolog Variable)').
'symbol'('Infer','Infer','src_span'(47,1,47,6,2474,5),'Funktion or Process').
'symbol'('i3','i','src_span'(47,7,47,8,2480,1),'Ident (Prolog Variable)').
'symbol'('p2','p','src_span'(47,10,47,11,2483,1),'Ident (Prolog Variable)').
'symbol'('sp','sp','src_span'(47,13,47,15,2486,2),'Ident (Prolog Variable)').
'symbol'('best','best','src_span'(47,17,47,21,2490,4),'Ident (Prolog Variable)').
'symbol'('tok','tok','src_span'(47,23,47,26,2496,3),'Ident (Prolog Variable)').
'symbol'('m2','m','src_span'(47,28,47,29,2501,1),'Ident (Prolog Variable)').
'symbol'('b2','b','src_span'(48,15,48,16,2520,1),'Ident (Prolog Variable)').
'symbol'('union','union','src_span'(48,34,48,39,2539,5),'BuiltIn primitive').
'symbol'('Release','Release','src_span'(51,1,51,8,2627,7),'Funktion or Process').
'symbol'('i4','i','src_span'(51,9,51,10,2635,1),'Ident (Prolog Variable)').
'symbol'('p3','p','src_span'(51,12,51,13,2638,1),'Ident (Prolog Variable)').
'symbol'('sp2','sp','src_span'(51,15,51,17,2641,2),'Ident (Prolog Variable)').
'symbol'('best2','best','src_span'(51,19,51,23,2645,4),'Ident (Prolog Variable)').
'symbol'('tok2','tok','src_span'(51,25,51,28,2651,3),'Ident (Prolog Variable)').
'symbol'('m3','m','src_span'(51,30,51,31,2656,1),'Ident (Prolog Variable)').
'symbol'('s','s','src_span'(51,39,51,40,2665,1),'Ident (Prolog Variable)').
'symbol'('Score','Score','src_span'(53,1,53,6,2734,5),'Funktion or Process').
'symbol'('i5','i','src_span'(53,7,53,8,2740,1),'Ident (Prolog Variable)').
'symbol'('p4','p','src_span'(53,10,53,11,2743,1),'Ident (Prolog Variable)').
'symbol'('sp3','sp','src_span'(53,13,53,15,2746,2),'Ident (Prolog Variable)').
'symbol'('best3','best','src_span'(53,17,53,21,2750,4),'Ident (Prolog Variable)').
'symbol'('tok3','tok','src_span'(53,23,53,26,2756,3),'Ident (Prolog Variable)').
'symbol'('m4','m','src_span'(53,28,53,29,2761,1),'Ident (Prolog Variable)').
'symbol'('union','union','src_span'(55,36,55,41,2826,5),'BuiltIn primitive').
'symbol'('union','union','src_span'(58,36,58,41,2956,5),'BuiltIn primitive').
'symbol'('union','union','src_span'(59,40,59,45,3026,5),'BuiltIn primitive').
'symbol'('union','union','src_span'(60,39,60,44,3095,5),'BuiltIn primitive').
'symbol'('End','End','src_span'(62,1,62,4,3127,3),'Funktion or Process').
'symbol'('i6','i','src_span'(62,5,62,6,3131,1),'Ident (Prolog Variable)').
'symbol'('sp4','sp','src_span'(62,8,62,10,3134,2),'Ident (Prolog Variable)').
'symbol'('best4','best','src_span'(62,12,62,16,3138,4),'Ident (Prolog Variable)').
'symbol'('tok4','tok','src_span'(62,18,62,21,3144,3),'Ident (Prolog Variable)').
'symbol'('m5','m','src_span'(62,23,62,24,3149,1),'Ident (Prolog Variable)').
'symbol'('Next','Next','src_span'(73,1,73,5,3482,4),'Funktion or Process').
'symbol'('sp5','sp','src_span'(73,6,73,8,3487,2),'Ident (Prolog Variable)').
'symbol'('best5','best','src_span'(73,10,73,14,3491,4),'Ident (Prolog Variable)').
'symbol'('tok5','tok','src_span'(73,16,73,19,3497,3),'Ident (Prolog Variable)').
'symbol'('m6','m','src_span'(73,21,73,22,3502,1),'Ident (Prolog Variable)').
'symbol'('j','j','src_span'(73,37,73,38,3518,1),'Ident (Prolog Variable)').
'symbol'('p5','p','src_span'(73,39,73,40,3520,1),'Ident (Prolog Variable)').
'symbol'('FREE','FREE','src_span'(78,1,78,5,3786,4),'Ident (Groundrep.)').
'symbol'('b3','b','src_span'(78,17,78,18,3802,1),'Ident (Prolog Variable)').
'symbol'('FREE_FULL','FREE_FULL','src_span'(79,1,79,10,3845,9),'Funktion or Process').
'symbol'('b4','b','src_span'(79,11,79,12,3855,1),'Ident (Prolog Variable)').
'symbol'('x2','x','src_span'(79,49,79,50,3893,1),'Ident (Prolog Variable)').
'symbol'('MainApp','MainApp','src_span'(82,1,82,8,3987,7),'Ident (Groundrep.)').
'symbol'('Reporter','Reporter','src_span'(85,1,85,9,4134,8),'Ident (Groundrep.)').
'symbol'('r','r','src_span'(85,25,85,26,4158,1),'Ident (Prolog Variable)').
'symbol'('b5','b','src_span'(86,34,86,35,4221,1),'Ident (Prolog Variable)').
'symbol'('OBS','OBS','src_span'(93,1,93,4,4739,3),'Funktion or Process').
'symbol'('cam','cam','src_span'(93,5,93,8,4743,3),'Ident (Prolog Variable)').
'symbol'('pend','pend','src_span'(93,10,93,14,4748,4),'Ident (Prolog Variable)').
'symbol'('best6','best','src_span'(93,16,93,20,4754,4),'Ident (Prolog Variable)').
'symbol'('sp6','sp','src_span'(93,22,93,24,4760,2),'Ident (Prolog Variable)').
'symbol'('send','send','src_span'(93,26,93,30,4764,4),'Ident (Prolog Variable)').
'symbol'('slot','slot','src_span'(93,32,93,36,4770,4),'Ident (Prolog Variable)').
'symbol'('i7','i','src_span'(94,17,94,18,4794,1),'Ident (Prolog Variable)').
'symbol'('b6','b','src_span'(94,19,94,20,4796,1),'Ident (Prolog Variable)').
'symbol'('b7','b','src_span'(95,19,95,20,4893,1),'Ident (Prolog Variable)').
'symbol'('member','member','src_span'(95,61,95,67,4935,6),'BuiltIn primitive').
'symbol'('o','o','src_span'(97,13,97,14,5057,1),'Ident (Prolog Variable)').
'symbol'('b8','b','src_span'(97,15,97,16,5059,1),'Ident (Prolog Variable)').
'symbol'('union','union','src_span'(99,73,99,78,5209,5),'BuiltIn primitive').
'symbol'('b9','b','src_span'(101,24,101,25,5339,1),'Ident (Prolog Variable)').
'symbol'('b133','b','src_span'(103,14,103,15,5494,1),'Ident (Prolog Variable)').
'symbol'('b134','b','src_span'(104,15,104,16,5587,1),'Ident (Prolog Variable)').
'symbol'('union','union','src_span'(104,60,104,65,5632,5),'BuiltIn primitive').
'symbol'('ROLE_EVENTS','ROLE_EVENTS','src_span'(106,1,106,12,5682,11),'Ident (Groundrep.)').
'symbol'('ReporterStall','ReporterStall','src_span'(108,1,108,14,5774,13),'Ident (Groundrep.)').
'symbol'('r2','r','src_span'(108,30,108,31,5803,1),'Ident (Prolog Variable)').
'symbol'('b136','b','src_span'(109,39,109,40,5876,1),'Ident (Prolog Variable)').
'symbol'('CYCLE','CYCLE','src_span'(111,1,111,6,5935,5),'Ident (Groundrep.)').
'symbol'('Release1','Release1','src_span'(116,1,116,9,6238,8),'Funktion or Process').
'symbol'('i8','i','src_span'(116,10,116,11,6247,1),'Ident (Prolog Variable)').
'symbol'('p6','p','src_span'(116,13,116,14,6250,1),'Ident (Prolog Variable)').
'symbol'('sp7','sp','src_span'(116,16,116,18,6253,2),'Ident (Prolog Variable)').
'symbol'('best7','best','src_span'(116,20,116,24,6257,4),'Ident (Prolog Variable)').
'symbol'('tok6','tok','src_span'(116,26,116,29,6263,3),'Ident (Prolog Variable)').
'symbol'('m7','m','src_span'(116,31,116,32,6268,1),'Ident (Prolog Variable)').
'symbol'('s2','s','src_span'(117,9,117,10,6281,1),'Ident (Prolog Variable)').
'symbol'('union','union','src_span'(117,13,117,18,6285,5),'BuiltIn primitive').
'symbol'('Inference1','Inference1','src_span'(119,1,119,11,6402,10),'Ident (Groundrep.)').
'symbol'('i9','i','src_span'(119,25,119,26,6426,1),'Ident (Prolog Variable)').
'symbol'('p7','p','src_span'(119,27,119,28,6428,1),'Ident (Prolog Variable)').
'symbol'('Infer1','Infer1','src_span'(120,1,120,7,6510,6),'Funktion or Process').
'symbol'('i146','i','src_span'(120,8,120,9,6517,1),'Ident (Prolog Variable)').
'symbol'('p8','p','src_span'(120,11,120,12,6520,1),'Ident (Prolog Variable)').
'symbol'('sp8','sp','src_span'(120,14,120,16,6523,2),'Ident (Prolog Variable)').
'symbol'('best8','best','src_span'(120,18,120,22,6527,4),'Ident (Prolog Variable)').
'symbol'('tok7','tok','src_span'(120,24,120,27,6533,3),'Ident (Prolog Variable)').
'symbol'('m8','m','src_span'(120,29,120,30,6538,1),'Ident (Prolog Variable)').
'symbol'('b152','b','src_span'(121,15,121,16,6557,1),'Ident (Prolog Variable)').
'symbol'('union','union','src_span'(121,35,121,40,6577,5),'BuiltIn primitive').
'symbol'('Score1','Score1','src_span'(123,1,123,7,6665,6),'Funktion or Process').
'symbol'('i153','i','src_span'(123,8,123,9,6672,1),'Ident (Prolog Variable)').
'symbol'('p9','p','src_span'(123,11,123,12,6675,1),'Ident (Prolog Variable)').
'symbol'('sp9','sp','src_span'(123,14,123,16,6678,2),'Ident (Prolog Variable)').
'symbol'('best9','best','src_span'(123,18,123,22,6682,4),'Ident (Prolog Variable)').
'symbol'('tok8','tok','src_span'(123,24,123,27,6688,3),'Ident (Prolog Variable)').
'symbol'('m9','m','src_span'(123,29,123,30,6693,1),'Ident (Prolog Variable)').
'symbol'('union','union','src_span'(125,37,125,42,6759,5),'BuiltIn primitive').
'symbol'('union','union','src_span'(128,37,128,42,6891,5),'BuiltIn primitive').
'symbol'('union','union','src_span'(129,41,129,46,6962,5),'BuiltIn primitive').
'symbol'('union','union','src_span'(130,40,130,45,7032,5),'BuiltIn primitive').
'symbol'('End1','End1','src_span'(131,1,131,5,7063,4),'Funktion or Process').
'symbol'('i159','i','src_span'(131,6,131,7,7068,1),'Ident (Prolog Variable)').
'symbol'('sp160','sp','src_span'(131,9,131,11,7071,2),'Ident (Prolog Variable)').
'symbol'('best161','best','src_span'(131,13,131,17,7075,4),'Ident (Prolog Variable)').
'symbol'('tok9','tok','src_span'(131,19,131,22,7081,3),'Ident (Prolog Variable)').
'symbol'('m163','m','src_span'(131,24,131,25,7086,1),'Ident (Prolog Variable)').
'symbol'('Next1','Next1','src_span'(141,1,141,6,7422,5),'Funktion or Process').
'symbol'('sp164','sp','src_span'(141,7,141,9,7428,2),'Ident (Prolog Variable)').
'symbol'('best165','best','src_span'(141,11,141,15,7432,4),'Ident (Prolog Variable)').
'symbol'('tok166','tok','src_span'(141,17,141,20,7438,3),'Ident (Prolog Variable)').
'symbol'('m167','m','src_span'(141,22,141,23,7443,1),'Ident (Prolog Variable)').
'symbol'('j2','j','src_span'(141,38,141,39,7459,1),'Ident (Prolog Variable)').
'symbol'('p169','p','src_span'(141,40,141,41,7461,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM1','SYSTEM1','src_span'(143,1,143,8,7498,7),'Ident (Groundrep.)').
'symbol'('SYSTEM1_OBS','SYSTEM1_OBS','src_span'(146,1,146,12,7703,11),'Ident (Groundrep.)').
'symbol'('End2','End2','src_span'(152,1,152,5,8064,4),'Funktion or Process').
'symbol'('i170','i','src_span'(152,6,152,7,8069,1),'Ident (Prolog Variable)').
'symbol'('sp171','sp','src_span'(152,9,152,11,8072,2),'Ident (Prolog Variable)').
'symbol'('best172','best','src_span'(152,13,152,17,8076,4),'Ident (Prolog Variable)').
'symbol'('tok173','tok','src_span'(152,19,152,22,8082,3),'Ident (Prolog Variable)').
'symbol'('m174','m','src_span'(152,24,152,25,8087,1),'Ident (Prolog Variable)').
'symbol'('Inference2','Inference2','src_span'(159,1,159,11,8321,10),'Ident (Groundrep.)').
'symbol'('i175','i','src_span'(159,25,159,26,8345,1),'Ident (Prolog Variable)').
'symbol'('p176','p','src_span'(159,27,159,28,8347,1),'Ident (Prolog Variable)').
'symbol'('Infer2','Infer2','src_span'(160,1,160,7,8429,6),'Funktion or Process').
'symbol'('i177','i','src_span'(160,8,160,9,8436,1),'Ident (Prolog Variable)').
'symbol'('p178','p','src_span'(160,11,160,12,8439,1),'Ident (Prolog Variable)').
'symbol'('sp179','sp','src_span'(160,14,160,16,8442,2),'Ident (Prolog Variable)').
'symbol'('best180','best','src_span'(160,18,160,22,8446,4),'Ident (Prolog Variable)').
'symbol'('tok181','tok','src_span'(160,24,160,27,8452,3),'Ident (Prolog Variable)').
'symbol'('m182','m','src_span'(160,29,160,30,8457,1),'Ident (Prolog Variable)').
'symbol'('b183','b','src_span'(161,15,161,16,8476,1),'Ident (Prolog Variable)').
'symbol'('union','union','src_span'(161,35,161,40,8496,5),'BuiltIn primitive').
'symbol'('Release2','Release2','src_span'(163,1,163,9,8584,8),'Funktion or Process').
'symbol'('i184','i','src_span'(163,10,163,11,8593,1),'Ident (Prolog Variable)').
'symbol'('p185','p','src_span'(163,13,163,14,8596,1),'Ident (Prolog Variable)').
'symbol'('sp186','sp','src_span'(163,16,163,18,8599,2),'Ident (Prolog Variable)').
'symbol'('best187','best','src_span'(163,20,163,24,8603,4),'Ident (Prolog Variable)').
'symbol'('tok188','tok','src_span'(163,26,163,29,8609,3),'Ident (Prolog Variable)').
'symbol'('m189','m','src_span'(163,31,163,32,8614,1),'Ident (Prolog Variable)').
'symbol'('s3','s','src_span'(163,40,163,41,8623,1),'Ident (Prolog Variable)').
'symbol'('Score2','Score2','src_span'(164,1,164,7,8692,6),'Funktion or Process').
'symbol'('i191','i','src_span'(164,8,164,9,8699,1),'Ident (Prolog Variable)').
'symbol'('p192','p','src_span'(164,11,164,12,8702,1),'Ident (Prolog Variable)').
'symbol'('sp193','sp','src_span'(164,14,164,16,8705,2),'Ident (Prolog Variable)').
'symbol'('best194','best','src_span'(164,18,164,22,8709,4),'Ident (Prolog Variable)').
'symbol'('tok195','tok','src_span'(164,24,164,27,8715,3),'Ident (Prolog Variable)').
'symbol'('m196','m','src_span'(164,29,164,30,8720,1),'Ident (Prolog Variable)').
'symbol'('union','union','src_span'(166,37,166,42,8786,5),'BuiltIn primitive').
'symbol'('union','union','src_span'(169,37,169,42,8918,5),'BuiltIn primitive').
'symbol'('union','union','src_span'(170,41,170,46,8989,5),'BuiltIn primitive').
'symbol'('union','union','src_span'(171,40,171,45,9059,5),'BuiltIn primitive').
'symbol'('Next2','Next2','src_span'(172,1,172,6,9090,5),'Funktion or Process').
'symbol'('sp197','sp','src_span'(172,7,172,9,9096,2),'Ident (Prolog Variable)').
'symbol'('best198','best','src_span'(172,11,172,15,9100,4),'Ident (Prolog Variable)').
'symbol'('tok199','tok','src_span'(172,17,172,20,9106,3),'Ident (Prolog Variable)').
'symbol'('m200','m','src_span'(172,22,172,23,9111,1),'Ident (Prolog Variable)').
'symbol'('j3','j','src_span'(172,38,172,39,9127,1),'Ident (Prolog Variable)').
'symbol'('p202','p','src_span'(172,40,172,41,9129,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM2_STALL','SYSTEM2_STALL','src_span'(174,1,174,14,9166,13),'Ident (Groundrep.)').