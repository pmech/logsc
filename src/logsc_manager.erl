-module(logsc_manager).

-export([start_link/0]).
-export([init/0]).

start_link() ->
    proc_lib:start_link(?MODULE, init, []).

init() ->
    proc_lib:init_ack({ok, self()}),
    start_connections().

start_connections() ->
    {ok, LogsCfg} = application:get_env(logs_to_tail),
    lists:foreach(fun({Host, File}) ->
			  {ok, Pid} = supervisor:start_child(logcs_connection_sup, [Host, File]),
			  link(Pid),
			  monitor(process, Pid)
		  end,
		  LogsCfg),
    wait_for_ever().

wait_for_ever() ->
    receive
	M ->
	    lager:info("msg=~p",[M])
    after
	3000 ->
	    wait_for_ever()
    end.


