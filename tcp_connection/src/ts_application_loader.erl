-module(ts_application_loader).

-behaviour(gen_server).

%% API
-export([start_link/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 

-record(state,
	{appl_name             ::string(),
	 conf_file_prefix      ::string()}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link(ConfigurationFilePrefix, ApplicationName, ApplRegistration_Fun) ->
    Name_s = ?MODULE_STRING ++ "_" ++ ApplicationName,
    Name = list_to_atom (Name_s),      
    error_logger:info_report("gen_server:start_link(~p)~n",[[{local, Name},?MODULE,[ConfigurationFilePrefix, ApplicationName],[],self()]]),
    %% Name may be left away.
    %% gen_server:start_link(?MODULE,[Socket],[]).
    gen_server:start_link({local, Name}, ?MODULE, [ConfigurationFilePrefix, ApplicationName, ApplRegistration_Fun], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([ConfigurationFilePrefix, ApplicationName, ApplRegistration_Fun]) ->
    ApplRegistration_Fun(), 
    {ok, #state{conf_file_prefix=ConfigurationFilePrefix, appl_name=ApplicationName}, 1000}. % causes delayed timeout to load the configuration file

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast({unregister_application, ApplicationName, ApplUnregistration_Fun}, State) ->
    error_logger:info_msg("Application ~p has been unregsitered~n", [ApplicationName]),
    ApplUnregistration_Fun(),
    {stop, normal, State};
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(timeout, #state{conf_file_prefix = ConfigurationFilePrefix, appl_name=ApplicationName}=State) ->
    ConfigurationFilename = ConfigurationFilePrefix ++ "_" ++ ApplicationName ++ ".txt",
    error_logger:info_msg("Loading ConfigurationFile (~p)~n", [ConfigurationFilename]),
    %% load the configuration file
    case ts_read_file:execute_file_commands(vty_direct, ConfigurationFilename) of
	ok -> 
	    error_logger:info_msg("Reading configuration file successfully!!~n~n");
	{error, Error} ->
	    error_logger:error_msg("Failed reading configuration configuration file with error: ~s~n~n",[Error])
    end,
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
