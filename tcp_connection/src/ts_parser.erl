%%% Modified by: M. Josenhans
%%%---------------------------------------------------------------------
%%% Based on idea from Jeffrey A. Meunier
%%%---------------------------------------------------------------------
%%% This module is based on the Haskell Parsec parser library written
%%% by Erik Meijer.


-module(ts_parser).
-export([match_string/3, pNumber/0, pString/1, pStr/0, pAnd/1, 
         example1/0, example2/0, example3/0, example4/0, example5/0, 
	 pMaybe/1, pOr/1, pWhiteSpace/0, pNumberWhiteSpace/0]).
-include("ts_command.hrl").
-include("ts_telnet.hrl").


example1()->
    A = pNumber(),
    {ok, B} = A("1234dfg5"),
    B#pstate.number_list.

example2() ->
    A= pWhiteSpace(),
    B= pMaybe(A),
    C= pString("michael"),
    D= pMaybe(C),
    E= pString("andreas"),
    % F= pMaybe(E),
    G= pNumber(),
    H= pMaybe(G),
    I= pStr(),
    U= pAnd([D,A,E, B, I, B, I, B, G, B, H]),
    V= pAnd([U]),
    {Status, X} = V(#pstate{input="michael andreas BlaBla 12 34 54"}),
    io:format("Status: ~p~n", [Status]),
    io:format("Input: ~p~n", [X#pstate.input]),
    io:format("Parsed: ~p~n", [X#pstate.parsed]),  
    io:format("Parsed_list: ~p~n", [X#pstate.parsed_list]),
    io:format("Completion: ~p~n", [X#pstate.completion]),
    io:format("Number list: ~w~n",[X#pstate.number_list]),
    io:format("Str list: ~p~n",[X#pstate.str_list]),
    X.

example3() ->
    A= pString("michael"),
    B= pString("andreas"),
    C= pString("Bernd"),
    W= pWhiteSpace(),
    D= pOr([A,B,C]),
    E= pAnd([A,W,D,W,C]),
    F= pAnd([E]),
    {Status, X} = F(#pstate{input="michael Andreas Beq"}),
    io:format("Status: ~p~n", [Status]),
    io:format("Input: ~p~n", [X#pstate.input]),
    io:format("Parsed: ~p~n", [X#pstate.parsed]),  
    io:format("Parsed_list: ~p~n", [X#pstate.parsed_list]),    
    io:format("Selection_list: ~p~n", [X#pstate.selection_list]),
    io:format("Completion: ~p~n", [X#pstate.completion]),
    io:format("Number list: ~w~n",[X#pstate.number_list]),
    io:format("Str list: ~p~n",[X#pstate.str_list]),
    X.


example4() ->
    A= pString("michael"),
    B= pString("andreas"),
    C= pString("bernd"),
    W= pWhiteSpace(),
    D= pAnd([B]),
    E= pAnd([A,W,C,W,D]),
    {Status, X} = E(#pstate{input="michael bernd Andreas"}),
    io:format("Status: ~p~n", [Status]),
    io:format("Input: ~p~n", [X#pstate.input]),
    io:format("Parsed: ~p~n", [X#pstate.parsed]),  
    io:format("Parsed_list: ~p~n", [X#pstate.parsed_list]),    
    io:format("Selection_list: ~p~n", [X#pstate.selection_list]),
    io:format("Completion: ~p~n", [X#pstate.completion]),
    io:format("Number list: ~w~n",[X#pstate.number_list]),
    io:format("Str list: ~p~n",[X#pstate.str_list]),
    X.

example5() ->
    A= pString("michael"),
    B= pString("andreas"),
    C= pString("bernd"),
    X = [A(#pstate{input="mich"}),B(#pstate{input="An"}),C(#pstate{input="ber"})],
    io:format("Status: ~p~n", [X]),
    X.







%%%---------------------------------------------------------------------
%%% Match a specific string.
%%%---------------------------------------------------------------------
pString( MatchString )-> 
    fun( State )-> 
	    %% State = #pstate{input=Input},
	    match_string( MatchString, State)
    end.

match_string( MatchString, State ) -> 
    match_string( MatchString, State, []).



%%% parsing is completed and input is empty
match_string( [], #pstate{input=[]}=State, Acc) ->
    NewState = State#pstate{parsed = lists:reverse(Acc),completion = []},
    {ok, NewState};

%%% match matchstring to input characterwise
match_string( [M | Ms], #pstate{input=[I|Is]}=State, Acc) when M == I -> % M: MatchString, I: Input
    NewState = State#pstate{input= Is},
    match_string( Ms, NewState, [M |Acc]);

%%% ignore case, thus match uppercase char against lowercase char
match_string( [M | Ms], #pstate{input=[I|Is]}=State, Acc) when I>=65, I=<90, M == I+32 -> % M: MatchString, I: Input 
    NewState = State#pstate{input= Is},
    match_string( Ms, NewState, [M |Acc]);

%%% parsing is completed, however further input data exist
match_string( [], State, Acc) -> 
    NewState = State#pstate {parsed = lists:reverse(Acc),completion = []},
    {incomplete, NewState};

%%% matchstring is neigther empty nor completed, however input is empty
%%% and Acc is empty -> the empty string has been parsed.
match_string( MatchString, #pstate{input=[]}=State, []) ->
    NewState = State#pstate{parsed = [],completion = MatchString},
    {fail, NewState};

%%% matchstring is neigther empty nor completed, however input is empty
match_string( MatchString, #pstate{input=[]}=State, Acc) -> 
    NewState = State#pstate {parsed = lists:reverse(Acc), completion = MatchString},
    {partially, NewState};

%%% matchstring does not match and input is not empty
match_string( MatchString,  State, Acc) -> 
    NewState = State#pstate {parsed = lists:reverse(Acc),completion = MatchString},
    {fail, NewState}.


pNumber()-> 
    fun( State ) -> 
	    match_number(State)
    end.

match_number(State)->
    match_number(0, State, []).

match_number(Number, #pstate{input=[I|Is]}=State, Acc) when (I >= $0), (I =< $9) ->
    NewNumber = Number * 10 +  (I - $0),
    %%io:format("Number: ~p~n",[NewNumber]),
    NewState = State#pstate{input= Is},
    %%io:format("State: ~w ~n", [NewState#pstate.input]), 
    match_number(NewNumber, NewState, [I |Acc]);

match_number(_Number,  #pstate{input=[]}=State, []) ->
    NewState = State#pstate { parsed = []},
    {fail_number, NewState};

match_number(_Number, State, []) ->
    NewState = State#pstate { parsed = []},
    {fail, NewState};

match_number(Number,  #pstate{input=[]}=State, Acc) ->   
    NumberList = State#pstate.number_list,
    NewNumberList = NumberList ++ [Number],
    %%io:format("NewNumberList: ~p~n",[NewNumberList]),
    NewState = State#pstate {number_list = NewNumberList, parsed = lists:reverse(Acc)},
    {ok, NewState};

match_number(Number,  State, Acc) ->   
    NumberList = State#pstate.number_list,
    NewNumberList = NumberList ++ [Number],
    %%io:format("NewNumberList: ~p~n",[NewNumberList]),
    NewState = State#pstate {number_list = NewNumberList, parsed = lists:reverse(Acc)},
    {incomplete, NewState}.


pStr()-> 
    fun( State ) -> 
	    match_str(State)
    end.

match_str(State)->
    match_str("", State, []).

match_str(String, #pstate{input=[I|Is]}=State, Acc) when (I >= 33), (I =< 126) ->
    NewString = String ++ [I|""],
    %%io:format("String: ~p~n",[NewString]),
    NewState = State#pstate{input= Is},
    %%io:format("State: ~w ~n", [NewState#pstate.input]), 
    match_str(NewString, NewState, [I |Acc]);

match_str(_String,  #pstate{input=[]}=State, []) ->
    NewState = State#pstate { parsed = []},
    {fail_str, NewState};

match_str(_String, State, []) ->
    NewState = State#pstate { parsed = []},
    {fail, NewState};

match_str(String,  #pstate{input=[]}=State, Acc) ->   
    StrList = State#pstate.str_list,
    NewStrList =  StrList++[String],
    %%io:format("NewStrList: ~p~n",[NewStrList]),
    NewState = State#pstate {str_list = NewStrList, parsed = lists:reverse(Acc)},
    {ok, NewState};

match_str(String,  State, Acc) ->   
    StrList = State#pstate.str_list,
    NewStrList = StrList++[String],
    %%io:format("NewStrList: ~p~n",[NewStrList]),
    NewState = State#pstate {str_list = NewStrList, parsed = lists:reverse(Acc)},
    {incomplete, NewState}.




%%%---------------------------------------------------------------------
%%% Succeed if all parsers succeed.  This can be used as a
%%% sequencing parser.
%%%---------------------------------------------------------------------
pAnd(Parsers) -> 
    fun(State)->
	    all( Parsers, State, [])
    end.

all([], #pstate{input=[], parsed_list = Parsed_List}=State, Acc) ->
    NewState = State#pstate{parsed_list =  lists:reverse( Acc ) ++Parsed_List},
    %% io:format("lists:reverse( Acc ) ~p~n",[lists:reverse( Acc )]),
    {ok, NewState};

all([], #pstate{parsed_list = Parsed_List}=State, Acc) ->
    NewState = State#pstate{parsed_list = lists:reverse( Acc ) ++ Parsed_List},
    {incomplete, NewState};


all([P | Parsers], #pstate{parsed_list = Parsed_List}=State, Acc) ->
    case P(State) of
	{fail, #pstate{parsed=[]}=NewState} -> 
	    Parsed_List1 = NewState#pstate.parsed_list,
	    NewState1 = NewState#pstate{parsed_list = Parsed_List1 ++ lists:reverse(Acc), parsed=""},
	    {fail, NewState1};

	{fail, #pstate{parsed=Parsed}=NewState} -> 
	    Parsed_List1 = NewState#pstate.parsed_list,
	    NewState1 = NewState#pstate{parsed_list = Parsed_List1 ++ lists:reverse(Acc) ++ [Parsed], parsed=""},
	    {fail, NewState1};

	{fail_number, NewState} -> 
	    NewState1 = NewState#pstate{parsed_list = Parsed_List ++ lists:reverse(Acc)},
	    {fail_number, NewState1};

	{fail_str, NewState} -> 
	    NewState1 = NewState#pstate{parsed_list = Parsed_List ++ lists:reverse(Acc)},
	    {fail_str, NewState1};

	{partially, NewState} ->
	    NewState1 = NewState#pstate{parsed_list = Parsed_List ++ lists:reverse(Acc)},
	    {partially, NewState1};

	{incomplete, #pstate{parsed=[]}=NewState} ->
	    all(Parsers, NewState#pstate{parsed=""}, Acc);

	{incomplete, NewState} ->
	    all(Parsers, NewState#pstate{parsed=""}, [NewState#pstate.parsed | Acc]);

	{ok,  #pstate{parsed=[]}=NewState} ->
	    all(Parsers, NewState#pstate{parsed=""}, Acc);

	{ok, NewState} ->
	    all(Parsers, NewState#pstate{parsed=""}, [NewState#pstate.parsed | Acc])
    end.

%%%---------------------------------------------------------------------
%%% Succeed when one of a list of parsers succeeds.
%%%---------------------------------------------------------------------
pOr( Parsers )
-> fun( State )
      -> pTry( Parsers, State )
   end.

pTry( [], State )-> 
    {fail, State};

pTry( [P | Parsers], State )-> 
    case P( State ) of
	{fail, _NewState} -> 
	    pTry( Parsers, State#pstate{parsed=""} );

	{partially, _NewState} ->         
	    pTry( Parsers, State#pstate{parsed=""} );

	{incomplete, NewState} ->
	    {incomplete, NewState#pstate{selection_list =   [NewState#pstate.parsed | State#pstate.selection_list]}};

	{ok, NewState}->
	    {ok, NewState#pstate{selection_list =   [NewState#pstate.parsed | State#pstate.selection_list]}}

    end.

%%%---------------------------------------------------------------------
%%% Parse 0 or 1 element.
%%%---------------------------------------------------------------------
pMaybe( P ) -> 
    fun(State)->
	    case P(State) of
		{fail, #pstate{input=[]}=_NewState} -> % when receiving fail, however input is empty -> its ok
		    {ok, State};

		{fail, _NewState} ->
		    {incomplete, State};

		{fail_number,  #pstate{input=[]}=_NewState} -> % when receiving fail, however input is empty -> its ok
		    {ok, State};

		{fail_number, _NewState} ->
		    {incomplete, State};

		{partially, #pstate{input=[]}=_NewState} -> % when receiving partially, however input is empty -> its ok
		    {ok, State};

		{partially, _NewState} -> 
		    {incomplete, State};

		{incomplete, NewState} ->
		    {incomplete, NewState};

		{ok, NewState} ->
		    {ok, NewState} 
	    end
    end.

pWhiteSpace() ->
    fun(State) ->
	    match_whitespace(State)
    end.

match_whitespace(State ) -> 
    match_whitespace(State, []).

match_whitespace( #pstate{input=[]}=State, []) ->
    NewState = State#pstate{parsed = [], completion=" "},
    {partially, NewState};

match_whitespace( #pstate{input=[]}=State, Acc) ->
    NewState = State#pstate{parsed = lists:reverse(Acc)},
    {ok, NewState};

match_whitespace(#pstate{input=[I|Is]}=State, Acc) when I== $\s -> % Test (I: Input) against Space " "
    NewState = State#pstate{input= Is},
    match_whitespace(NewState, [$\s |Acc]);

%% match_whitespace(#pstate{input=Input}=State, Acc) when length(Acc) > 0, length(Input) == 0 -> 
%%     NewState = State#pstate {parsed = lists:reverse(Acc)},
%%     {ok, NewState};

match_whitespace(State, Acc) when length(Acc) > 0 -> 
    NewState = State#pstate {parsed = lists:reverse(Acc)},
    {incomplete, NewState};

match_whitespace(State, []) -> 
    NewState = State#pstate {parsed = []},
    {fail, NewState}.

pNumberWhiteSpace() ->
    fun(State) ->
	    match_number_whitespace(State)
    end.

match_number_whitespace(State ) -> 
    match_number_whitespace(State, []).

match_number_whitespace( #pstate{input=[]}=State, []) ->
    NewState = State#pstate{parsed = []},
    {fail_number, NewState};

match_number_whitespace( #pstate{input=[]}=State, Acc) ->
    NewState = State#pstate{parsed = lists:reverse(Acc)},
    {ok, NewState};

match_number_whitespace(#pstate{input=[I|Is]}=State, Acc) when I== $\s -> % Test (I: Input) against Space " "
    NewState = State#pstate{input= Is},
    match_number_whitespace(NewState, [$\s |Acc]);

%% match_number_whitespace(#pstate{input=Input}=State, Acc) when length(Acc) > 0, length(Input) == 0 -> 
%%     NewState = State#pstate {parsed = lists:reverse(Acc)},
%%     {ok, NewState};

match_number_whitespace(State, Acc) when length(Acc) > 0 -> 
    NewState = State#pstate {parsed = lists:reverse(Acc)},
    {incomplete, NewState};

match_number_whitespace(State, []) -> 
    NewState = State#pstate {parsed = []},
    {fail, NewState}.


