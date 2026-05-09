-module(iotserv).
-behaviour(gen_server).

-include("iotserv.hrl").

%% API
-export([stop/0, start_link/0, start_link/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([add/1, delete/1, lookup/1, change/2]).

stop() ->
    gen_server:cast(?MODULE, stop).

start_link() ->
    {ok, BinFilename} = file:read_file("priv/config.json"),
    Config = jsx:decode(BinFilename, [return_maps]),
    BinPAth = maps:get(<<"dets_file">>, Config),
    Filename = binary_to_list(BinPAth),
    start_link(Filename).

start_link(Filename) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, Filename, []).

%% Customer Services API


add(Device) ->
  gen_server:call(?MODULE, {add, Device}).


delete(Id) ->
  gen_server:call(?MODULE, {delete, Id}).


change(Id, Changes) ->
  gen_server:call(?MODULE, {change, Id, Changes}).

lookup(Id) ->
    gen_server:call(?MODULE, {lookup, Id}).
  


init(Filename) ->
    iotserv_db:create_tables(Filename),
    iotserv_db:restore_backup(),
    {ok, null}.

handle_call({add, Device}, _From, LoopData) ->
    Reply = iotserv_db:add_iot(Device),
    {reply, Reply, LoopData};

handle_call({delete, Id}, _From, LoopData) ->
    Reply = iotserv_db:delete_iot(Id),
    {reply, Reply, LoopData};

handle_call({change, Id, Changes}, _From, LoopData) ->
    case iotserv_db:lookup_id(Id) of
        {error, instance} ->
            {reply, {error, instance} , LoopData};
        {ok, Iot} ->
            NewDevice = apply_changes(Iot, Changes),
            iotserv_db:add_iot(NewDevice),
            {reply, ok, LoopData}
    end;

handle_call({lookup, Id}, _From, State) ->
    Reply = iotserv_db:lookup_id(Id),
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    {reply, {error, unknown_request}, State}.

handle_cast(stop, LoopData) ->
    {stop, normal, LoopData}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    iotserv_db:close_tables(),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

apply_changes(Device, []) -> Device;
apply_changes(Device, [{name, Newname} | Rest]) -> 
    apply_changes(setelement(3, Device, Newname), Rest);
apply_changes(Device, [{adress, Newadress} | Rest]) ->
    apply_changes(setelement(4, Device, Newadress), Rest);
apply_changes(Device, [{tempature, Newtempature} | Rest]) ->
    apply_changes(setelement(5, Device, Newtempature), Rest);
apply_changes(Device, [{indicators, Newindicators} | Rest]) ->
    apply_changes(setelement(6, Device, Newindicators), Rest).
