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
'bindval'('W','int'(2),'src_span'(11,1,11,14,713,13)).
'bindval'('IDS','setExp'('rangeClosed'('int'(0),'int'(3))),'src_span'(12,1,12,19,727,18)).
'bindval'('NONE','int'(4),'src_span'(13,1,13,14,746,13)).
'bindval'('MAXM','int'(2),'src_span'(14,1,14,14,806,13)).
'agent'('sat'(_m),'ifte'('>'(_m,'val_of'('MAXM','src_span'(16,17,16,21,837,4))),'val_of'('MAXM','src_span'(16,27,16,31,847,4)),_m,'src_span'(16,10,16,21,830,11),'src_span'(16,22,16,26,841,18),'src_span'(16,32,16,36,851,11)),'src_span'(16,10,16,38,830,28)).
'dataTypeDef'('source_t',['constructor'('camera'),'constructor'('inference'),'constructor'('filesource')]).
'dataTypeDef'('kind_t',['constructor'('img'),'constructor'('eos')]).
'dataTypeDef'('outcome_t',['constructor'('better'),'constructor'('worse'),'constructor'('failed')]).
'dataTypeDef'('report_t',['constructorC'('started','dotTupleType'(['source_t'])),'constructor'('stack'),'constructor'('srcmsg'),'constructor'('scores'),'constructorC'('window','dotTupleType'(['setExp'('rangeClosed'('int'(0),'val_of'('MAXM','src_span'(21,78,21,82,1066,4))))])),'constructorC'('wimage','dotTupleType'(['setExp'('rangeClosed'('int'(0),'val_of'('MAXM','src_span'(21,97,21,101,1085,4)))),'val_of'('IDS','src_span'(21,103,21,106,1091,3))]))]).
'bindval'('INF_TEXT','agent_call'('src_span'(23,12,23,17,1107,5),'union',['setExp'('rangeEnum'(['scores'])),'setExp'('rangeEnum'(['dotTuple'(['window',_m2])]),['comprehensionGenerator'(_m2,'setExp'('rangeClosed'('int'(0),'val_of'('MAXM','src_span'(23,49,23,53,1144,4)))))])]),'src_span'(23,1,23,56,1096,55)).
'bindval'('OTHER','setExp'('rangeEnum'(['dotTuple'(['started','camera']),'dotTuple'(['started','inference']),'dotTuple'(['started','filesource']),'stack','srcmsg'])),'src_span'(24,1,24,82,1200,81)).
'channel'('g_trigger_chan','type'('dotUnitType')).
'channel'('frame_chan','type'('dotTupleType'(['val_of'('IDS','src_span'(27,24,27,27,1388,3)),'kind_t']))).
'channel'('release_chan','type'('dotTupleType'(['val_of'('IDS','src_span'(28,24,28,27,1487,3))]))).
'channel'('free_in','type'('dotTupleType'(['val_of'('IDS','src_span'(29,24,29,27,1582,3))]))).
'channel'('free_out','type'('dotTupleType'(['val_of'('IDS','src_span'(30,24,30,27,1661,3))]))).
'channel'('poll_empty','type'('dotUnitType')).
'channel'('ready_in','type'('dotUnitType')).
'channel'('ready_out','type'('dotUnitType')).
'channel'('ready_empty','type'('dotUnitType')).
'channel'('report_chan','type'('dotTupleType'(['report_t']))).
'channel'('line','type'('dotTupleType'(['report_t']))).
'channel'('uplink','type'('dotTupleType'(['val_of'('IDS','src_span'(37,24,37,27,2271,3))]))).
'channel'('scored','type'('dotTupleType'(['outcome_t','val_of'('IDS','src_span'(38,34,38,37,2374,3))]))).
'channel'('suppress','type'('dotTupleType'(['val_of'('IDS','src_span'(39,24,39,27,2460,3))]))).
'channel'('merge','type'('dotUnitType')).
'channel'('fs_read','type'('dotUnitType')).
'channel'('fs_restart','type'('dotUnitType')).
'channel'('camera_log','type'('dotUnitType')).
'channel'('stack_tick','type'('dotUnitType')).
'channel'('overflow','type'('dotUnitType')).
'channel'('error','type'('dotUnitType')).
'bindval'('ENV','prefix'('src_span'(46,7,46,21,2867,14),[],'g_trigger_chan','val_of'('ENV','src_span'(46,25,46,28,2885,3)),'src_span'(46,22,46,24,2881,21)),'src_span'(46,1,46,28,2861,27)).
'agent'('RUN'(_A),'repChoice'(['comprehensionGenerator'(_x,_A)],'prefix'('src_span'(48,21,48,22,2910,1),[],_x,'agent_call'('src_span'(48,26,48,29,2915,3),'RUN',[_A]),'src_span'(48,23,48,25,2911,11)),'src_span'(48,13,48,20,2902,7)),'src_span'(48,10,48,32,2899,22)).
'bindval'('Camera','prefix'('src_span'(52,10,52,20,3105,10),[],'camera_log','prefix'('src_span'(52,24,52,35,3119,11),['out'('dotTuple'(['started','camera']))],'report_chan','agent_call'('src_span'(52,54,52,64,3149,10),'CameraLoop',['int'(0)]),'src_span'(52,51,52,53,3145,32)),'src_span'(52,21,52,23,3115,57)),'src_span'(52,1,52,67,3096,66)).
'agent'('CameraLoop'(_b),'prefix'('src_span'(53,17,53,31,3179,14),[],'g_trigger_chan','prefix'('src_span'(53,35,53,45,3197,10),['out'(_b),'out'('img')],'frame_chan','prefix'('src_span'(53,55,53,67,3217,12),['in'(_nb)],'release_chan','agent_call'('src_span'(53,74,53,84,3236,10),'CameraLoop',[_nb]),'src_span'(53,71,53,73,3232,21)),'src_span'(53,52,53,54,3213,41)),'src_span'(53,32,53,34,3193,71)),'src_span'(53,17,53,88,3179,71)).
'bindval'('FileSource','prefix'('src_span'(61,14,61,25,3846,11),['out'('dotTuple'(['started','filesource']))],'report_chan','agent_call'('src_span'(61,48,61,50,3880,2),'FS',['int'(0)]),'src_span'(61,45,61,47,3876,28)),'src_span'(61,1,61,53,3833,52)).
'agent'('FS'(_b2),'|~|'('prefix'('src_span'(62,10,62,21,3895,11),['out'('srcmsg')],'report_chan','agent_call'('src_span'(62,32,62,39,3917,7),'FSFrame',[_b2]),'src_span'(62,29,62,31,3913,21)),'agent_call'('src_span'(62,48,62,55,3933,7),'FSFrame',[_b2]),'src_span_operator'('no_loc_info_available','src_span'(62,44,62,47,3929,3))),'no_loc_info_available').
'agent'('FSFrame'(_b3),'|~|'('prefix'('src_span'(63,15,63,22,3958,7),[],'fs_read','prefix'('src_span'(63,26,63,36,3969,10),['out'(_b3),'out'('img')],'frame_chan','prefix'('src_span'(63,46,63,58,3989,12),['in'(_nb2)],'release_chan','agent_call'('src_span'(63,65,63,67,4008,2),'FS',[_nb2]),'src_span'(63,62,63,64,4004,13)),'src_span'(63,43,63,45,3985,33)),'src_span'(63,23,63,25,3965,56)),'prefix'('src_span'(64,19,64,29,4034,10),['out'(_b3),'out'('eos')],'frame_chan','prefix'('src_span'(64,39,64,51,4054,12),['in'(_nb3)],'release_chan','prefix'('src_span'(64,58,64,69,4073,11),['out'('srcmsg')],'report_chan','prefix'('src_span'(64,80,64,90,4095,10),[],'fs_restart','prefix'('src_span'(65,19,65,30,4127,11),['out'('dotTuple'(['started','filesource']))],'report_chan','agent_call'('src_span'(65,53,65,55,4161,2),'FS',[_nb3]),'src_span'(65,50,65,52,4157,29)),'src_span'(64,91,65,18,4105,72)),'src_span'(64,77,64,79,4091,83)),'src_span'(64,55,64,57,4069,101)),'src_span'(64,36,64,38,4050,121)),'src_span_operator'('no_loc_info_available','src_span'(64,14,64,17,4029,3))),'no_loc_info_available').
'bindval'('Inference','prefix'('src_span'(70,13,70,23,4471,10),['in'(_p),'in'(_k)],'frame_chan','prefix'('src_span'(70,31,70,42,4489,11),['out'('dotTuple'(['started','inference']))],'report_chan','agent_call'('src_span'(70,64,70,69,4522,5),'Infer',['int'(0),_p,_k,'agent_call'('src_span'(70,79,70,83,4537,4),'diff',['val_of'('IDS','src_span'(70,84,70,87,4542,3)),'setExp'('rangeEnum'([_p]))]),'val_of'('NONE','src_span'(70,95,70,99,4553,4)),'true','true','int'(0),'false']),'src_span'(70,61,70,63,4518,80)),'src_span'(70,28,70,30,4485,97)),'src_span'(70,1,70,122,4459,121)).
'agent'('Infer'(_pos,_p2,_k2,_sp,_best,_tok,_rdy,_m3,_sc),'[]'('prefix'('src_span'(73,6,73,14,4633,8),['in'(_b4)],'free_out','agent_call'('src_span'(73,20,73,29,4647,9),'PollReady',[_pos,_p2,_k2,'agent_call'('src_span'(73,41,73,46,4668,5),'union',[_sp,'setExp'('rangeEnum'([_b4]))]),_best,'true',_rdy,_m3,_sc]),'src_span'(73,17,73,19,4643,66)),'prefix'('src_span'(74,9,74,19,4717,10),[],'poll_empty','agent_call'('src_span'(74,23,74,32,4731,9),'PollReady',[_pos,_p2,_k2,_sp,_best,_tok,_rdy,_m3,_sc]),'src_span'(74,20,74,22,4727,61)),'src_span_operator'('no_loc_info_available','src_span'(74,5,74,7,4713,2))),'no_loc_info_available').
'agent'('PollReady'(_pos2,_p3,_k3,_sp2,_best2,_tok2,_rdy2,_m4,_sc2),'[]'('prefix'('src_span'(77,6,77,15,4836,9),[],'ready_out','agent_call'('src_span'(77,19,77,27,4849,8),'Dispatch',[_pos2,_p3,_k3,_sp2,_best2,_tok2,'true',_m4,_sc2]),'src_span'(77,16,77,18,4845,60)),'prefix'('src_span'(78,9,78,20,4906,11),[],'ready_empty','agent_call'('src_span'(78,24,78,32,4921,8),'Dispatch',[_pos2,_p3,_k3,_sp2,_best2,_tok2,_rdy2,_m4,_sc2]),'src_span'(78,21,78,23,4917,61)),'src_span_operator'('no_loc_info_available','src_span'(78,5,78,7,4902,2))),'no_loc_info_available').
'agent'('Dispatch'(_pos3,_p4,_k4,_sp3,_best3,_tok3,_rdy3,_m5,_sc3),'ifte'('=='(_k4,'img'),'agent_call'('src_span'(81,22,81,29,5040,7),'Release',[_pos3,_p4,_sp3,_best3,_tok3,_rdy3,_m5,_sc3]),'prefix'('src_span'(82,10,82,22,5092,12),['out'(_p4)],'release_chan','agent_call'('src_span'(82,28,82,33,5110,5),'Flush',[_pos3,_sp3,_best3,_tok3,_rdy3,_m5,_sc3]),'src_span'(82,25,82,27,5106,43)),'no_loc_info_available','no_loc_info_available','src_span'(81,65,82,9,5082,107)),'src_span'(81,5,82,65,5023,124)).
'agent'('Release'(_pos4,_p5,_sp4,_best4,_tok4,_rdy4,_m6,_sc4),'repInternalChoice'(['comprehensionGenerator'(_s,_sp4)],'prefix'('src_span'(85,18,85,30,5211,12),['out'(_s)],'release_chan','agent_call'('src_span'(85,36,85,41,5229,5),'Score',[_pos4,_p5,'agent_call'('src_span'(85,50,85,54,5243,4),'diff',[_sp4,'setExp'('rangeEnum'([_s]))]),_best4,_tok4,_rdy4,_m6,_sc4]),'src_span'(85,33,85,35,5225,57)),'src_span'(85,9,85,17,5202,8)),'src_span'(85,5,85,87,5198,82)).
'agent'('Score'(_pos5,_p6,_sp5,_best5,_tok5,_rdy5,_m7,_sc5),'ifte'('=='(_best5,'val_of'('NONE','src_span'(88,16,88,20,5340,4))),'|~|'('prefix'('src_span'(89,10,89,16,5359,6),['out'('failed'),'out'(_p6)],'scored','agent_call'('src_span'(89,29,89,32,5378,3),'End',[_pos5,'agent_call'('src_span'(89,38,89,43,5387,5),'union',[_sp5,'setExp'('rangeEnum'([_p6]))]),_best5,_tok5,_rdy5,_m7]),'src_span'(89,26,89,28,5374,49)),'prefix'('src_span'(90,14,90,20,5436,6),['out'('better'),'out'(_p6)],'scored','agent_call'('src_span'(90,33,90,36,5455,3),'End',[_pos5,_sp5,_p6,_tok5,_rdy5,_m7]),'src_span'(90,30,90,32,5451,34)),'src_span_operator'('no_loc_info_available','src_span'(90,9,90,12,5431,3))),'|~|'('|~|'('prefix'('src_span'(92,10,92,16,5503,6),['out'('failed'),'out'(_p6)],'scored','agent_call'('src_span'(92,29,92,32,5522,3),'End',[_pos5,'agent_call'('src_span'(92,38,92,43,5531,5),'union',[_sp5,'setExp'('rangeEnum'([_p6]))]),_best5,_tok5,_rdy5,_m7]),'src_span'(92,26,92,28,5518,49)),'prefix'('src_span'(93,14,93,20,5580,6),['out'('better'),'out'(_p6)],'scored','agent_call'('src_span'(93,33,93,36,5599,3),'End',[_pos5,'agent_call'('src_span'(93,42,93,47,5608,5),'union',[_sp5,'setExp'('rangeEnum'([_best5]))]),_p6,_tok5,_rdy5,_m7]),'src_span'(93,30,93,32,5595,49)),'src_span_operator'('no_loc_info_available','src_span'(93,9,93,12,5575,3))),'prefix'('src_span'(94,14,94,20,5657,6),['out'('worse'),'out'(_p6)],'scored','agent_call'('src_span'(94,32,94,35,5675,3),'End',[_pos5,'agent_call'('src_span'(94,41,94,46,5684,5),'union',[_sp5,'setExp'('rangeEnum'([_p6]))]),_best5,_tok5,_rdy5,_m7]),'src_span'(94,29,94,31,5671,49)),'src_span_operator'('no_loc_info_available','src_span'(94,9,94,12,5652,3))),'no_loc_info_available','no_loc_info_available','no_loc_info_available'),'src_span'(88,5,94,76,5329,390)).
'agent'('WindowReport'(_sp6,_best6,_tok6,_m8),'ifte'('=='(_best6,'val_of'('NONE','src_span'(99,16,99,20,5919,4))),'prefix'('src_span'(99,26,99,37,5929,11),['out'('dotTuple'(['window',_m8]))],'report_chan','agent_call'('src_span'(99,50,99,54,5953,4),'Next',['int'(0),_sp6,'val_of'('NONE','src_span'(99,62,99,66,5965,4)),_tok6,'false','int'(0),'false']),'src_span'(99,47,99,49,5949,52)),'|~|'('prefix'('src_span'(100,11,100,22,6003,11),['out'('dotTuple'(['wimage',_m8,_best6]))],'report_chan','agent_call'('src_span'(100,40,100,44,6032,4),'Next',['int'(0),_sp6,'val_of'('NONE','src_span'(100,52,100,56,6044,4)),'false','false','int'(0),'false']),'src_span'(100,37,100,39,6028,59)),'prefix'('src_span'(101,15,101,23,6089,8),['out'(_best6)],'suppress','prefix'('src_span'(101,32,101,43,6106,11),['out'('dotTuple'(['window',_m8]))],'report_chan','agent_call'('src_span'(101,56,101,60,6130,4),'Next',['int'(0),'agent_call'('src_span'(101,64,101,69,6138,5),'union',[_sp6,'setExp'('rangeEnum'([_best6]))]),'val_of'('NONE','src_span'(101,83,101,87,6157,4)),_tok6,'false','int'(0),'false']),'src_span'(101,53,101,55,6126,67)),'src_span'(101,29,101,31,6102,87)),'src_span_operator'('no_loc_info_available','src_span'(101,10,101,13,6084,3))),'no_loc_info_available','no_loc_info_available','no_loc_info_available'),'src_span'(99,5,101,111,5908,277)).
'agent'('End'(_pos6,_sp7,_best7,_tok7,_rdy6,_m9),'ifte'(_rdy6,'ifte'('bool_and'('=='(_pos6,'-'('val_of'('W','src_span'(105,19,105,20,6255,1)),'int'(1))),_tok7),'agent_call'('src_span'(105,38,105,50,6274,12),'WindowReport',[_sp7,_best7,_tok7,_m9]),'ifte'('=='(_pos6,'-'('val_of'('W','src_span'(106,24,106,25,6328,1)),'int'(1))),'prefix'('src_span'(107,13,107,18,6351,5),[],'merge','prefix'('src_span'(107,22,107,33,6360,11),['out'('scores')],'report_chan','agent_call'('src_span'(107,44,107,48,6382,4),'Next',['int'(0),_sp7,_best7,_tok7,'false','agent_call'('src_span'(107,74,107,77,6412,3),'sat',['+'(_m9,'int'(1))]),'false']),'src_span'(107,41,107,43,6378,59)),'src_span'(107,19,107,21,6356,79)),'prefix'('src_span'(109,13,109,24,6456,11),['out'('scores')],'report_chan','agent_call'('src_span'(109,35,109,39,6478,4),'Next',['+'(_pos6,'int'(1)),_sp7,_best7,_tok7,'false',_m9,'false']),'src_span'(109,32,109,34,6474,56)),'no_loc_info_available','no_loc_info_available','src_span'(107,93,109,12,6430,172)),'no_loc_info_available','no_loc_info_available','src_span'(105,69,106,13,6304,249)),'ifte'('=='(_pos6,'-'('val_of'('W','src_span'(110,20,110,21,6543,1)),'int'(1))),'prefix'('src_span'(111,9,111,14,6562,5),[],'merge','agent_call'('src_span'(111,18,111,22,6571,4),'Next',['int'(0),_sp7,_best7,_tok7,_rdy6,'agent_call'('src_span'(111,46,111,49,6599,3),'sat',['+'(_m9,'int'(1))]),'true']),'src_span'(111,15,111,17,6567,54)),'agent_call'('src_span'(113,9,113,13,6634,4),'Next',['+'(_pos6,'int'(1)),_sp7,_best7,_tok7,_rdy6,_m9,'true']),'no_loc_info_available','no_loc_info_available','src_span'(111,64,113,8,6616,114)),'src_span'(104,5,104,11,6225,6),'src_span'(104,12,105,8,6231,295),'src_span'(109,81,110,9,6523,431)),'src_span'(104,5,113,51,6225,451)).
'agent'('Flush'(_pos7,_sp8,_best8,_tok8,_rdy7,_m169,_sc6),'ifte'('bool_or'('>'(_pos7,'int'(0)),_sc6),'ifte'(_rdy7,'agent_call'('src_span'(121,22,121,32,7130,10),'FlushReady',[_pos7,_sp8,_best8,_tok8,_m169]),'prefix'('src_span'(122,15,122,24,7178,9),[],'ready_out','agent_call'('src_span'(122,28,122,38,7191,10),'FlushReady',[_pos7,_sp8,_best8,_tok8,_m169]),'src_span'(122,25,122,27,7187,46)),'src_span'(121,10,121,16,7118,6),'src_span'(121,17,121,21,7124,42),'src_span'(121,56,122,14,7163,94)),'agent_call'('src_span'(123,10,123,14,7235,4),'Next',['int'(0),_sp8,_best8,_tok8,_rdy7,_m169,'false']),'src_span'(120,5,120,21,7087,16),'src_span'(120,22,121,8,7103,135),'src_span'(122,63,123,9,7225,155)),'src_span'(120,5,123,47,7087,185)).
'agent'('FlushReady'(_pos8,_sp9,_best9,_tok9,_m175),'ifte'('>'(_pos8,'int'(0)),'ifte'(_tok9,'agent_call'('src_span'(127,22,127,34,7351,12),'WindowReport',[_sp9,_best9,_tok9,_m175]),'prefix'('src_span'(128,15,128,23,7396,8),['in'(_b5)],'free_out','agent_call'('src_span'(128,29,128,41,7410,12),'WindowReport',['agent_call'('src_span'(128,42,128,47,7423,5),'union',[_sp9,'setExp'('rangeEnum'([_b5]))]),_best9,'true',_m175]),'src_span'(128,26,128,28,7406,49)),'src_span'(127,10,127,16,7339,6),'src_span'(127,17,127,21,7345,39),'src_span'(127,53,128,14,7381,102)),'prefix'('src_span'(129,10,129,21,7464,11),['out'('scores')],'report_chan','agent_call'('src_span'(129,32,129,36,7486,4),'Next',['int'(0),_sp9,_best9,_tok9,'false',_m175,'false']),'src_span'(129,29,129,31,7482,50)),'src_span'(126,5,126,15,7314,10),'src_span'(126,16,127,8,7324,137),'src_span'(128,74,129,9,7454,187)),'src_span'(126,5,129,71,7314,211)).
'agent'('Next'(_pos9,_sp178,_best179,_tok180,_rdy8,_m182,_sc7),'prefix'('src_span'(131,40,131,50,7566,10),['in'(_p7),'in'(_k5)],'frame_chan','agent_call'('src_span'(131,58,131,63,7584,5),'Infer',[_pos9,_p7,_k5,_sp178,_best179,_tok180,_rdy8,_m182,_sc7]),'src_span'(131,55,131,57,7580,49)),'src_span'(131,40,131,101,7566,61)).
'bindval'('FREE','[]'('prefix'('src_span'(135,9,135,16,7822,7),['in'(_b6)],'free_in','agent_call'('src_span'(135,22,135,31,7835,9),'FREE_FULL',[_b6]),'src_span'(135,19,135,21,7831,18)),'prefix'('src_span'(135,40,135,50,7853,10),[],'poll_empty','val_of'('FREE','src_span'(135,54,135,58,7867,4)),'src_span'(135,51,135,53,7863,18)),'src_span_operator'('no_loc_info_available','src_span'(135,36,135,38,7849,2))),'src_span'(135,1,135,59,7814,58)).
'agent'('FREE_FULL'(_b7),'[]'('prefix'('src_span'(136,17,136,25,7889,8),['out'(_b7)],'free_out','val_of'('FREE','src_span'(136,31,136,35,7903,4)),'src_span'(136,28,136,30,7899,10)),'prefix'('src_span'(136,41,136,48,7913,7),['in'(_x2)],'free_in','prefix'('src_span'(136,54,136,62,7926,8),[],'overflow','stop'('src_span'(136,66,136,70,7938,4)),'src_span'(136,63,136,65,7934,16)),'src_span'(136,51,136,53,7922,22)),'src_span_operator'('no_loc_info_available','src_span'(136,37,136,39,7909,2))),'no_loc_info_available').
'bindval'('READY','[]'('prefix'('src_span'(138,10,138,18,7954,8),[],'ready_in','val_of'('READY_FULL','src_span'(138,22,138,32,7966,10)),'src_span'(138,19,138,21,7962,22)),'prefix'('src_span'(138,38,138,49,7982,11),[],'ready_empty','val_of'('READY','src_span'(138,53,138,58,7997,5)),'src_span'(138,50,138,52,7993,20)),'src_span_operator'('no_loc_info_available','src_span'(138,34,138,36,7978,2))),'src_span'(138,1,138,59,7945,58)).
'bindval'('READY_FULL','[]'('prefix'('src_span'(139,15,139,24,8018,9),[],'ready_out','val_of'('READY','src_span'(139,28,139,33,8031,5)),'src_span'(139,25,139,27,8027,18)),'prefix'('src_span'(139,39,139,47,8042,8),[],'ready_in','prefix'('src_span'(139,51,139,59,8054,8),[],'overflow','stop'('src_span'(139,63,139,67,8066,4)),'src_span'(139,60,139,62,8062,16)),'src_span'(139,48,139,50,8050,28)),'src_span_operator'('no_loc_info_available','src_span'(139,35,139,37,8038,2))),'src_span'(139,1,139,68,8004,67)).
'bindval'('MainApp','prefix'('src_span'(141,11,141,21,8083,10),[],'stack_tick','prefix'('src_span'(141,25,141,36,8097,11),['out'('stack')],'report_chan','val_of'('MainApp','src_span'(141,46,141,53,8118,7)),'src_span'(141,43,141,45,8114,17)),'src_span'(141,22,141,24,8093,42)),'src_span'(141,1,141,53,8073,52)).
'agent'('MainAppN'(_n),'ifte'('=='(_n,'int'(0)),'stop'('src_span'(142,30,142,34,8155,4)),'prefix'('src_span'(142,40,142,50,8165,10),[],'stack_tick','prefix'('src_span'(142,54,142,65,8179,11),['out'('stack')],'report_chan','agent_call'('src_span'(142,75,142,83,8200,8),'MainAppN',['-'(_n,'int'(1))]),'src_span'(142,72,142,74,8196,25)),'src_span'(142,51,142,53,8175,50)),'no_loc_info_available','no_loc_info_available','src_span'(142,35,142,39,8159,60)),'src_span'(142,15,142,90,8140,75)).
'bindval'('Reporter','[]'('[]'('prefix'('src_span'(145,13,145,24,8316,11),['inGuard'(_r,'val_of'('INF_TEXT','src_span'(145,27,145,35,8330,8)))],'report_chan','prefix'('src_span'(145,39,145,43,8342,4),['out'(_r)],'line','prefix'('src_span'(145,49,145,57,8352,8),[],'ready_in','val_of'('Reporter','src_span'(145,61,145,69,8364,8)),'src_span'(145,58,145,60,8360,20)),'src_span'(145,46,145,48,8348,26)),'src_span'(145,36,145,38,8338,45)),'prefix'('src_span'(146,16,146,27,8389,11),['inGuard'(_r2,'val_of'('OTHER','src_span'(146,30,146,35,8403,5)))],'report_chan','prefix'('src_span'(146,39,146,43,8412,4),['out'(_r2)],'line','val_of'('Reporter','src_span'(146,49,146,57,8422,8)),'src_span'(146,46,146,48,8418,14)),'src_span'(146,36,146,38,8408,30)),'src_span_operator'('no_loc_info_available','src_span'(146,12,146,14,8385,2))),'prefix'('src_span'(147,16,147,34,8447,18),['in'(_m192),'in'(_b8)],'dotTuple'(['report_chan','wimage']),'prefix'('src_span'(147,42,147,46,8473,4),['out'('dotTuple'(['window',_m192]))],'line','prefix'('src_span'(147,59,147,65,8490,6),['out'(_b8)],'uplink','prefix'('src_span'(147,71,147,78,8502,7),['out'(_b8)],'free_in','prefix'('src_span'(147,84,147,92,8515,8),[],'ready_in','val_of'('Reporter','src_span'(147,96,147,104,8527,8)),'src_span'(147,93,147,95,8523,20)),'src_span'(147,81,147,83,8511,26)),'src_span'(147,68,147,70,8498,39)),'src_span'(147,56,147,58,8486,58)),'src_span'(147,39,147,41,8469,68)),'src_span_operator'('no_loc_info_available','src_span'(147,12,147,14,8443,2))),'src_span'(145,1,147,105,8304,232)).
'bindval'('ReporterStall','[]'('[]'('prefix'('src_span'(149,18,149,29,8555,11),['inGuard'(_r3,'val_of'('INF_TEXT','src_span'(149,32,149,40,8569,8)))],'report_chan','prefix'('src_span'(149,44,149,48,8581,4),['out'(_r3)],'line','|~|'('prefix'('src_span'(149,56,149,64,8593,8),[],'ready_in','val_of'('ReporterStall','src_span'(149,68,149,81,8605,13)),'src_span'(149,65,149,67,8601,25)),'stop'('src_span'(149,87,149,91,8624,4)),'src_span_operator'('no_loc_info_available','src_span'(149,83,149,86,8620,3))),'src_span'(149,51,149,53,8587,44)),'src_span'(149,41,149,43,8577,63)),'prefix'('src_span'(150,21,150,32,8651,11),['inGuard'(_r4,'val_of'('OTHER','src_span'(150,35,150,40,8665,5)))],'report_chan','prefix'('src_span'(150,44,150,48,8674,4),['out'(_r4)],'line','val_of'('ReporterStall','src_span'(150,54,150,67,8684,13)),'src_span'(150,51,150,53,8680,19)),'src_span'(150,41,150,43,8670,35)),'src_span_operator'('no_loc_info_available','src_span'(150,17,150,19,8647,2))),'prefix'('src_span'(151,21,151,39,8719,18),['in'(_m196),'in'(_b9)],'dotTuple'(['report_chan','wimage']),'prefix'('src_span'(151,47,151,51,8745,4),['out'('dotTuple'(['window',_m196]))],'line','prefix'('src_span'(151,64,151,70,8762,6),['out'(_b9)],'uplink','|~|'('prefix'('src_span'(152,23,152,30,8796,7),['out'(_b9)],'free_in','prefix'('src_span'(152,36,152,44,8809,8),[],'ready_in','val_of'('ReporterStall','src_span'(152,48,152,61,8821,13)),'src_span'(152,45,152,47,8817,25)),'src_span'(152,33,152,35,8805,31)),'stop'('src_span'(152,67,152,71,8840,4)),'src_span_operator'('no_loc_info_available','src_span'(152,63,152,66,8836,3))),'src_span'(151,73,152,20,8770,77)),'src_span'(151,61,151,63,8758,96)),'src_span'(151,44,151,46,8741,106)),'src_span_operator'('no_loc_info_available','src_span'(151,17,151,19,8715,2))),'src_span'(149,1,152,73,8538,308)).
'agent'('PIPE'(_Src,_Inf),'sharing'('closure'(['frame_chan','release_chan']),_Src,_Inf,'src_span'(154,22,154,58,8869,36)),'src_span'(154,22,154,58,8869,36)).
'agent'('NETWORK'(_Src2,_Inf2,_Rep,_Main),'sharing'('closure'(['ready_in','ready_out','ready_empty']),'sharing'('closure'(['free_in','free_out','poll_empty']),'sharing'('closure'(['report_chan']),'|||'('agent_call'('src_span'(156,8,156,12,8948,4),'PIPE',[_Src2,_Inf2]),_Main,'src_span_operator'('no_loc_info_available','src_span'(156,23,156,26,8963,3))),_Rep,'src_span'(156,33,156,56,8973,23)),'val_of'('FREE','src_span'(157,48,157,52,9049,4)),'src_span'(157,6,157,47,9007,41)),'val_of'('READY','src_span'(158,50,158,55,9104,5)),'src_span'(158,5,158,49,9059,44)),'src_span'(158,5,158,49,9059,44)).
'agent'('SYS'(_Src3,_Inf3,_Rep2,_Main2),'sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(159,28,159,31,9137,3)),'agent_call'('src_span'(159,59,159,66,9168,7),'NETWORK',[_Src3,_Inf3,_Rep2,_Main2]),'src_span'(159,32,159,58,9141,26)),'src_span'(159,32,159,58,9141,26)).
'agent'('OBS'(_cam,_pend,_best210,_sp211,_send,_slot),'[]'('[]'('[]'('[]'('[]'('[]'('prefix'('src_span'(164,6,164,16,9419,10),['in'(_b214),'in'(_k6)],'frame_chan','ifte'('!='(_b214,_cam),'prefix'('src_span'(164,42,164,47,9455,5),[],'error','stop'('src_span'(164,51,164,55,9464,4)),'src_span'(164,48,164,50,9460,13)),'ifte'('=='(_k6,'img'),'agent_call'('src_span'(165,47,165,50,9515,3),'OBS',['val_of'('NONE','src_span'(165,51,165,55,9519,4)),_b214,_best210,_sp211,_send,_slot]),'agent_call'('src_span'(166,30,166,33,9579,3),'OBS',['val_of'('NONE','src_span'(166,34,166,38,9583,4)),_pend,_best210,'agent_call'('src_span'(166,52,166,57,9601,5),'union',[_sp211,'setExp'('rangeEnum'([_b214]))]),_send,_slot]),'no_loc_info_available','no_loc_info_available','src_span'(165,82,166,29,9549,113)),'no_loc_info_available','no_loc_info_available','src_span'(164,56,165,29,9468,173)),'src_span'(164,21,164,23,9433,198)),'prefix'('src_span'(167,6,167,18,9636,12),['in'(_b216)],'release_chan','ifte'('bool_and'('=='(_cam,'val_of'('NONE','src_span'(167,35,167,39,9665,4))),'agent_call'('src_span'(167,44,167,50,9674,6),'member',[_b216,_sp211])),'agent_call'('src_span'(168,30,168,33,9717,3),'OBS',[_b216,_pend,_best210,'agent_call'('src_span'(168,49,168,53,9736,4),'diff',[_sp211,'setExp'('rangeEnum'([_b216]))]),_send,_slot]),'prefix'('src_span'(168,81,168,86,9768,5),[],'error','stop'('src_span'(168,90,168,94,9777,4)),'src_span'(168,87,168,89,9773,13)),'no_loc_info_available','no_loc_info_available','src_span'(168,76,168,80,9762,64)),'src_span'(167,21,167,23,9650,134)),'src_span_operator'('no_loc_info_available','src_span'(167,2,167,4,9632,2))),'prefix'('src_span'(169,6,169,12,9789,6),['in'(_o),'in'(_b218)],'scored','ifte'('!='(_b218,_pend),'prefix'('src_span'(169,39,169,44,9822,5),[],'error','stop'('src_span'(169,48,169,52,9831,4)),'src_span'(169,45,169,47,9827,13)),'ifte'('=='(_o,'better'),'agent_call'('src_span'(171,26,171,29,9901,3),'OBS',[_cam,'val_of'('NONE','src_span'(171,35,171,39,9910,4)),_b218,'ifte'('=='(_best210,'val_of'('NONE','src_span'(171,55,171,59,9930,4))),_sp211,'agent_call'('src_span'(171,73,171,78,9948,5),'union',[_sp211,'setExp'('rangeEnum'([_best210]))]),'no_loc_info_available','no_loc_info_available','src_span'(171,68,171,72,9942,25)),_send,_slot]),'agent_call'('src_span'(172,26,172,29,10004,3),'OBS',[_cam,'val_of'('NONE','src_span'(172,35,172,39,10013,4)),_best210,'agent_call'('src_span'(172,47,172,52,10025,5),'union',[_sp211,'setExp'('rangeEnum'([_b218]))]),_send,_slot]),'no_loc_info_available','no_loc_info_available','src_span'(171,104,172,25,9978,151)),'no_loc_info_available','no_loc_info_available','src_span'(169,53,170,25,9835,230)),'src_span'(169,17,169,19,9799,256)),'src_span_operator'('no_loc_info_available','src_span'(169,2,169,4,9785,2))),'prefix'('src_span'(173,6,173,14,10060,8),['in'(_b219)],'suppress','ifte'('=='(_b219,_best210),'agent_call'('src_span'(173,39,173,42,10093,3),'OBS',[_cam,_pend,'val_of'('NONE','src_span'(173,54,173,58,10108,4)),'agent_call'('src_span'(173,60,173,65,10114,5),'union',[_sp211,'setExp'('rangeEnum'([_b219]))]),_send,_slot]),'prefix'('src_span'(173,93,173,98,10147,5),[],'error','stop'('src_span'(173,102,173,106,10156,4)),'src_span'(173,99,173,101,10152,13)),'no_loc_info_available','no_loc_info_available','src_span'(173,88,173,92,10141,67)),'src_span'(173,17,173,19,10070,93)),'src_span_operator'('no_loc_info_available','src_span'(173,2,173,4,10056,2))),'prefix'('src_span'(174,6,174,24,10168,18),['in'(_m220),'in'(_b221)],'dotTuple'(['report_chan','wimage']),'ifte'('bool_and'('bool_and'('=='(_b221,_best210),'=='(_send,'val_of'('NONE','src_span'(174,58,174,62,10220,4)))),'=='(_slot,'val_of'('NONE','src_span'(174,75,174,79,10237,4)))),'agent_call'('src_span'(175,38,175,41,10279,3),'OBS',[_cam,_pend,'val_of'('NONE','src_span'(175,53,175,57,10294,4)),_sp211,_b221,_slot]),'prefix'('src_span'(175,77,175,82,10318,5),[],'error','stop'('src_span'(175,86,175,90,10327,4)),'src_span'(175,83,175,85,10323,13)),'no_loc_info_available','no_loc_info_available','src_span'(175,72,175,76,10312,52)),'src_span'(174,29,174,31,10190,144)),'src_span_operator'('no_loc_info_available','src_span'(174,2,174,4,10164,2))),'prefix'('src_span'(176,6,176,13,10339,7),['in'(_b222)],'free_in','ifte'('=='(_b222,_send),'agent_call'('src_span'(176,38,176,41,10371,3),'OBS',[_cam,_pend,_best210,_sp211,'val_of'('NONE','src_span'(176,63,176,67,10396,4)),_b222]),'prefix'('src_span'(176,77,176,82,10410,5),[],'error','stop'('src_span'(176,86,176,90,10419,4)),'src_span'(176,83,176,85,10415,13)),'no_loc_info_available','no_loc_info_available','src_span'(176,72,176,76,10404,52)),'src_span'(176,16,176,18,10348,78)),'src_span_operator'('no_loc_info_available','src_span'(176,2,176,4,10335,2))),'prefix'('src_span'(177,6,177,14,10431,8),['in'(_b223)],'free_out','ifte'('=='(_b223,_slot),'agent_call'('src_span'(177,39,177,42,10464,3),'OBS',[_cam,_pend,_best210,'agent_call'('src_span'(177,60,177,65,10485,5),'union',[_sp211,'setExp'('rangeEnum'([_b223]))]),_send,'val_of'('NONE','src_span'(177,82,177,86,10507,4))]),'prefix'('src_span'(177,93,177,98,10518,5),[],'error','stop'('src_span'(177,102,177,106,10527,4)),'src_span'(177,99,177,101,10523,13)),'no_loc_info_available','no_loc_info_available','src_span'(177,88,177,92,10512,67)),'src_span'(177,17,177,19,10441,93)),'src_span_operator'('no_loc_info_available','src_span'(177,2,177,4,10427,2))),'no_loc_info_available').
'bindval'('ROLE_EVENTS','closure'(['frame_chan','release_chan','scored','suppress','dotTuple'(['report_chan','wimage']),'free_in','free_out']),'src_span'(179,1,179,102,10535,101)).
'agent'('OBSERVED'(_P),'sharing'('val_of'('ROLE_EVENTS','src_span'(180,20,180,31,10656,11)),_P,'agent_call'('src_span'(180,35,180,38,10671,3),'OBS',['int'(0),'val_of'('NONE','src_span'(180,42,180,46,10678,4)),'val_of'('NONE','src_span'(180,48,180,52,10684,4)),'setExp'('rangeEnum'(['int'(1),'int'(2),'int'(3)])),'val_of'('NONE','src_span'(180,65,180,69,10701,4)),'val_of'('NONE','src_span'(180,71,180,75,10707,4))]),'src_span'(180,17,180,34,10653,17)),'src_span'(180,17,180,34,10653,17)).
'bindval'('SRC_EVENTS','closure'(['frame_chan','release_chan']),'src_span'(10,1,10,44,589,43)).
'agent'('SOURCE'(_b225),'repInternalChoice'(['comprehensionGenerator'(_k7,'kind_t')],'prefix'('src_span'(11,31,11,41,663,10),['out'(_b225),'out'(_k7)],'frame_chan','prefix'('src_span'(11,49,11,61,681,12),['in'(_nb4)],'release_chan','agent_call'('src_span'(11,68,11,74,700,6),'SOURCE',[_nb4]),'src_span'(11,65,11,67,696,17)),'src_span'(11,46,11,48,677,35)),'src_span'(11,18,11,30,650,12)),'src_span'(11,13,11,79,645,66)).
'assertRef'('False','agent_call'('src_span'(13,8,13,14,720,6),'SOURCE',['int'(0)]),'FailureDivergence','\x5c\'('val_of'('Camera','src_span'(13,23,13,29,735,6)),'agent_call'('src_span'(13,32,13,36,744,4),'diff',['Events','val_of'('SRC_EVENTS','src_span'(13,45,13,55,757,10))]),'src_span_operator'('no_loc_info_available','src_span'(13,30,13,31,742,1))),'src_span'(13,1,13,56,713,55)).
'assertRef'('False','agent_call'('src_span'(14,8,14,14,776,6),'SOURCE',['int'(0)]),'FailureDivergence','\x5c\'('val_of'('FileSource','src_span'(14,23,14,33,791,10)),'agent_call'('src_span'(14,36,14,40,804,4),'diff',['Events','val_of'('SRC_EVENTS','src_span'(14,49,14,59,817,10))]),'src_span_operator'('no_loc_info_available','src_span'(14,34,14,35,802,1))),'src_span'(14,1,14,60,769,59)).
'bindval'('SYSTEM_FS','agent_call'('src_span'(17,13,17,16,904,3),'SYS',['val_of'('FileSource','src_span'(17,17,17,27,908,10)),'val_of'('Inference','src_span'(17,29,17,38,920,9)),'val_of'('Reporter','src_span'(17,40,17,48,931,8)),'val_of'('MainApp','src_span'(17,50,17,57,941,7))]),'src_span'(17,1,17,58,892,57)).
'assertModelCheckExt'('False','val_of'('SYSTEM_FS','src_span'(19,8,19,17,958,9)),'DeadlockFree','F').
'assertModelCheck'('False','val_of'('SYSTEM_FS','src_span'(20,8,20,17,996,9)),'LivelockFree').
'assertRef'('False','agent_call'('src_span'(21,8,21,11,1032,3),'RUN',['agent_call'('src_span'(21,12,21,16,1036,4),'diff',['Events','setExp'('rangeEnum'(['error','overflow']))])]),'Trace','agent_call'('src_span'(21,49,21,57,1073,8),'OBSERVED',['val_of'('SYSTEM_FS','src_span'(21,58,21,67,1082,9))]),'src_span'(21,1,21,68,1025,67)).
'agent'('MCOUNT'(_k8),'[]'('[]'('prefix'('src_span'(23,14,23,19,1107,5),[],'merge','agent_call'('src_span'(23,23,23,29,1116,6),'MCOUNT',['agent_call'('src_span'(23,30,23,33,1123,3),'sat',['+'(_k8,'int'(1))])]),'src_span'(23,20,23,22,1112,27)),'prefix'('src_span'(24,17,24,35,1152,18),['out'(_k8)],'dotTuple'(['report_chan','window']),'agent_call'('src_span'(24,41,24,47,1176,6),'MCOUNT',['int'(0)]),'src_span'(24,38,24,40,1172,15)),'src_span_operator'('no_loc_info_available','src_span'(24,13,24,15,1148,2))),'prefix'('src_span'(25,17,25,35,1203,18),['out'(_k8),'in'(_b229)],'dotTuple'(['report_chan','wimage']),'agent_call'('src_span'(25,43,25,49,1229,6),'MCOUNT',['int'(0)]),'src_span'(25,40,25,42,1225,15)),'src_span_operator'('no_loc_info_available','src_span'(25,13,25,15,1199,2))),'no_loc_info_available').
'assertRef'('False','agent_call'('src_span'(27,8,27,14,1248,6),'MCOUNT',['int'(0)]),'Trace','\x5c\'('val_of'('SYSTEM_FS','src_span'(27,22,27,31,1262,9)),'agent_call'('src_span'(27,34,27,38,1274,4),'diff',['Events','closure'(['merge','dotTuple'(['report_chan','window']),'dotTuple'(['report_chan','wimage'])])]),'src_span_operator'('no_loc_info_available','src_span'(27,32,27,33,1272,1))),'src_span'(27,1,27,99,1241,98)).
'bindval'('INF_REPORTS','closure'(['dotTuple'(['report_chan','scores']),'dotTuple'(['report_chan','window']),'dotTuple'(['report_chan','wimage'])]),'src_span'(29,1,29,79,1341,78)).
'bindval'('TOKEN','repChoice'(['comprehensionGenerator'(_r5,'val_of'('INF_REPORTS','src_span'(30,17,30,28,1436,11)))],'prefix'('src_span'(30,31,30,32,1450,1),[],_r5,'prefix'('src_span'(30,36,30,44,1455,8),[],'ready_in','val_of'('TOKEN','src_span'(30,48,30,53,1467,5)),'src_span'(30,45,30,47,1463,17)),'src_span'(30,33,30,35,1451,22)),'src_span'(30,13,30,30,1432,17)),'src_span'(30,1,30,54,1420,53)).
'assertRef'('False','val_of'('TOKEN','src_span'(32,8,32,13,1482,5)),'Trace','\x5c\'('val_of'('SYSTEM_FS','src_span'(32,18,32,27,1492,9)),'agent_call'('src_span'(32,30,32,34,1504,4),'diff',['Events','agent_call'('src_span'(32,43,32,48,1517,5),'union',['val_of'('INF_REPORTS','src_span'(32,49,32,60,1523,11)),'setExp'('rangeEnum'(['ready_in']))])]),'src_span_operator'('no_loc_info_available','src_span'(32,28,32,29,1502,1))),'src_span'(32,1,32,74,1475,73)).
'bindval'('CYCLE_F','repInternalChoice'(['comprehensionGenerator'(_b231,'val_of'('IDS','src_span'(37,20,37,23,1855,3))),'comprehensionGenerator'(_k9,'kind_t')],'prefix'('src_span'(37,38,37,48,1873,10),['out'(_b231),'out'(_k9)],'frame_chan','val_of'('CYCLE_F','src_span'(37,56,37,63,1891,7)),'src_span'(37,53,37,55,1887,13)),'src_span'(37,16,37,37,1851,21)),'src_span'(37,1,37,64,1836,63)).
'assertRef'('False','val_of'('CYCLE_F','src_span'(39,8,39,15,1908,7)),'FailureDivergence','\x5c\'('agent_call'('src_span'(39,21,39,24,1921,3),'SYS',['val_of'('FileSource','src_span'(39,25,39,35,1925,10)),'val_of'('Inference','src_span'(39,37,39,46,1937,9)),'val_of'('Reporter','src_span'(39,48,39,56,1948,8)),'agent_call'('src_span'(39,58,39,66,1958,8),'MainAppN',['int'(1)])]),'agent_call'('src_span'(39,73,39,77,1973,4),'diff',['Events','closure'(['frame_chan'])]),'src_span_operator'('no_loc_info_available','src_span'(39,71,39,72,1971,1))),'src_span'(39,1,39,103,1901,102)).
'assertRef'('False','val_of'('CYCLE_F','src_span'(45,8,45,15,2394,7)),'FailureDivergence','\x5c\'('agent_call'('src_span'(45,21,45,24,2407,3),'SYS',['val_of'('FileSource','src_span'(45,25,45,35,2411,10)),'val_of'('Inference','src_span'(45,37,45,46,2423,9)),'val_of'('ReporterStall','src_span'(45,48,45,61,2434,13)),'agent_call'('src_span'(45,63,45,71,2449,8),'MainAppN',['int'(1)])]),'agent_call'('src_span'(45,78,45,82,2464,4),'diff',['Events','closure'(['frame_chan'])]),'src_span_operator'('no_loc_info_available','src_span'(45,76,45,77,2462,1))),'src_span'(45,1,45,108,2387,107)).
'bindval'('SYSTEM_CAM','agent_call'('src_span'(49,14,49,17,2699,3),'SYS',['val_of'('Camera','src_span'(49,18,49,24,2703,6)),'val_of'('Inference','src_span'(49,26,49,35,2711,9)),'val_of'('Reporter','src_span'(49,37,49,45,2722,8)),'val_of'('MainApp','src_span'(49,47,49,54,2732,7))]),'src_span'(49,1,49,55,2686,54)).
'bindval'('CYCLE','prefix'('src_span'(50,9,50,23,2749,14),[],'g_trigger_chan','val_of'('CYCLE','src_span'(50,27,50,32,2767,5)),'src_span'(50,24,50,26,2763,23)),'src_span'(50,1,50,32,2741,31)).
'assertModelCheckExt'('False','val_of'('SYSTEM_CAM','src_span'(52,8,52,18,2781,10)),'DeadlockFree','F').
'assertRef'('False','agent_call'('src_span'(53,8,53,11,2820,3),'RUN',['agent_call'('src_span'(53,12,53,16,2824,4),'diff',['Events','setExp'('rangeEnum'(['error','overflow']))])]),'Trace','agent_call'('src_span'(53,49,53,57,2861,8),'OBSERVED',['val_of'('SYSTEM_CAM','src_span'(53,58,53,68,2870,10))]),'src_span'(53,1,53,69,2813,68)).
'assertRef'('False','val_of'('CYCLE','src_span'(54,8,54,13,2889,5)),'FailureDivergence','\x5c\'('agent_call'('src_span'(54,19,54,22,2900,3),'SYS',['val_of'('Camera','src_span'(54,23,54,29,2904,6)),'val_of'('Inference','src_span'(54,31,54,40,2912,9)),'val_of'('ReporterStall','src_span'(54,42,54,55,2923,13)),'agent_call'('src_span'(54,57,54,65,2938,8),'MainAppN',['int'(2)])]),'agent_call'('src_span'(54,72,54,76,2953,4),'diff',['Events','setExp'('rangeEnum'(['g_trigger_chan']))]),'src_span_operator'('no_loc_info_available','src_span'(54,70,54,71,2951,1))),'src_span'(54,1,54,102,2882,101)).
'comment'('lineComment'('-- Frame source: the assertions. The processes are in Uplink_source_defs.csp; Uplink.csp checks'),'src_position'(1,1,0,95)).
'comment'('lineComment'('-- the Camera network of Uplink_defs.csp, Uplink_command.csp the command path.'),'src_position'(2,1,96,78)).
'comment'('lineComment'('-- Frame source (FRAME_SOURCE = camera | sdcard), definitions shared by Uplink_source.csp and'),'src_position'(1,1,0,93)).
'comment'('lineComment'('-- Uplink_source_controls.csp. Derived from Uplink_defs.csp (same buffers, tokens, Reporter and'),'src_position'(2,1,94,95)).
'comment'('lineComment'('-- MainApp), with three changes:'),'src_position'(3,1,190,32)).
'comment'('lineComment'('--  * frame_chan carries the buffer id and a kind: img (a frame) or eos (the end-of-stream'),'src_position'(4,1,223,90)).
'comment'('lineComment'('--    terminator, frame_t.end: it carries a JPEG buffer but no image);'),'src_position'(5,1,314,70)).
'comment'('lineComment'('--  * Inference counts its position in the window (pos) instead of taking it from the frame'),'src_position'(6,1,385,91)).
'comment'('lineComment'('--    index, as the firmware does (pos restarts at 0 after an end-of-stream flush);'),'src_position'(7,1,477,83)).
'comment'('lineComment'('--  * the source is a parameter: Camera or FileSource.'),'src_position'(8,1,561,54)).
'comment'('lineComment'('-- Bounded as in Uplink_defs.csp: windows of W = 2 frames, the merged count saturating at MAXM.'),'src_position'(9,1,616,95)).
'comment'('lineComment'('-- no buffer'),'src_position'(13,48,793,12)).
'comment'('lineComment'('-- Inference\x27\s text reports (return the token)'),'src_position'(23,58,1153,46)).
'comment'('lineComment'('-- frame-ready interrupt -> Camera'),'src_position'(26,48,1330,34)).
'comment'('lineComment'('-- source -> Inference: buffer, frame or terminator'),'src_position'(27,48,1412,51)).
'comment'('lineComment'('-- Inference -> source: the next buffer to fill'),'src_position'(28,48,1511,47)).
'comment'('lineComment'('-- Reporter -> free_chan\x27\s slot'),'src_position'(29,48,1606,31)).
'comment'('lineComment'('-- free_chan\x27\s slot -> Inference'),'src_position'(30,48,1685,32)).
'comment'('lineComment'('-- free_chan\x27\s slot -> Inference (poll, SKIP taken)'),'src_position'(31,48,1765,51)).
'comment'('lineComment'('-- Reporter -> ready_chan\x27\s slot'),'src_position'(32,48,1864,32)).
'comment'('lineComment'('-- ready_chan\x27\s slot -> Inference'),'src_position'(33,48,1944,33)).
'comment'('lineComment'('-- ready_chan\x27\s slot -> Inference (poll, SKIP taken)'),'src_position'(34,48,2025,52)).
'comment'('lineComment'('-- the sources, Inference, MainApp -> Reporter'),'src_position'(35,48,2125,46)).
'comment'('lineComment'('-- the Reporter\x27\s text lines'),'src_position'(36,48,2219,28)).
'comment'('lineComment'('-- the Reporter sends the JPEG in this buffer'),'src_position'(37,48,2295,45)).
'comment'('lineComment'('-- Inference has scored the frame in this buffer'),'src_position'(38,48,2388,48)).
'comment'('lineComment'('-- the window\x27\s best fails the filter'),'src_position'(39,48,2484,37)).
'comment'('lineComment'('-- Inference merges a window (no token at its end)'),'src_position'(40,48,2569,50)).
'comment'('lineComment'('-- FileSource has read a frame\x27\s two files'),'src_position'(41,48,2667,42)).
'comment'('lineComment'('-- FileSource starts the stream again (restart)'),'src_position'(42,48,2757,47)).
'comment'('lineComment'('-- Camera: as in Uplink_defs.csp, without the frame index (only Inference\x27\s window position used'),'src_position'(50,1,2923,96)).
'comment'('lineComment'('-- it). It writes report_chan once, at start, and never sends a terminator.'),'src_position'(51,1,3020,75)).
'comment'('lineComment'('-- FileSource: before each frame it may write one report (a read or CRC error with the file name,'),'src_position'(55,1,3252,97)).
'comment'('lineComment'('-- a command acknowledgement, a status line); then either a frame (its two files read into the'),'src_position'(56,1,3350,94)).
'comment'('lineComment'('-- raw buffer and the JPEG buffer b) or, at the end of the manifest without loop, the terminator'),'src_position'(57,1,3445,96)).
'comment'('lineComment'('-- in b, the end report, and a wait for restart, after which it starts again. A frame that fails'),'src_position'(58,1,3542,96)).
'comment'('lineComment'('-- its CRC is not passed on: the report is written, the next frame is read into the same buffers.'),'src_position'(59,1,3639,97)).
'comment'('lineComment'('-- Pace and the cmd_chan polls only add delays and are left out (cmd_chan: Uplink_command.csp).'),'src_position'(60,1,3737,95)).
'comment'('lineComment'('-- Inference: pos = position in the window, p = the buffer just received, k = its kind, sp ='),'src_position'(67,1,4170,92)).
'comment'('lineComment'('-- spare buffers, best = the window\x27\s best (NONE if none), tok = holds the free token, rdy = holds'),'src_position'(68,1,4263,98)).
'comment'('lineComment'('-- the ready token, m = windows merged since the last Window line, sc = scores not yet reported.'),'src_position'(69,1,4362,96)).
'comment'('lineComment'('-- After scoring there is always a score not yet reported; every report of Inference\x27\s carries'),'src_position'(96,1,5721,94)).
'comment'('lineComment'('-- the scores and clears it. Window end: pos == W - 1.'),'src_position'(97,1,5816,54)).
'comment'('lineComment'('-- End of stream: the terminator\x27\s buffer goes straight back to the source; if the window has'),'src_position'(115,1,6678,93)).
'comment'('lineComment'('-- frames (pos > 0) or scores are waiting, Inference waits for the ready token (a blocking read,'),'src_position'(116,1,6772,96)).
'comment'('lineComment'('-- not a poll), for a partial window also for the free token, and sends the Window report of the'),'src_position'(117,1,6869,96)).
'comment'('lineComment'('-- partial window (or a Scores report). The next stream starts a new window.'),'src_position'(118,1,6966,76)).
'comment'('lineComment'('-- free_chan and ready_chan: one-slot buffered channels, as in Uplink_defs.csp. Inference\x27\s'),'src_position'(133,1,7629,91)).
'comment'('lineComment'('-- blocking reads at end of stream take free_out / ready_out like a poll that finds a value.'),'src_position'(134,1,7721,92)).
'comment'('lineComment'('-- Reporter: as in Uplink_defs.csp; the source\x27\s reports are OTHER (a line, no token).'),'src_position'(144,1,8217,86)).
'comment'('lineComment'('-- Buffer roles, as in Uplink_defs.csp, plus the terminator: its buffer goes from the source\x27\s'),'src_position'(161,1,9198,94)).
'comment'('lineComment'('-- target straight back to the spares (Inference releases it as the next target).'),'src_position'(162,1,9293,81)).
'comment'('lineComment'('-- The source protocol on frame_chan and release_chan: the source sends a frame or a terminator'),'src_position'(6,1,210,95)).
'comment'('lineComment'('-- in the buffer it was last given (buffer 0 at start), then takes any buffer as the next one.'),'src_position'(7,1,306,94)).
'comment'('lineComment'('-- Camera and FileSource both refine it (everything but the two channels hidden), so everything'),'src_position'(8,1,401,95)).
'comment'('lineComment'('-- Inference and the rest of the network can see of either source is a behaviour of SOURCE.'),'src_position'(9,1,497,91)).
'comment'('lineComment'('-- The FileSource network keeps the properties of Uplink.csp.'),'src_position'(16,1,830,61)).
'comment'('lineComment'('-- Frames keep flowing (with end of stream and restart) while the Reporter runs: frame_chan is'),'src_position'(34,1,1550,94)).
'comment'('lineComment'('-- never refused for ever. MainApp with one report (Uplink.csp: two): with two, the check ran'),'src_position'(35,1,1645,93)).
'comment'('lineComment'('-- out of memory at 14 GB; any finite number keeps the stack reports from forming a hidden loop.'),'src_position'(36,1,1739,96)).
'comment'('lineComment'('-- Expected to FAIL, and documented as a difference between the sources: with the Reporter'),'src_position'(41,1,2005,90)).
'comment'('lineComment'('-- stalled, FileSource stops. It writes report_chan between frames (errors, acknowledgements,'),'src_position'(42,1,2096,93)).
'comment'('lineComment'('-- status, end of stream), and Inference\x27\s end-of-stream flush waits for the ready token. Camera'),'src_position'(43,1,2190,96)).
'comment'('lineComment'('-- writes report_chan only at start and never sends a terminator, so it keeps cycling (last check).'),'src_position'(44,1,2287,99)).
'comment'('lineComment'('-- The Camera network with this Inference (window position, end-of-stream branch) keeps the'),'src_position'(47,1,2496,91)).
'comment'('lineComment'('-- buffer roles and keeps cycling with the Reporter stalled, as with the Inference of Uplink.csp.'),'src_position'(48,1,2588,97)).
'symbol'('W','W','src_span'(11,1,11,2,713,1),'Ident (Groundrep.)').
'symbol'('IDS','IDS','src_span'(12,1,12,4,727,3),'Ident (Groundrep.)').
'symbol'('NONE','NONE','src_span'(13,1,13,5,746,4),'Ident (Groundrep.)').
'symbol'('MAXM','MAXM','src_span'(14,1,14,5,806,4),'Ident (Groundrep.)').
'symbol'('sat','sat','src_span'(16,1,16,4,821,3),'Funktion or Process').
'symbol'('m','m','src_span'(16,5,16,6,825,1),'Ident (Prolog Variable)').
'symbol'('source_t','source_t','src_span'(18,10,18,18,869,8),'Datatype').
'symbol'('camera','camera','src_span'(18,22,18,28,881,6),'Constructor of Datatype').
'symbol'('inference','inference','src_span'(18,31,18,40,890,9),'Constructor of Datatype').
'symbol'('filesource','filesource','src_span'(18,43,18,53,902,10),'Constructor of Datatype').
'symbol'('kind_t','kind_t','src_span'(19,10,19,16,922,6),'Datatype').
'symbol'('img','img','src_span'(19,22,19,25,934,3),'Constructor of Datatype').
'symbol'('eos','eos','src_span'(19,28,19,31,940,3),'Constructor of Datatype').
'symbol'('outcome_t','outcome_t','src_span'(20,10,20,19,953,9),'Datatype').
'symbol'('better','better','src_span'(20,22,20,28,965,6),'Constructor of Datatype').
'symbol'('worse','worse','src_span'(20,31,20,36,974,5),'Constructor of Datatype').
'symbol'('failed','failed','src_span'(20,39,20,45,982,6),'Constructor of Datatype').
'symbol'('report_t','report_t','src_span'(21,10,21,18,998,8),'Datatype').
'symbol'('started','started','src_span'(21,22,21,29,1010,7),'Constructor of Datatype').
'symbol'('stack','stack','src_span'(21,41,21,46,1029,5),'Constructor of Datatype').
'symbol'('srcmsg','srcmsg','src_span'(21,49,21,55,1037,6),'Constructor of Datatype').
'symbol'('scores','scores','src_span'(21,58,21,64,1046,6),'Constructor of Datatype').
'symbol'('window','window','src_span'(21,67,21,73,1055,6),'Constructor of Datatype').
'symbol'('wimage','wimage','src_span'(21,86,21,92,1074,6),'Constructor of Datatype').
'symbol'('INF_TEXT','INF_TEXT','src_span'(23,1,23,9,1096,8),'Ident (Groundrep.)').
'symbol'('union','union','src_span'(23,12,23,17,1107,5),'BuiltIn primitive').
'symbol'('m2','m','src_span'(23,40,23,41,1135,1),'Ident (Prolog Variable)').
'symbol'('OTHER','OTHER','src_span'(24,1,24,6,1200,5),'Ident (Groundrep.)').
'symbol'('g_trigger_chan','g_trigger_chan','src_span'(26,9,26,23,1291,14),'Channel').
'symbol'('frame_chan','frame_chan','src_span'(27,9,27,19,1373,10),'Channel').
'symbol'('release_chan','release_chan','src_span'(28,9,28,21,1472,12),'Channel').
'symbol'('free_in','free_in','src_span'(29,9,29,16,1567,7),'Channel').
'symbol'('free_out','free_out','src_span'(30,9,30,17,1646,8),'Channel').
'symbol'('poll_empty','poll_empty','src_span'(31,9,31,19,1726,10),'Channel').
'symbol'('ready_in','ready_in','src_span'(32,9,32,17,1825,8),'Channel').
'symbol'('ready_out','ready_out','src_span'(33,9,33,18,1905,9),'Channel').
'symbol'('ready_empty','ready_empty','src_span'(34,9,34,20,1986,11),'Channel').
'symbol'('report_chan','report_chan','src_span'(35,9,35,20,2086,11),'Channel').
'symbol'('line','line','src_span'(36,9,36,13,2180,4),'Channel').
'symbol'('uplink','uplink','src_span'(37,9,37,15,2256,6),'Channel').
'symbol'('scored','scored','src_span'(38,9,38,15,2349,6),'Channel').
'symbol'('suppress','suppress','src_span'(39,9,39,17,2445,8),'Channel').
'symbol'('merge','merge','src_span'(40,9,40,14,2530,5),'Channel').
'symbol'('fs_read','fs_read','src_span'(41,9,41,16,2628,7),'Channel').
'symbol'('fs_restart','fs_restart','src_span'(42,9,42,19,2718,10),'Channel').
'symbol'('camera_log','camera_log','src_span'(43,9,43,19,2813,10),'Channel').
'symbol'('stack_tick','stack_tick','src_span'(43,21,43,31,2825,10),'Channel').
'symbol'('overflow','overflow','src_span'(44,9,44,17,2844,8),'Channel').
'symbol'('error','error','src_span'(44,19,44,24,2854,5),'Channel').
'symbol'('ENV','ENV','src_span'(46,1,46,4,2861,3),'Ident (Groundrep.)').
'symbol'('RUN','RUN','src_span'(48,1,48,4,2890,3),'Funktion or Process').
'symbol'('A','A','src_span'(48,5,48,6,2894,1),'Ident (Prolog Variable)').
'symbol'('x','x','src_span'(48,13,48,14,2902,1),'Ident (Prolog Variable)').
'symbol'('Camera','Camera','src_span'(52,1,52,7,3096,6),'Ident (Groundrep.)').
'symbol'('CameraLoop','CameraLoop','src_span'(53,1,53,11,3163,10),'Funktion or Process').
'symbol'('b','b','src_span'(53,12,53,13,3174,1),'Ident (Prolog Variable)').
'symbol'('nb','nb','src_span'(53,68,53,70,3230,2),'Ident (Prolog Variable)').
'symbol'('FileSource','FileSource','src_span'(61,1,61,11,3833,10),'Ident (Groundrep.)').
'symbol'('FS','FS','src_span'(62,1,62,3,3886,2),'Funktion or Process').
'symbol'('b2','b','src_span'(62,4,62,5,3889,1),'Ident (Prolog Variable)').
'symbol'('FSFrame','FSFrame','src_span'(63,1,63,8,3944,7),'Funktion or Process').
'symbol'('b3','b','src_span'(63,9,63,10,3952,1),'Ident (Prolog Variable)').
'symbol'('nb2','nb','src_span'(63,59,63,61,4002,2),'Ident (Prolog Variable)').
'symbol'('nb3','nb','src_span'(64,52,64,54,4067,2),'Ident (Prolog Variable)').
'symbol'('Inference','Inference','src_span'(70,1,70,10,4459,9),'Ident (Groundrep.)').
'symbol'('p','p','src_span'(70,24,70,25,4482,1),'Ident (Prolog Variable)').
'symbol'('k','k','src_span'(70,26,70,27,4484,1),'Ident (Prolog Variable)').
'symbol'('diff','diff','src_span'(70,79,70,83,4537,4),'BuiltIn primitive').
'symbol'('Infer','Infer','src_span'(72,1,72,6,4582,5),'Funktion or Process').
'symbol'('pos','pos','src_span'(72,7,72,10,4588,3),'Ident (Prolog Variable)').
'symbol'('p2','p','src_span'(72,12,72,13,4593,1),'Ident (Prolog Variable)').
'symbol'('k2','k','src_span'(72,15,72,16,4596,1),'Ident (Prolog Variable)').
'symbol'('sp','sp','src_span'(72,18,72,20,4599,2),'Ident (Prolog Variable)').
'symbol'('best','best','src_span'(72,22,72,26,4603,4),'Ident (Prolog Variable)').
'symbol'('tok','tok','src_span'(72,28,72,31,4609,3),'Ident (Prolog Variable)').
'symbol'('rdy','rdy','src_span'(72,33,72,36,4614,3),'Ident (Prolog Variable)').
'symbol'('m3','m','src_span'(72,38,72,39,4619,1),'Ident (Prolog Variable)').
'symbol'('sc','sc','src_span'(72,41,72,43,4622,2),'Ident (Prolog Variable)').
'symbol'('b4','b','src_span'(73,15,73,16,4642,1),'Ident (Prolog Variable)').
'symbol'('PollReady','PollReady','src_span'(76,1,76,10,4781,9),'Funktion or Process').
'symbol'('pos2','pos','src_span'(76,11,76,14,4791,3),'Ident (Prolog Variable)').
'symbol'('p3','p','src_span'(76,16,76,17,4796,1),'Ident (Prolog Variable)').
'symbol'('k3','k','src_span'(76,19,76,20,4799,1),'Ident (Prolog Variable)').
'symbol'('sp2','sp','src_span'(76,22,76,24,4802,2),'Ident (Prolog Variable)').
'symbol'('best2','best','src_span'(76,26,76,30,4806,4),'Ident (Prolog Variable)').
'symbol'('tok2','tok','src_span'(76,32,76,35,4812,3),'Ident (Prolog Variable)').
'symbol'('rdy2','rdy','src_span'(76,37,76,40,4817,3),'Ident (Prolog Variable)').
'symbol'('m4','m','src_span'(76,42,76,43,4822,1),'Ident (Prolog Variable)').
'symbol'('sc2','sc','src_span'(76,45,76,47,4825,2),'Ident (Prolog Variable)').
'symbol'('Dispatch','Dispatch','src_span'(80,1,80,9,4970,8),'Funktion or Process').
'symbol'('pos3','pos','src_span'(80,10,80,13,4979,3),'Ident (Prolog Variable)').
'symbol'('p4','p','src_span'(80,15,80,16,4984,1),'Ident (Prolog Variable)').
'symbol'('k4','k','src_span'(80,18,80,19,4987,1),'Ident (Prolog Variable)').
'symbol'('sp3','sp','src_span'(80,21,80,23,4990,2),'Ident (Prolog Variable)').
'symbol'('best3','best','src_span'(80,25,80,29,4994,4),'Ident (Prolog Variable)').
'symbol'('tok3','tok','src_span'(80,31,80,34,5000,3),'Ident (Prolog Variable)').
'symbol'('rdy3','rdy','src_span'(80,36,80,39,5005,3),'Ident (Prolog Variable)').
'symbol'('m5','m','src_span'(80,41,80,42,5010,1),'Ident (Prolog Variable)').
'symbol'('sc3','sc','src_span'(80,44,80,46,5013,2),'Ident (Prolog Variable)').
'symbol'('Release','Release','src_span'(84,1,84,8,5149,7),'Funktion or Process').
'symbol'('pos4','pos','src_span'(84,9,84,12,5157,3),'Ident (Prolog Variable)').
'symbol'('p5','p','src_span'(84,14,84,15,5162,1),'Ident (Prolog Variable)').
'symbol'('sp4','sp','src_span'(84,17,84,19,5165,2),'Ident (Prolog Variable)').
'symbol'('best4','best','src_span'(84,21,84,25,5169,4),'Ident (Prolog Variable)').
'symbol'('tok4','tok','src_span'(84,27,84,30,5175,3),'Ident (Prolog Variable)').
'symbol'('rdy4','rdy','src_span'(84,32,84,35,5180,3),'Ident (Prolog Variable)').
'symbol'('m6','m','src_span'(84,37,84,38,5185,1),'Ident (Prolog Variable)').
'symbol'('sc4','sc','src_span'(84,40,84,42,5188,2),'Ident (Prolog Variable)').
'symbol'('s','s','src_span'(85,9,85,10,5202,1),'Ident (Prolog Variable)').
'symbol'('diff','diff','src_span'(85,50,85,54,5243,4),'BuiltIn primitive').
'symbol'('Score','Score','src_span'(87,1,87,6,5282,5),'Funktion or Process').
'symbol'('pos5','pos','src_span'(87,7,87,10,5288,3),'Ident (Prolog Variable)').
'symbol'('p6','p','src_span'(87,12,87,13,5293,1),'Ident (Prolog Variable)').
'symbol'('sp5','sp','src_span'(87,15,87,17,5296,2),'Ident (Prolog Variable)').
'symbol'('best5','best','src_span'(87,19,87,23,5300,4),'Ident (Prolog Variable)').
'symbol'('tok5','tok','src_span'(87,25,87,28,5306,3),'Ident (Prolog Variable)').
'symbol'('rdy5','rdy','src_span'(87,30,87,33,5311,3),'Ident (Prolog Variable)').
'symbol'('m7','m','src_span'(87,35,87,36,5316,1),'Ident (Prolog Variable)').
'symbol'('sc5','sc','src_span'(87,38,87,40,5319,2),'Ident (Prolog Variable)').
'symbol'('WindowReport','WindowReport','src_span'(98,1,98,13,5871,12),'Funktion or Process').
'symbol'('sp6','sp','src_span'(98,14,98,16,5884,2),'Ident (Prolog Variable)').
'symbol'('best6','best','src_span'(98,18,98,22,5888,4),'Ident (Prolog Variable)').
'symbol'('tok6','tok','src_span'(98,24,98,27,5894,3),'Ident (Prolog Variable)').
'symbol'('m8','m','src_span'(98,29,98,30,5899,1),'Ident (Prolog Variable)').
'symbol'('End','End','src_span'(103,1,103,4,6187,3),'Funktion or Process').
'symbol'('pos6','pos','src_span'(103,5,103,8,6191,3),'Ident (Prolog Variable)').
'symbol'('sp7','sp','src_span'(103,10,103,12,6196,2),'Ident (Prolog Variable)').
'symbol'('best7','best','src_span'(103,14,103,18,6200,4),'Ident (Prolog Variable)').
'symbol'('tok7','tok','src_span'(103,20,103,23,6206,3),'Ident (Prolog Variable)').
'symbol'('rdy6','rdy','src_span'(103,25,103,28,6211,3),'Ident (Prolog Variable)').
'symbol'('m9','m','src_span'(103,30,103,31,6216,1),'Ident (Prolog Variable)').
'symbol'('Flush','Flush','src_span'(119,1,119,6,7043,5),'Funktion or Process').
'symbol'('pos7','pos','src_span'(119,7,119,10,7049,3),'Ident (Prolog Variable)').
'symbol'('sp8','sp','src_span'(119,12,119,14,7054,2),'Ident (Prolog Variable)').
'symbol'('best8','best','src_span'(119,16,119,20,7058,4),'Ident (Prolog Variable)').
'symbol'('tok8','tok','src_span'(119,22,119,25,7064,3),'Ident (Prolog Variable)').
'symbol'('rdy7','rdy','src_span'(119,27,119,30,7069,3),'Ident (Prolog Variable)').
'symbol'('m169','m','src_span'(119,32,119,33,7074,1),'Ident (Prolog Variable)').
'symbol'('sc6','sc','src_span'(119,35,119,37,7077,2),'Ident (Prolog Variable)').
'symbol'('FlushReady','FlushReady','src_span'(125,1,125,11,7274,10),'Funktion or Process').
'symbol'('pos8','pos','src_span'(125,12,125,15,7285,3),'Ident (Prolog Variable)').
'symbol'('sp9','sp','src_span'(125,17,125,19,7290,2),'Ident (Prolog Variable)').
'symbol'('best9','best','src_span'(125,21,125,25,7294,4),'Ident (Prolog Variable)').
'symbol'('tok9','tok','src_span'(125,27,125,30,7300,3),'Ident (Prolog Variable)').
'symbol'('m175','m','src_span'(125,32,125,33,7305,1),'Ident (Prolog Variable)').
'symbol'('b5','b','src_span'(128,24,128,25,7405,1),'Ident (Prolog Variable)').
'symbol'('Next','Next','src_span'(131,1,131,5,7527,4),'Funktion or Process').
'symbol'('pos9','pos','src_span'(131,6,131,9,7532,3),'Ident (Prolog Variable)').
'symbol'('sp178','sp','src_span'(131,11,131,13,7537,2),'Ident (Prolog Variable)').
'symbol'('best179','best','src_span'(131,15,131,19,7541,4),'Ident (Prolog Variable)').
'symbol'('tok180','tok','src_span'(131,21,131,24,7547,3),'Ident (Prolog Variable)').
'symbol'('rdy8','rdy','src_span'(131,26,131,29,7552,3),'Ident (Prolog Variable)').
'symbol'('m182','m','src_span'(131,31,131,32,7557,1),'Ident (Prolog Variable)').
'symbol'('sc7','sc','src_span'(131,34,131,36,7560,2),'Ident (Prolog Variable)').
'symbol'('p7','p','src_span'(131,51,131,52,7577,1),'Ident (Prolog Variable)').
'symbol'('k5','k','src_span'(131,53,131,54,7579,1),'Ident (Prolog Variable)').
'symbol'('FREE','FREE','src_span'(135,1,135,5,7814,4),'Ident (Groundrep.)').
'symbol'('b6','b','src_span'(135,17,135,18,7830,1),'Ident (Prolog Variable)').
'symbol'('FREE_FULL','FREE_FULL','src_span'(136,1,136,10,7873,9),'Funktion or Process').
'symbol'('b7','b','src_span'(136,11,136,12,7883,1),'Ident (Prolog Variable)').
'symbol'('x2','x','src_span'(136,49,136,50,7921,1),'Ident (Prolog Variable)').
'symbol'('READY','READY','src_span'(138,1,138,6,7945,5),'Ident (Groundrep.)').
'symbol'('READY_FULL','READY_FULL','src_span'(139,1,139,11,8004,10),'Ident (Groundrep.)').
'symbol'('MainApp','MainApp','src_span'(141,1,141,8,8073,7),'Ident (Groundrep.)').
'symbol'('MainAppN','MainAppN','src_span'(142,1,142,9,8126,8),'Funktion or Process').
'symbol'('n','n','src_span'(142,10,142,11,8135,1),'Ident (Prolog Variable)').
'symbol'('Reporter','Reporter','src_span'(145,1,145,9,8304,8),'Ident (Groundrep.)').
'symbol'('r','r','src_span'(145,25,145,26,8328,1),'Ident (Prolog Variable)').
'symbol'('r2','r','src_span'(146,28,146,29,8401,1),'Ident (Prolog Variable)').
'symbol'('m192','m','src_span'(147,35,147,36,8466,1),'Ident (Prolog Variable)').
'symbol'('b8','b','src_span'(147,37,147,38,8468,1),'Ident (Prolog Variable)').
'symbol'('ReporterStall','ReporterStall','src_span'(149,1,149,14,8538,13),'Ident (Groundrep.)').
'symbol'('r3','r','src_span'(149,30,149,31,8567,1),'Ident (Prolog Variable)').
'symbol'('r4','r','src_span'(150,33,150,34,8663,1),'Ident (Prolog Variable)').
'symbol'('m196','m','src_span'(151,40,151,41,8738,1),'Ident (Prolog Variable)').
'symbol'('b9','b','src_span'(151,42,151,43,8740,1),'Ident (Prolog Variable)').
'symbol'('PIPE','PIPE','src_span'(154,1,154,5,8848,4),'Funktion or Process').
'symbol'('Src','Src','src_span'(154,6,154,9,8853,3),'Ident (Prolog Variable)').
'symbol'('Inf','Inf','src_span'(154,11,154,14,8858,3),'Ident (Prolog Variable)').
'symbol'('NETWORK','NETWORK','src_span'(155,1,155,8,8910,7),'Funktion or Process').
'symbol'('Src2','Src','src_span'(155,9,155,12,8918,3),'Ident (Prolog Variable)').
'symbol'('Inf2','Inf','src_span'(155,14,155,17,8923,3),'Ident (Prolog Variable)').
'symbol'('Rep','Rep','src_span'(155,19,155,22,8928,3),'Ident (Prolog Variable)').
'symbol'('Main','Main','src_span'(155,24,155,28,8933,4),'Ident (Prolog Variable)').
'symbol'('SYS','SYS','src_span'(159,1,159,4,9110,3),'Funktion or Process').
'symbol'('Src3','Src','src_span'(159,5,159,8,9114,3),'Ident (Prolog Variable)').
'symbol'('Inf3','Inf','src_span'(159,10,159,13,9119,3),'Ident (Prolog Variable)').
'symbol'('Rep2','Rep','src_span'(159,15,159,18,9124,3),'Ident (Prolog Variable)').
'symbol'('Main2','Main','src_span'(159,20,159,24,9129,4),'Ident (Prolog Variable)').
'symbol'('OBS','OBS','src_span'(163,1,163,4,9375,3),'Funktion or Process').
'symbol'('cam','cam','src_span'(163,5,163,8,9379,3),'Ident (Prolog Variable)').
'symbol'('pend','pend','src_span'(163,10,163,14,9384,4),'Ident (Prolog Variable)').
'symbol'('best210','best','src_span'(163,16,163,20,9390,4),'Ident (Prolog Variable)').
'symbol'('sp211','sp','src_span'(163,22,163,24,9396,2),'Ident (Prolog Variable)').
'symbol'('send','send','src_span'(163,26,163,30,9400,4),'Ident (Prolog Variable)').
'symbol'('slot','slot','src_span'(163,32,163,36,9406,4),'Ident (Prolog Variable)').
'symbol'('b214','b','src_span'(164,17,164,18,9430,1),'Ident (Prolog Variable)').
'symbol'('k6','k','src_span'(164,19,164,20,9432,1),'Ident (Prolog Variable)').
'symbol'('b216','b','src_span'(167,19,167,20,9649,1),'Ident (Prolog Variable)').
'symbol'('member','member','src_span'(167,44,167,50,9674,6),'BuiltIn primitive').
'symbol'('diff','diff','src_span'(168,49,168,53,9736,4),'BuiltIn primitive').
'symbol'('o','o','src_span'(169,13,169,14,9796,1),'Ident (Prolog Variable)').
'symbol'('b218','b','src_span'(169,15,169,16,9798,1),'Ident (Prolog Variable)').
'symbol'('b219','b','src_span'(173,15,173,16,10069,1),'Ident (Prolog Variable)').
'symbol'('m220','m','src_span'(174,25,174,26,10187,1),'Ident (Prolog Variable)').
'symbol'('b221','b','src_span'(174,27,174,28,10189,1),'Ident (Prolog Variable)').
'symbol'('b222','b','src_span'(176,14,176,15,10347,1),'Ident (Prolog Variable)').
'symbol'('b223','b','src_span'(177,15,177,16,10440,1),'Ident (Prolog Variable)').
'symbol'('ROLE_EVENTS','ROLE_EVENTS','src_span'(179,1,179,12,10535,11),'Ident (Groundrep.)').
'symbol'('OBSERVED','OBSERVED','src_span'(180,1,180,9,10637,8),'Funktion or Process').
'symbol'('P','P','src_span'(180,10,180,11,10646,1),'Ident (Prolog Variable)').
'symbol'('SRC_EVENTS','SRC_EVENTS','src_span'(10,1,10,11,589,10),'Ident (Groundrep.)').
'symbol'('SOURCE','SOURCE','src_span'(11,1,11,7,633,6),'Funktion or Process').
'symbol'('b225','b','src_span'(11,8,11,9,640,1),'Ident (Prolog Variable)').
'symbol'('k7','k','src_span'(11,18,11,19,650,1),'Ident (Prolog Variable)').
'symbol'('nb4','nb','src_span'(11,62,11,64,694,2),'Ident (Prolog Variable)').
'symbol'('diff','diff','src_span'(13,32,13,36,744,4),'BuiltIn primitive').
'symbol'('SYSTEM_FS','SYSTEM_FS','src_span'(17,1,17,10,892,9),'Ident (Groundrep.)').
'symbol'('MCOUNT','MCOUNT','src_span'(23,1,23,7,1094,6),'Funktion or Process').
'symbol'('k8','k','src_span'(23,8,23,9,1101,1),'Ident (Prolog Variable)').
'symbol'('b229','b','src_span'(25,38,25,39,1224,1),'Ident (Prolog Variable)').
'symbol'('INF_REPORTS','INF_REPORTS','src_span'(29,1,29,12,1341,11),'Ident (Groundrep.)').
'symbol'('TOKEN','TOKEN','src_span'(30,1,30,6,1420,5),'Ident (Groundrep.)').
'symbol'('r5','r','src_span'(30,13,30,14,1432,1),'Ident (Prolog Variable)').
'symbol'('CYCLE_F','CYCLE_F','src_span'(37,1,37,8,1836,7),'Ident (Groundrep.)').
'symbol'('b231','b','src_span'(37,16,37,17,1851,1),'Ident (Prolog Variable)').
'symbol'('k9','k','src_span'(37,25,37,26,1860,1),'Ident (Prolog Variable)').
'symbol'('SYSTEM_CAM','SYSTEM_CAM','src_span'(49,1,49,11,2686,10),'Ident (Groundrep.)').
'symbol'('CYCLE','CYCLE','src_span'(50,1,50,6,2741,5),'Ident (Groundrep.)').