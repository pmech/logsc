-module(logsc_central_logger).

-export([start_link/0,
	 central_logger/0]).

start_link() ->
    proc_lib:start_link(?MODULE, central_logger, []).

central_logger() ->
    register(logsc_central_logger, self()),
    proc_lib:init_ack({ok, self()}),
    {ok, CentralLog} = application:get_env(central_log),
    {ok, F} = file:open(CentralLog, [append]),
    loop(F).

loop(F) ->
    receive
	{lines, Data} ->
	    file:write(F, Data),
	    loop(F);
	Term ->
	    io:format("Error: recieved unexpected message: ~p~n", [Term])
    end.
