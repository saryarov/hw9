-module(iotserv_db).
-include("iotserv.hrl").

-export([create_tables/1, close_tables/0, add_iot/1, delete_iot/1,
         lookup_id/1, restore_backup/0]).

create_tables(Filename) ->
    ets:new(ioTid, [named_table, {keypos, 2}]),
    dets:open_file(iotDisk, [{file, Filename}, {keypos, 2}]).

close_tables() ->
    ets:delete(ioTid),
    dets:close(iotDisk).

add_iot(#iot{} = Iot) ->
    ets:insert(ioTid, Iot),
    update_iot(Iot).

update_iot(Iot) ->
    dets:insert(iotDisk, Iot),
    ok.

delete_iot(Id) ->
    case ets:lookup(ioTid, Id) of
        [] -> {error, instance};
        [_] -> 
            dets:delete(iotDisk, Id),
            ets:delete(ioTid, Id),
            ok
    end.


lookup_id(Id) ->
    case ets:lookup(ioTid, Id) of
        [] -> {error, instance};
        [Iot] -> {ok, Iot}
    end.


restore_backup() ->
    Insert = fun(#iot{} = Iot) ->
                ets:insert(ioTid, Iot),
                continue
            end,
    ets:delete_all_objects(ioTid),
    dets:traverse(iotDisk, Insert). % для каждого тапла из диска применяется инсерт

%delete_disabled()