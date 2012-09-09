%%%-------------------------------------------------------------------
%%% @author michael <michael@michael-desktop>
%%% @copyright (C) 2012, michael
%%% @doc
%%%
%%% @end
%%% Created : 18 Jul 2012 by michael <michael@michael-desktop>
%%%-------------------------------------------------------------------
-module(tcp_connection_sup).

-behaviour(supervisor).

%% API
-export([start_link/2, start_child/4]).

%% Supervisor callbacks
-export([init/1, handle_call/3]).

-define(SERVER, ?MODULE).

%%%===================================================================
%%% API functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the supervisor
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------

start_link(Socket, Instance) when is_integer(Instance)->
    Instance_s = integer_to_list(Instance),
    Ref_s = erlang:ref_to_list(make_ref()),
    Name_s = ?MODULE_STRING ++ "_" ++ Instance_s ++ "_" ++ Ref_s,
    Name = list_to_atom (Name_s),
    error_logger:info_report("supervisor:start_link(~p)~n", [{local, Name}, ?MODULE, [Socket, Instance]]),
    %% supervisor:start_link(?MODULE, [Socket, Instance]).
    supervisor:start_link({local, Name}, ?MODULE, [Socket, Instance]).  % the name is optional

start_child(PID, Socket, ConfigurationFile, Instance) ->    
    supervisor:start_child(PID,  [Socket, ConfigurationFile, Instance]).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever a supervisor is started using supervisor:start_link/[2,3],
%% this function is called by the new process to find out about
%% restart strategy, maximum restart frequency and child
%% specifications.
%%
%% @spec init(Args) -> {ok, {SupFlags, [ChildSpec]}} |
%%                     ignore |
%%                     {error, Reason}
%% @end
%%--------------------------------------------------------------------
init([_Socket, _Instance]) ->
    RestartStrategy = simple_one_for_one,
    MaxRestarts = 10,
    MaxSecondsBetweenRestarts = 60,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},
    TCP_connection = {tcp_connection, {tcp_connection, start_link, []},
		      temporary, 2000, worker, [tcp_connection]},
    %% unclear, why it is necessary to define tcp_coonection
    %% if its not used at all. 
    {ok, {SupFlags, [TCP_connection]}}.

handle_call(Request, _From, State) ->
    error_logger:info_report("handle call, module(~w) Request:(~p)~n",[?MODULE, Request]),
    Reply = ok,
    {reply, Reply, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
