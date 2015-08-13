-module(logsc_ssh).

-export([start_link/2]).
-export([init/2]).

start_link(Host, File) ->
    proc_lib:start_link(?MODULE, init, [Host, File]).

init(Host, File) ->
    proc_lib:init_ack({ok, self()}),
    {ok, ConnectionRef} = ssh:connect(Host, 22, []),
    {ok, ChannelId} =  ssh_connection:session_channel(ConnectionRef, infinity),
    Cmd = "tail -F -n 0 "++File,
    io:format("Tail command [~p:~p]: ~p~n", [Host, File, Cmd]),
    success = ssh_connection:exec(ConnectionRef, ChannelId, Cmd, infinity),
    receive_stream(atom_to_list(Host)++"@"++File, prepend_name).

receive_stream(File, NameStrategy) ->
    receive
	{ssh_cm,_, {data,0,0, Data}} ->
	    NextNameStrategy = name_stategy(Data),
	    EndInNewLine = end_in_newline(Data),
	    Lines = binary:split(Data, <<"\n">>, [global, trim]),
	    logsc_central_logger ! {lines,
				    [add_name(NameStrategy, File),
				     iolist_to_binary(join(Lines, [<<"\n">>, File, " "])),
				     case EndInNewLine of yes -> <<"\n">>; no -> <<"">> end]},
	    receive_stream(File, NextNameStrategy);
	M ->
	    io:format("Unexpected message: ~p~n", [M]),
	    receive_stream(File, NameStrategy)
    end.

join([] =List, _Sep) -> List;
join([_]=List, _Sep) -> List;
join([First|Rest], Sep) ->
    [First | lists:foldr(fun(Elem, Acc) -> [Sep, Elem | Acc] end, [], Rest)].

add_name(prepend_name, File) -> File++" ";
add_name(_, _) -> "".

name_stategy(Bin) ->
    case binary:last(Bin) of $\n -> prepend_name; _ -> no_prepend end.
end_in_newline(Bin) ->
    case binary:last(Bin) of $\n -> yes; _ -> no end.
