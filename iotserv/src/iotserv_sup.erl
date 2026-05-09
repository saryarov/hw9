-module(iotserv_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init(_Args) ->
    ChildSpec = {
        iotserv,
        {iotserv, start_link, []},
        permanent,
        5000,
        worker,
        [iotserv]
    },
    {ok, {{one_for_one, 5, 10}, [ChildSpec]}}.