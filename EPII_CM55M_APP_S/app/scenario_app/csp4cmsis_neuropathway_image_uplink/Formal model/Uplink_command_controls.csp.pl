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
'bindval'('W','int'(2),'src_span'(10,1,10,6,688,5)).
'dataTypeDef'('report_t',['constructor'('started'),'constructor'('stack'),'constructor'('scores'),'constructor'('window'),'constructor'('applied'),'constructor'('rejected')]).
'bindval'('INF_REPORTS','setExp'('rangeEnum'(['scores','window','applied'])),'src_span'(14,1,14,40,771,39)).
'bindval'('OTHER','setExp'('rangeEnum'(['started','stack','rejected'])),'src_span'(15,1,15,41,811,40)).
'channel'('g_trigger_chan','type'('dotUnitType')).
'channel'('frame_chan','type'('dotTupleType'(['setExp'('rangeClosed'('int'(0),'-'('val_of'('W','src_span'(18,28,18,29,962,1)),'int'(1)))),'boolType']))).
'channel'('release_chan','type'('dotUnitType')).
'channel'('ready_in','type'('dotUnitType')).
'channel'('ready_out','type'('dotUnitType')).
'channel'('ready_empty','type'('dotUnitType')).
'channel'('rx','type'('dotUnitType')).
'channel'('cmd_in','type'('dotUnitType')).
'channel'('cmd_out','type'('dotUnitType')).
'channel'('cmd_empty','type'('dotUnitType')).
'channel'('sensor_write','type'('dotUnitType')).
'channel'('report_chan','type'('dotTupleType'(['report_t']))).
'channel'('line','type'('dotTupleType'(['report_t']))).
'channel'('stack_tick','type'('dotUnitType')).
'channel'('overflow','type'('dotUnitType')).
'bindval'('ENV','prefix'('src_span'(32,7,32,21,1852,14),[],'g_trigger_chan','val_of'('ENV','src_span'(32,25,32,28,1870,3)),'src_span'(32,22,32,24,1866,21)),'src_span'(32,1,32,28,1846,27)).
'agent'('RUN'(_A),'repChoice'(['comprehensionGenerator'(_x,_A)],'prefix'('src_span'(34,21,34,22,1895,1),[],_x,'agent_call'('src_span'(34,26,34,29,1900,3),'RUN',[_A]),'src_span'(34,23,34,25,1896,11)),'src_span'(34,13,34,20,1887,7)),'src_span'(34,10,34,32,1884,22)).
'bindval'('Camera','prefix'('src_span'(38,10,38,21,2086,11),['out'('started')],'report_chan','agent_call'('src_span'(38,33,38,43,2109,10),'CameraLoop',['int'(0),'false']),'src_span'(38,30,38,32,2105,32)),'src_span'(38,1,38,53,2077,52)).
'agent'('CameraLoop'(_i,_a),'prefix'('src_span'(39,20,39,34,2149,14),[],'g_trigger_chan','prefix'('src_span'(39,38,39,48,2167,10),['out'(_i),'out'(_a)],'frame_chan','agent_call'('src_span'(39,56,39,60,2185,4),'Poll',[_i]),'src_span'(39,53,39,55,2181,13)),'src_span'(39,35,39,37,2163,43)),'src_span'(39,20,39,63,2149,43)).
'agent'('Poll'(_i2),'[]'('prefix'('src_span'(40,12,40,19,2204,7),[],'cmd_out','prefix'('src_span'(40,23,40,35,2215,12),[],'sensor_write','prefix'('src_span'(40,39,40,51,2231,12),[],'release_chan','agent_call'('src_span'(40,55,40,65,2247,10),'CameraLoop',['%'('+'(_i2,'int'(1)),'val_of'('W','src_span'(40,76,40,77,2268,1))),'true']),'src_span'(40,52,40,54,2243,45)),'src_span'(40,36,40,38,2227,61)),'src_span'(40,20,40,22,2211,72)),'prefix'('src_span'(41,15,41,24,2292,9),[],'cmd_empty','prefix'('src_span'(41,28,41,40,2305,12),[],'release_chan','agent_call'('src_span'(41,44,41,54,2321,10),'CameraLoop',['%'('+'(_i2,'int'(1)),'val_of'('W','src_span'(41,65,41,66,2342,1))),'false']),'src_span'(41,41,41,43,2317,46)),'src_span'(41,25,41,27,2301,59)),'src_span_operator'('no_loc_info_available','src_span'(41,11,41,13,2288,2))),'no_loc_info_available').
'bindval'('Inference','prefix'('src_span'(46,13,46,23,2624,10),['in'(_i3),'in'(_a2)],'frame_chan','agent_call'('src_span'(46,31,46,36,2642,5),'Infer',[_i3,_a2,'true']),'src_span'(46,28,46,30,2638,23)),'src_span'(46,1,46,48,2612,47)).
'agent'('Infer'(_i4,_q,_rdy),'[]'('prefix'('src_span'(47,21,47,30,2680,9),[],'ready_out','agent_call'('src_span'(47,34,47,46,2693,12),'InferRelease',[_i4,_q,'true']),'src_span'(47,31,47,33,2689,37)),'prefix'('src_span'(47,64,47,75,2723,11),[],'ready_empty','agent_call'('src_span'(47,79,47,91,2738,12),'InferRelease',[_i4,_q,_rdy]),'src_span'(47,76,47,78,2734,38)),'src_span_operator'('no_loc_info_available','src_span'(47,60,47,62,2719,2))),'no_loc_info_available').
'agent'('InferRelease'(_i5,_q2,_rdy2),'prefix'('src_span'(48,27,48,39,2789,12),[],'release_chan','agent_call'('src_span'(48,43,48,51,2805,8),'InferEnd',[_i5,_q2,_rdy2]),'src_span'(48,40,48,42,2801,35)),'src_span'(48,27,48,62,2789,35)).
'agent'('InferEnd'(_i6,_q3,_rdy3),'ifte'(_rdy3,'ifte'('=='(_i6,'-'('val_of'('W','src_span'(51,17,51,18,2879,1)),'int'(1))),'prefix'('src_span'(51,28,51,39,2890,11),['out'('window')],'report_chan','agent_call'('src_span'(51,50,51,59,2912,9),'InferNext',[_q3,'false']),'src_span'(51,47,51,49,2908,30)),'ifte'(_q3,'prefix'('src_span'(52,24,52,35,2955,11),['out'('applied')],'report_chan','agent_call'('src_span'(52,47,52,56,2978,9),'InferNext',['false','false']),'src_span'(52,44,52,46,2974,35)),'prefix'('src_span'(53,14,53,25,3015,11),['out'('scores')],'report_chan','agent_call'('src_span'(53,36,53,45,3037,9),'InferNext',[_q3,'false']),'src_span'(53,33,53,35,3033,30)),'src_span'(52,14,52,18,2945,4),'src_span'(52,19,52,23,2949,53),'src_span'(52,71,53,13,3001,101)),'no_loc_info_available','no_loc_info_available','src_span'(51,70,52,13,2931,166)),'agent_call'('src_span'(54,10,54,19,3066,9),'InferNext',[_q3,_rdy3]),'src_span'(50,5,50,11,2851,6),'src_span'(50,12,51,8,2857,202),'src_span'(53,56,54,9,3056,212)),'src_span'(50,5,54,27,2851,232)).
'agent'('InferNext'(_q4,_rdy4),'prefix'('src_span'(55,21,55,31,3104,10),['in'(_j),'in'(_a3)],'frame_chan','agent_call'('src_span'(55,39,55,44,3122,5),'Infer',[_j,'bool_or'(_q4,_a3),_rdy4]),'src_span'(55,36,55,38,3118,27)),'src_span'(55,21,55,60,3104,39)).
'bindval'('READY','[]'('prefix'('src_span'(57,10,57,18,3154,8),[],'ready_in','val_of'('READY_FULL','src_span'(57,22,57,32,3166,10)),'src_span'(57,19,57,21,3162,22)),'prefix'('src_span'(57,38,57,49,3182,11),[],'ready_empty','val_of'('READY','src_span'(57,53,57,58,3197,5)),'src_span'(57,50,57,52,3193,20)),'src_span_operator'('no_loc_info_available','src_span'(57,34,57,36,3178,2))),'src_span'(57,1,57,59,3145,58)).
'bindval'('READY_FULL','[]'('prefix'('src_span'(58,15,58,24,3218,9),[],'ready_out','val_of'('READY','src_span'(58,28,58,33,3231,5)),'src_span'(58,25,58,27,3227,18)),'prefix'('src_span'(58,39,58,47,3242,8),[],'ready_in','prefix'('src_span'(58,51,58,59,3254,8),[],'overflow','stop'('src_span'(58,63,58,67,3266,4)),'src_span'(58,60,58,62,3262,16)),'src_span'(58,48,58,50,3250,28)),'src_span_operator'('no_loc_info_available','src_span'(58,35,58,37,3238,2))),'src_span'(58,1,58,68,3204,67)).
'bindval'('CMD','[]'('prefix'('src_span'(60,8,60,14,3280,6),[],'cmd_in','val_of'('CMD_FULL','src_span'(60,18,60,26,3290,8)),'src_span'(60,15,60,17,3286,18)),'prefix'('src_span'(60,32,60,41,3304,9),[],'cmd_empty','val_of'('CMD','src_span'(60,45,60,48,3317,3)),'src_span'(60,42,60,44,3313,16)),'src_span_operator'('no_loc_info_available','src_span'(60,28,60,30,3300,2))),'src_span'(60,1,60,49,3273,48)).
'bindval'('CMD_FULL','prefix'('src_span'(61,12,61,19,3333,7),[],'cmd_out','val_of'('CMD','src_span'(61,23,61,26,3344,3)),'src_span'(61,20,61,22,3340,14)),'src_span'(61,1,61,26,3322,25)).
'bindval'('MainApp','prefix'('src_span'(63,11,63,21,3359,10),[],'stack_tick','prefix'('src_span'(63,25,63,36,3373,11),['out'('stack')],'report_chan','val_of'('MainApp','src_span'(63,46,63,53,3394,7)),'src_span'(63,43,63,45,3390,17)),'src_span'(63,22,63,24,3369,42)),'src_span'(63,1,63,53,3349,52)).
'agent'('MainAppN'(_n),'ifte'('=='(_n,'int'(0)),'stop'('src_span'(64,30,64,34,3431,4)),'prefix'('src_span'(64,40,64,50,3441,10),[],'stack_tick','prefix'('src_span'(64,54,64,65,3455,11),['out'('stack')],'report_chan','agent_call'('src_span'(64,75,64,83,3476,8),'MainAppN',['-'(_n,'int'(1))]),'src_span'(64,72,64,74,3472,25)),'src_span'(64,51,64,53,3451,50)),'no_loc_info_available','no_loc_info_available','src_span'(64,35,64,39,3435,60)),'src_span'(64,15,64,90,3416,75)).
'bindval'('Command','prefix'('src_span'(69,11,69,13,3728,2),[],'rx','|~|'('prefix'('src_span'(69,19,69,25,3736,6),[],'cmd_in','val_of'('Command','src_span'(69,29,69,36,3746,7)),'src_span'(69,26,69,28,3742,17)),'prefix'('src_span'(69,43,69,54,3760,11),['out'('rejected')],'report_chan','val_of'('Command','src_span'(69,67,69,74,3784,7)),'src_span'(69,64,69,66,3780,20)),'src_span_operator'('no_loc_info_available','src_span'(69,38,69,41,3755,3))),'src_span'(69,14,69,16,3730,65)),'src_span'(69,1,69,76,3718,75)).
'agent'('CommandN'(_n2),'ifte'('=='(_n2,'int'(0)),'stop'('src_span'(70,30,70,34,3823,4)),'prefix'('src_span'(70,40,70,42,3833,2),[],'rx','|~|'('prefix'('src_span'(70,48,70,54,3841,6),[],'cmd_in','agent_call'('src_span'(70,58,70,66,3851,8),'CommandN',['-'(_n2,'int'(1))]),'src_span'(70,55,70,57,3847,25)),'prefix'('src_span'(70,80,70,91,3873,11),['out'('rejected')],'report_chan','agent_call'('src_span'(70,104,70,112,3897,8),'CommandN',['-'(_n2,'int'(1))]),'src_span'(70,101,70,103,3893,28)),'src_span_operator'('no_loc_info_available','src_span'(70,75,70,78,3868,3))),'src_span'(70,43,70,45,3835,81)),'no_loc_info_available','no_loc_info_available','src_span'(70,35,70,39,3827,91)),'src_span'(70,15,70,121,3808,106)).
'bindval'('CommandValid','prefix'('src_span'(71,16,71,18,3930,2),[],'rx','prefix'('src_span'(71,22,71,28,3936,6),[],'cmd_in','val_of'('CommandValid','src_span'(71,32,71,44,3946,12)),'src_span'(71,29,71,31,3942,22)),'src_span'(71,19,71,21,3932,28)),'src_span'(71,1,71,44,3915,43)).
'bindval'('CommandNone','stop'('src_span'(72,15,72,19,3973,4)),'src_span'(72,1,72,19,3959,18)).
'bindval'('Reporter','[]'('prefix'('src_span'(74,13,74,24,3991,11),['inGuard'(_r,'val_of'('INF_REPORTS','src_span'(74,27,74,38,4005,11)))],'report_chan','prefix'('src_span'(74,42,74,46,4020,4),['out'(_r)],'line','prefix'('src_span'(74,52,74,60,4030,8),[],'ready_in','val_of'('Reporter','src_span'(74,64,74,72,4042,8)),'src_span'(74,61,74,63,4038,20)),'src_span'(74,49,74,51,4026,26)),'src_span'(74,39,74,41,4016,48)),'prefix'('src_span'(75,16,75,27,4067,11),['inGuard'(_r2,'val_of'('OTHER','src_span'(75,30,75,35,4081,5)))],'report_chan','prefix'('src_span'(75,39,75,43,4090,4),['out'(_r2)],'line','val_of'('Reporter','src_span'(75,49,75,57,4100,8)),'src_span'(75,46,75,48,4096,14)),'src_span'(75,36,75,38,4086,30)),'src_span_operator'('no_loc_info_available','src_span'(75,12,75,14,4063,2))),'src_span'(74,1,75,58,3979,130)).
'bindval'('ReporterStall','[]'('prefix'('src_span'(76,18,76,29,4127,11),['inGuard'(_r3,'val_of'('INF_REPORTS','src_span'(76,32,76,43,4141,11)))],'report_chan','prefix'('src_span'(76,47,76,51,4156,4),['out'(_r3)],'line','|~|'('prefix'('src_span'(76,59,76,67,4168,8),[],'ready_in','val_of'('ReporterStall','src_span'(76,71,76,84,4180,13)),'src_span'(76,68,76,70,4176,25)),'stop'('src_span'(76,90,76,94,4199,4)),'src_span_operator'('no_loc_info_available','src_span'(76,86,76,89,4195,3))),'src_span'(76,54,76,56,4162,44)),'src_span'(76,44,76,46,4152,66)),'prefix'('src_span'(77,21,77,32,4226,11),['inGuard'(_r4,'val_of'('OTHER','src_span'(77,35,77,40,4240,5)))],'report_chan','prefix'('src_span'(77,44,77,48,4249,4),['out'(_r4)],'line','val_of'('ReporterStall','src_span'(77,54,77,67,4259,13)),'src_span'(77,51,77,53,4255,19)),'src_span'(77,41,77,43,4245,35)),'src_span_operator'('no_loc_info_available','src_span'(77,17,77,19,4222,2))),'src_span'(76,1,77,68,4110,163)).
'agent'('NET'(_Cam,_Rep,_Main,_Cmd),'sharing'('closure'(['cmd_in','cmd_out','cmd_empty']),'sharing'('closure'(['ready_in','ready_out','ready_empty']),'sharing'('closure'(['report_chan']),'|||'('|||'('sharing'('closure'(['frame_chan','release_chan']),_Cam,'val_of'('Inference','src_span'(80,51,80,60,4352,9)),'src_span'(80,14,80,50,4315,36)),_Main,'src_span_operator'('no_loc_info_available','src_span'(80,62,80,65,4363,3))),_Cmd,'src_span_operator'('no_loc_info_available','src_span'(80,71,80,74,4372,3))),_Rep,'src_span'(81,8,81,31,4388,23)),'val_of'('READY','src_span'(82,52,82,57,4468,5)),'src_span'(82,7,82,51,4423,44)),'val_of'('CMD','src_span'(83,45,83,48,4519,3)),'src_span'(83,6,83,44,4480,38)),'src_span'(80,5,83,49,4306,217)).
'agent'('SYS'(_Cam2,_Rep2,_Main2,_Cmd2),'sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(84,28,84,31,4551,3)),'agent_call'('src_span'(84,59,84,62,4582,3),'NET',[_Cam2,_Rep2,_Main2,_Cmd2]),'src_span'(84,32,84,58,4555,26)),'src_span'(84,32,84,58,4555,26)).
'bindval'('CYCLE','prefix'('src_span'(86,9,86,23,4616,14),[],'g_trigger_chan','val_of'('CYCLE','src_span'(86,27,86,32,4634,5)),'src_span'(86,24,86,26,4630,23)),'src_span'(86,1,86,32,4608,31)).
'bindval'('Camera3','prefix'('src_span'(7,11,7,22,265,11),['out'('started')],'report_chan','agent_call'('src_span'(7,34,7,45,288,11),'CameraLoop3',['int'(0)]),'src_span'(7,31,7,33,284,26)),'src_span'(7,1,7,48,255,47)).
'agent'('CameraLoop3'(_i7),'prefix'('src_span'(8,18,8,32,320,14),[],'g_trigger_chan','prefix'('src_span'(8,36,8,46,338,10),['out'(_i7),'out'('true')],'frame_chan','prefix'('src_span'(8,57,8,64,359,7),[],'cmd_out','prefix'('src_span'(8,68,8,80,370,12),[],'sensor_write','prefix'('src_span'(8,84,8,96,386,12),[],'release_chan','agent_call'('src_span'(9,18,9,29,419,11),'CameraLoop3',['%'('+'(_i7,'int'(1)),'val_of'('W','src_span'(9,40,9,41,441,1)))]),'src_span'(8,97,9,17,398,57)),'src_span'(8,81,8,83,382,73)),'src_span'(8,65,8,67,366,84)),'src_span'(8,54,8,56,355,93)),'src_span'(8,33,8,35,334,123)),'src_span'(8,18,9,42,320,123)).
'assertRef'('False','val_of'('CYCLE','src_span'(11,8,11,13,452,5)),'FailureDivergence','\x5c\'('agent_call'('src_span'(11,19,11,22,463,3),'SYS',['val_of'('Camera3','src_span'(11,23,11,30,467,7)),'val_of'('Reporter','src_span'(11,32,11,40,476,8)),'agent_call'('src_span'(11,42,11,50,486,8),'MainAppN',['int'(2)]),'val_of'('CommandNone','src_span'(11,55,11,66,499,11))]),'agent_call'('src_span'(11,70,11,74,514,4),'diff',['Events','setExp'('rangeEnum'(['g_trigger_chan']))]),'src_span_operator'('no_loc_info_available','src_span'(11,68,11,69,512,1))),'src_span'(11,1,11,100,445,99)).
'comment'('lineComment'('-- Positive control for Uplink_command.csp: must FAIL its check.'),'src_position'(1,1,0,64)).
'comment'('lineComment'('-- The command path of csp4cmsis_neuropathway_image_uplink, definitions shared by'),'src_position'(1,1,0,81)).
'comment'('lineComment'('-- Uplink_command.csp and Uplink_command_controls.csp. Command reads command lines from the'),'src_position'(2,1,82,91)).
'comment'('lineComment'('-- console UART (rx), writes valid ones to cmd_chan (one slot) and reports invalid ones on'),'src_position'(3,1,174,90)).
'comment'('lineComment'('-- report_chan. Camera polls cmd_chan once per frame, writes the sensor and marks the next frame;'),'src_position'(4,1,265,97)).
'comment'('lineComment'('-- Inference acknowledges with a report of its own under the ready token.'),'src_position'(5,1,363,73)).
'comment'('lineComment'('-- The JPEG buffers are left out (Uplink.csp checks them): Inference here keeps only what the'),'src_position'(6,1,437,93)).
'comment'('lineComment'('-- command path touches, the ready token, the window position and a pending acknowledgement.'),'src_position'(7,1,531,92)).
'comment'('lineComment'('-- Windows of W = 2 frames; a command is abstract (one value).'),'src_position'(8,1,624,62)).
'comment'('lineComment'('-- frame-ready interrupt -> Camera'),'src_position'(17,48,900,34)).
'comment'('lineComment'('-- Camera -> Inference: position in the window,'),'src_position'(18,48,982,47)).
'comment'('lineComment'('-- a setting was written before this frame'),'src_position'(19,48,1077,42)).
'comment'('lineComment'('-- Inference -> Camera: raw buffer free'),'src_position'(20,48,1167,39)).
'comment'('lineComment'('-- ready_chan (one slot), as in Uplink.csp'),'src_position'(21,48,1254,42)).
'comment'('lineComment'('-- a command line arrives on the console UART'),'src_position'(22,48,1344,45)).
'comment'('lineComment'('-- Command -> cmd_chan\x27\s slot'),'src_position'(23,48,1437,29)).
'comment'('lineComment'('-- cmd_chan\x27\s slot -> Camera (poll, value ready)'),'src_position'(24,48,1514,48)).
'comment'('lineComment'('-- cmd_chan\x27\s slot -> Camera (poll, SKIP taken)'),'src_position'(25,48,1610,47)).
'comment'('lineComment'('-- Camera writes the sensor\x27\s registers'),'src_position'(26,48,1705,39)).
'comment'('lineComment'('-- Camera: after passing a frame on it polls cmd_chan (PRI ALT with SKIP): a command is'),'src_position'(36,1,1908,87)).
'comment'('lineComment'('-- applied to the sensor and marked on the next frame; an empty slot is skipped.'),'src_position'(37,1,1996,80)).
'comment'('lineComment'('-- Inference: q = an acknowledgement is pending, rdy = holds the ready token. With the token it'),'src_position'(43,1,2354,95)).
'comment'('lineComment'('-- writes one report per frame: the Window report at a window end, else a pending'),'src_position'(44,1,2450,81)).
'comment'('lineComment'('-- acknowledgement, else Scores. Without it, the acknowledgement stays pending.'),'src_position'(45,1,2532,79)).
'comment'('lineComment'('-- Command: each line received is either valid (to cmd_chan) or rejected (a report). Command:'),'src_position'(66,1,3493,93)).
'comment'('lineComment'('-- lines for ever; CommandN(n): n lines; CommandValid: valid lines for ever, each of which needs'),'src_position'(67,1,3587,96)).
'comment'('lineComment'('-- a frame; CommandNone: no line.'),'src_position'(68,1,3684,33)).
'comment'('lineComment'('-- Control 3 (must stall Camera when no command arrives): Camera reads cmd_chan with a blocking'),'src_position'(5,1,101,95)).
'comment'('lineComment'('-- read after each frame instead of polling it with SKIP.'),'src_position'(6,1,197,57)).
'comment'('lineComment'('-- expected: false'),'src_position'(11,103,547,18)).
'symbol'('W','W','src_span'(10,1,10,2,688,1),'Ident (Groundrep.)').
'symbol'('report_t','report_t','src_span'(12,10,12,18,704,8),'Datatype').
'symbol'('started','started','src_span'(12,21,12,28,715,7),'Constructor of Datatype').
'symbol'('stack','stack','src_span'(12,31,12,36,725,5),'Constructor of Datatype').
'symbol'('scores','scores','src_span'(12,39,12,45,733,6),'Constructor of Datatype').
'symbol'('window','window','src_span'(12,48,12,54,742,6),'Constructor of Datatype').
'symbol'('applied','applied','src_span'(12,57,12,64,751,7),'Constructor of Datatype').
'symbol'('rejected','rejected','src_span'(12,67,12,75,761,8),'Constructor of Datatype').
'symbol'('INF_REPORTS','INF_REPORTS','src_span'(14,1,14,12,771,11),'Ident (Groundrep.)').
'symbol'('OTHER','OTHER','src_span'(15,1,15,6,811,5),'Ident (Groundrep.)').
'symbol'('g_trigger_chan','g_trigger_chan','src_span'(17,9,17,23,861,14),'Channel').
'symbol'('frame_chan','frame_chan','src_span'(18,9,18,19,943,10),'Channel').
'symbol'('release_chan','release_chan','src_span'(20,9,20,21,1128,12),'Channel').
'symbol'('ready_in','ready_in','src_span'(21,9,21,17,1215,8),'Channel').
'symbol'('ready_out','ready_out','src_span'(21,19,21,28,1225,9),'Channel').
'symbol'('ready_empty','ready_empty','src_span'(21,30,21,41,1236,11),'Channel').
'symbol'('rx','rx','src_span'(22,9,22,11,1305,2),'Channel').
'symbol'('cmd_in','cmd_in','src_span'(23,9,23,15,1398,6),'Channel').
'symbol'('cmd_out','cmd_out','src_span'(24,9,24,16,1475,7),'Channel').
'symbol'('cmd_empty','cmd_empty','src_span'(25,9,25,18,1571,9),'Channel').
'symbol'('sensor_write','sensor_write','src_span'(26,9,26,21,1666,12),'Channel').
'symbol'('report_chan','report_chan','src_span'(27,9,27,20,1753,11),'Channel').
'symbol'('line','line','src_span'(28,9,28,13,1785,4),'Channel').
'symbol'('stack_tick','stack_tick','src_span'(29,9,29,19,1817,10),'Channel').
'symbol'('overflow','overflow','src_span'(30,9,30,17,1836,8),'Channel').
'symbol'('ENV','ENV','src_span'(32,1,32,4,1846,3),'Ident (Groundrep.)').
'symbol'('RUN','RUN','src_span'(34,1,34,4,1875,3),'Funktion or Process').
'symbol'('A','A','src_span'(34,5,34,6,1879,1),'Ident (Prolog Variable)').
'symbol'('x','x','src_span'(34,13,34,14,1887,1),'Ident (Prolog Variable)').
'symbol'('Camera','Camera','src_span'(38,1,38,7,2077,6),'Ident (Groundrep.)').
'symbol'('CameraLoop','CameraLoop','src_span'(39,1,39,11,2130,10),'Funktion or Process').
'symbol'('i','i','src_span'(39,12,39,13,2141,1),'Ident (Prolog Variable)').
'symbol'('a','a','src_span'(39,15,39,16,2144,1),'Ident (Prolog Variable)').
'symbol'('Poll','Poll','src_span'(40,1,40,5,2193,4),'Funktion or Process').
'symbol'('i2','i','src_span'(40,6,40,7,2198,1),'Ident (Prolog Variable)').
'symbol'('Inference','Inference','src_span'(46,1,46,10,2612,9),'Ident (Groundrep.)').
'symbol'('i3','i','src_span'(46,24,46,25,2635,1),'Ident (Prolog Variable)').
'symbol'('a2','a','src_span'(46,26,46,27,2637,1),'Ident (Prolog Variable)').
'symbol'('Infer','Infer','src_span'(47,1,47,6,2660,5),'Funktion or Process').
'symbol'('i4','i','src_span'(47,7,47,8,2666,1),'Ident (Prolog Variable)').
'symbol'('q','q','src_span'(47,10,47,11,2669,1),'Ident (Prolog Variable)').
'symbol'('rdy','rdy','src_span'(47,13,47,16,2672,3),'Ident (Prolog Variable)').
'symbol'('InferRelease','InferRelease','src_span'(48,1,48,13,2763,12),'Funktion or Process').
'symbol'('i5','i','src_span'(48,14,48,15,2776,1),'Ident (Prolog Variable)').
'symbol'('q2','q','src_span'(48,17,48,18,2779,1),'Ident (Prolog Variable)').
'symbol'('rdy2','rdy','src_span'(48,20,48,23,2782,3),'Ident (Prolog Variable)').
'symbol'('InferEnd','InferEnd','src_span'(49,1,49,9,2825,8),'Funktion or Process').
'symbol'('i6','i','src_span'(49,10,49,11,2834,1),'Ident (Prolog Variable)').
'symbol'('q3','q','src_span'(49,13,49,14,2837,1),'Ident (Prolog Variable)').
'symbol'('rdy3','rdy','src_span'(49,16,49,19,2840,3),'Ident (Prolog Variable)').
'symbol'('InferNext','InferNext','src_span'(55,1,55,10,3084,9),'Funktion or Process').
'symbol'('q4','q','src_span'(55,11,55,12,3094,1),'Ident (Prolog Variable)').
'symbol'('rdy4','rdy','src_span'(55,14,55,17,3097,3),'Ident (Prolog Variable)').
'symbol'('j','j','src_span'(55,32,55,33,3115,1),'Ident (Prolog Variable)').
'symbol'('a3','a','src_span'(55,34,55,35,3117,1),'Ident (Prolog Variable)').
'symbol'('READY','READY','src_span'(57,1,57,6,3145,5),'Ident (Groundrep.)').
'symbol'('READY_FULL','READY_FULL','src_span'(58,1,58,11,3204,10),'Ident (Groundrep.)').
'symbol'('CMD','CMD','src_span'(60,1,60,4,3273,3),'Ident (Groundrep.)').
'symbol'('CMD_FULL','CMD_FULL','src_span'(61,1,61,9,3322,8),'Ident (Groundrep.)').
'symbol'('MainApp','MainApp','src_span'(63,1,63,8,3349,7),'Ident (Groundrep.)').
'symbol'('MainAppN','MainAppN','src_span'(64,1,64,9,3402,8),'Funktion or Process').
'symbol'('n','n','src_span'(64,10,64,11,3411,1),'Ident (Prolog Variable)').
'symbol'('Command','Command','src_span'(69,1,69,8,3718,7),'Ident (Groundrep.)').
'symbol'('CommandN','CommandN','src_span'(70,1,70,9,3794,8),'Funktion or Process').
'symbol'('n2','n','src_span'(70,10,70,11,3803,1),'Ident (Prolog Variable)').
'symbol'('CommandValid','CommandValid','src_span'(71,1,71,13,3915,12),'Ident (Groundrep.)').
'symbol'('CommandNone','CommandNone','src_span'(72,1,72,12,3959,11),'Ident (Groundrep.)').
'symbol'('Reporter','Reporter','src_span'(74,1,74,9,3979,8),'Ident (Groundrep.)').
'symbol'('r','r','src_span'(74,25,74,26,4003,1),'Ident (Prolog Variable)').
'symbol'('r2','r','src_span'(75,28,75,29,4079,1),'Ident (Prolog Variable)').
'symbol'('ReporterStall','ReporterStall','src_span'(76,1,76,14,4110,13),'Ident (Groundrep.)').
'symbol'('r3','r','src_span'(76,30,76,31,4139,1),'Ident (Prolog Variable)').
'symbol'('r4','r','src_span'(77,33,77,34,4238,1),'Ident (Prolog Variable)').
'symbol'('NET','NET','src_span'(79,1,79,4,4275,3),'Funktion or Process').
'symbol'('Cam','Cam','src_span'(79,5,79,8,4279,3),'Ident (Prolog Variable)').
'symbol'('Rep','Rep','src_span'(79,10,79,13,4284,3),'Ident (Prolog Variable)').
'symbol'('Main','Main','src_span'(79,15,79,19,4289,4),'Ident (Prolog Variable)').
'symbol'('Cmd','Cmd','src_span'(79,21,79,24,4295,3),'Ident (Prolog Variable)').
'symbol'('SYS','SYS','src_span'(84,1,84,4,4524,3),'Funktion or Process').
'symbol'('Cam2','Cam','src_span'(84,5,84,8,4528,3),'Ident (Prolog Variable)').
'symbol'('Rep2','Rep','src_span'(84,10,84,13,4533,3),'Ident (Prolog Variable)').
'symbol'('Main2','Main','src_span'(84,15,84,19,4538,4),'Ident (Prolog Variable)').
'symbol'('Cmd2','Cmd','src_span'(84,21,84,24,4544,3),'Ident (Prolog Variable)').
'symbol'('CYCLE','CYCLE','src_span'(86,1,86,6,4608,5),'Ident (Groundrep.)').
'symbol'('Camera3','Camera3','src_span'(7,1,7,8,255,7),'Ident (Groundrep.)').
'symbol'('CameraLoop3','CameraLoop3','src_span'(8,1,8,12,303,11),'Funktion or Process').
'symbol'('i7','i','src_span'(8,13,8,14,315,1),'Ident (Prolog Variable)').
'symbol'('diff','diff','src_span'(11,70,11,74,514,4),'BuiltIn primitive').