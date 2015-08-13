-module(logsc_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([start_link/1]).
-export([init/1]).

start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, top).

start_link(Sup) ->
	supervisor:start_link({local, Sup}, ?MODULE, Sup).

init(top) ->
    Procs = [#{id => logcs_connection_sup,  start => {?MODULE,              start_link, [logcs_connection_sup]},  type => supervisor},
	     #{id => logsc_central_logger,  start => {logsc_central_logger, start_link, []}},
	     #{id => logsc_manager,         start => {logsc_manager,        start_link, []}}],

	{ok, {#{strategy => one_for_all,
		intensity => 1,
		period => 5},
	      Procs}};

init(logcs_connection_sup) ->
    Procs = [#{id => ignored,
	       start => {logsc_ssh, start_link, []},
	       restart => temporary}],
    lager:info("logcs_connection_sup"),

    {ok, {#{strategy => simple_one_for_one,
	    intensity => 1,
	    period => 5},
	  Procs}}.
