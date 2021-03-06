-module(ts_telnet_registration). 
-export([ create_parser_list/1, test_commandstring/4, create_command_list/1, 
          get_command_list/1, get_command_execution_list/1, get_completion_list/1,
          get_option_list/1]).
-include("ts_command.hrl").
-include("ts_telnet.hrl").


test_commandstring(NodeID, CommandlineString, Match_fun, FilterHidden)->
    case ets:lookup(commandTable, NodeID) of
	[#node{nodeID = NodeID, commandListTableID = NodeTableID}] ->
	    CommandList = create_command_list(ets:tab2list(NodeTableID)),
	    case FilterHidden of
		filter_hidden ->
		    NonHiddenCommandList = lists:filter(fun(X) -> (X#command.hidden /= yes) end, CommandList);
		provide_hidden ->
		    NonHiddenCommandList = CommandList
	    end,
	    %% io:format("Table for node: ~p:~n~p~n", [NodeID, NonHiddenCommandList]),
	    Extract_Cmdstr_fun = fun(Command) ->
					 #command{cmdstr = Cmdstr, helpstr = _Helpstr, funcname = _Funcname}=Command,
					 Fun = create_parser_list(Cmdstr),
					 Fun(#pstate{input=CommandlineString, command=Command}) % store command record for later processing.
				 end,
	    %% Examples for match funs
	    %% Ok_fun = fun(X)->case X of {ok, _State} -> true;_-> false end end,
	    %% Fail_number_fun = fun(X)->case X of {fail_number, _State} -> true;_-> false end end,
	    %% Partially_fun = fun(X)->case X of {partially, _State} -> true;_-> false end end,
	    %% Fail_fun = fun(X)->case X of {fail, _State} -> true;_-> false end end,
	    %% Incomplete_fun = fun(X)->case X of {incomplete, _State} -> true;_-> false end end,
	    A = lists:map(Extract_Cmdstr_fun, NonHiddenCommandList),
	    lists:filter(Match_fun, A);

	[] -> % should not occur
	    throw({error, {node_unknown, NodeID}})
    end.  

create_command_list(List)->
    create_command_list(List, []).

create_command_list([], Acc)->
    lists:reverse(Acc);

create_command_list([Head|Tail], Acc)->
    {_NodeID, Command} = Head,
    create_command_list(Tail, [Command|Acc]).


get_command_list(CommandList) -> 
    get_command_list(CommandList, []).

get_command_list([], Acc) -> 
    ordsets:from_list(lists:reverse(Acc));

get_command_list([Head|Tail], Acc) ->
    %% io:format("Head: ~p~n", [Head]),
    {_, State} = Head,
    io:format("State: ~p~n", [State#pstate.command]),
    get_command_list(Tail, [State#pstate.command|Acc]).

get_command_execution_list(CommandList) -> 
    get_command_execution_list(CommandList, []).

get_command_execution_list([], Acc) -> 
    ordsets:from_list(lists:reverse(Acc));

get_command_execution_list([Head|Tail], Acc) ->
    %% io:format("Head: ~p~n", [Head]),
    {_, State} = Head,
    %% io:format("State: ~p~n", [State#pstate.command]),
    get_command_execution_list(Tail, [{State#pstate.number_list ,State#pstate.selection_list, State#pstate.str_list, State#pstate.command}|Acc]).

get_completion_list(CommandList) -> 
    get_completion_list(CommandList, []).

get_completion_list([], Acc) -> 
    ordsets:from_list(lists:reverse(Acc));

get_completion_list([Head|Tail], Acc) ->
    %% io:format("Head: ~p~n", [Head]),
    {_, State} = Head,
    get_completion_list(Tail, [State#pstate.completion|Acc]).

get_option_list(CommandList) -> 
    get_option_list(CommandList, []).

get_option_list([], Acc) -> 
    ordsets:from_list(lists:reverse(Acc));

get_option_list([Head|Tail], Acc) ->
    %% io:format("Head: ~p~n", [Head]),
    {_, State} = Head,
    get_option_list(Tail, [(State#pstate.parsed ++ State#pstate.completion)|Acc]).




create_parser_list(String) ->
    create_parser_list(String, true, []).

create_parser_list([], _Start, Acc) ->  
    ts_parser:pAnd(lists:reverse(Acc));

create_parser_list([Head|Tail], Start, Acc) -> % Start flags the first item to ensure that no whitespace is requested before the first item of the list 
    Whitespace = ts_parser:pWhiteSpace(),
    Number = ts_parser:pNumber(), 
    WhitespaceAndNumber = ts_parser:pAnd([Whitespace, Number]),    
    MaybeWhitespaceAndNumber = ts_parser:pMaybe(WhitespaceAndNumber),
    Str = ts_parser:pStr(),       % e.g. password in "set PASSWORD"
    WhitespaceAndStr = ts_parser:pAnd([Whitespace, Str]),
    %% io:format("Head: ~p~n", [Head]),
    OptionalNumberGuardOpening = string:chr(Head, $[ ), 
    OptionalNumberGuardClosing = string:chr(Head, $] ), 
    MandatoryNumberGuardOpening = string:chr(Head, $< ), 
    MandatoryNumberGuardClosing = string:chr(Head, $> ),    
    SelectionListGuardOpening = string:chr(Head, ${ ), 
    SelectionListGuardClosing = string:chr(Head, $} ),
    StrGuard = (string:to_upper(Head) == Head),
    if 
	((OptionalNumberGuardOpening == 1) and (OptionalNumberGuardClosing == length(Head))) -> % [XXX]: Optional Number 
	    NewAcc = MaybeWhitespaceAndNumber; % optional match for whitespace followed by number
	(( MandatoryNumberGuardOpening == 1) and (MandatoryNumberGuardClosing == length(Head))) -> % <XXX>: Mandatory Number 	    
	    NewAcc = WhitespaceAndNumber; % match for whitespace followed by number
	(( SelectionListGuardOpening == 1) and (SelectionListGuardClosing == length(Head))) -> % {XXX|YYY|ZZZ}: Selection list 
	    SelectionList = string:tokens(string:substr(Head, 2,length(Head)-2), "|"),
	    Fun = fun(X) -> ts_parser:pString(X) end,
	    NewAcc = case Start  of
			 true -> 
			     ts_parser:pOr(lists:map(Fun, SelectionList)); % match for selection list
			 _ ->
			     ts_parser:pAnd([Whitespace, ts_parser:pOr(lists:map(Fun, SelectionList))]) % match for selection list and whitespace
		     end;
	StrGuard->
	    NewAcc = WhitespaceAndStr;

	true -> % XXXX: String
	    NewAcc = case Start  of
			 true -> 
			     ts_parser:pString(Head);
			 _ ->
			     ts_parser:pAnd([Whitespace, ts_parser:pString(Head)])
		     end
    end,
    create_parser_list(Tail, false, [NewAcc|Acc]). 











