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
'bindval'('MAX_INDEX','int'(2),'src_span'(2,1,2,14,16,13)).
'dataTypeDef'('prediction_t',['constructor'('person'),'constructor'('no_person')]).
'channel'('g_trigger_chan','type'('dotUnitType')).
'channel'('frame_chan','type'('dotTupleType'(['intType']))).
'channel'('result_chan','type'('dotTupleType'(['intType','prediction_t']))).
'channel'('print_','type'('dotUnitType')).
'bindval'('ENV','prefix'('src_span'(11,7,11,21,184,14),[],'g_trigger_chan','val_of'('ENV','src_span'(11,25,11,28,202,3)),'src_span'(11,22,11,24,198,21)),'src_span'(11,1,11,28,178,27)).
'agent'('Camera'(_c),'prefix'('src_span'(14,5,14,19,223,14),[],'g_trigger_chan','prefix'('src_span'(14,23,14,33,241,10),['out'(_c)],'frame_chan','agent_call'('src_span'(14,39,14,45,257,6),'Camera',['%'('+'(_c,'int'(1)),'val_of'('MAX_INDEX','src_span'(14,54,14,63,272,9)))]),'src_span'(14,36,14,38,253,31)),'src_span'(14,20,14,22,237,59)),'src_span'(14,5,14,64,223,59)).
'bindval'('Inference','prefix'('src_span'(17,5,17,15,300,10),['in'(_f)],'frame_chan','|~|'('prefix'('src_span'(19,14,19,25,339,11),['out'(_f),'out'('person')],'result_chan','val_of'('Inference','src_span'(19,38,19,47,363,9)),'src_span'(19,35,19,37,359,20)),'prefix'('src_span'(21,14,21,25,399,11),['out'(_f),'out'('no_person')],'result_chan','val_of'('Inference','src_span'(21,41,21,50,426,9)),'src_span'(21,38,21,40,422,23)),'src_span_operator'('no_loc_info_available','src_span'(20,9,20,12,382,3))),'src_span'(17,18,18,8,312,136)),'src_span'(16,1,22,10,284,162)).
'bindval'('Console','prefix'('src_span'(25,5,25,16,462,11),['in'(_f2),'in'(_p)],'result_chan','prefix'('src_span'(25,24,25,30,481,6),[],'print_','val_of'('Console','src_span'(25,34,25,41,491,7)),'src_span'(25,31,25,33,487,17)),'src_span'(25,21,25,23,477,23)),'src_span'(24,1,25,41,448,50)).
'bindval'('NEUROPATHWAY','sharing'('closure'(['frame_chan']),'agent_call'('src_span'(28,5,28,11,519,6),'Camera',['int'(0)]),'sharing'('closure'(['result_chan']),'val_of'('Inference','src_span'(30,6,30,15,565,9)),'val_of'('Console','src_span'(30,40,30,47,599,7)),'src_span'(30,16,30,39,575,23)),'src_span'(29,9,29,31,537,22)),'src_span'(27,1,30,48,500,107)).
'bindval'('SYSTEM','sharing'('closure'(['g_trigger_chan']),'val_of'('ENV','src_span'(33,5,33,8,622,3)),'val_of'('NEUROPATHWAY','src_span'(33,36,33,48,653,12)),'src_span'(33,9,33,35,626,26)),'src_span'(32,1,33,48,609,56)).
'assertModelCheckExt'('False','val_of'('SYSTEM','src_span'(36,8,36,14,692,6)),'DeadlockFree','F').
'assertModelCheck'('False','val_of'('SYSTEM','src_span'(37,8,37,14,726,6)),'LivelockFree').
'comment'('lineComment'('-- Neuropathway'),'src_position'(1,1,0,15)).
'comment'('lineComment'('-- Sanity checks:'),'src_position'(35,1,667,17)).
'symbol'('MAX_INDEX','MAX_INDEX','src_span'(2,1,2,10,16,9),'Ident (Groundrep.)').
'symbol'('prediction_t','prediction_t','src_span'(4,10,4,22,40,12),'Datatype').
'symbol'('person','person','src_span'(4,25,4,31,55,6),'Constructor of Datatype').
'symbol'('no_person','no_person','src_span'(4,34,4,43,64,9),'Constructor of Datatype').
'symbol'('g_trigger_chan','g_trigger_chan','src_span'(6,9,6,23,83,14),'Channel').
'symbol'('frame_chan','frame_chan','src_span'(7,9,7,19,106,10),'Channel').
'symbol'('result_chan','result_chan','src_span'(8,9,8,20,131,11),'Channel').
'symbol'('print_','print_','src_span'(9,9,9,15,170,6),'Channel').
'symbol'('ENV','ENV','src_span'(11,1,11,4,178,3),'Ident (Groundrep.)').
'symbol'('Camera','Camera','src_span'(13,1,13,7,207,6),'Funktion or Process').
'symbol'('c','c','src_span'(13,8,13,9,214,1),'Ident (Prolog Variable)').
'symbol'('Inference','Inference','src_span'(16,1,16,10,284,9),'Ident (Groundrep.)').
'symbol'('f','f','src_span'(17,16,17,17,311,1),'Ident (Prolog Variable)').
'symbol'('Console','Console','src_span'(24,1,24,8,448,7),'Ident (Groundrep.)').
'symbol'('f2','f','src_span'(25,17,25,18,474,1),'Ident (Prolog Variable)').
'symbol'('p','p','src_span'(25,19,25,20,476,1),'Ident (Prolog Variable)').
'symbol'('NEUROPATHWAY','NEUROPATHWAY','src_span'(27,1,27,13,500,12),'Ident (Groundrep.)').
'symbol'('SYSTEM','SYSTEM','src_span'(32,1,32,7,609,6),'Ident (Groundrep.)').