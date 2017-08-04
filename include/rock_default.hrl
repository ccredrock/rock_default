%%%-------------------------------------------------------------------
%%% @author wanghongyan05
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 2017年07月17日10:56:58
%%%-------------------------------------------------------------------
-ifndef(COMMON_HRL).
-define(COMMON_HRL, true).

-export([hs/0, hs/1, cr/1, ca/1, ce/1, dm/1,
         pj/0, vs/0, pf/0, pf/1,
         log/1, log/2, logw/2,
         em/0, er/0, eq/0, es/0]).

-define(USER_TOP_LEN, 3).
-define(USER_TOP_TIME, 200).

%%------------------------------------------------------------------------------
hs() -> hs(user_default).
hs(M) ->
    {ok, Path} = file:get_cwd(),
    cc(M, [{outdir, Path ++ "/lib/" ++ atom_to_list(pj()) ++ "-" ++ vs() ++ "/ebin"}]).

cc(M, L) ->
    code:ensure_loaded(M),
    F = element(2, lists:keyfind(source, 1, erlang:get_module_info(M, compile))),
    Path = binary_to_list(hd(re:split(F, "/src/"))),
    c:c(F, L ++ [debug_info,
                 {parse_transform, lager_transform},
                 {lager_extra_sinks, [much]},
                 {i, Path ++ "/include"}]).

cr(M) -> cc(M, [to_core]).
ca(M) -> cc(M, [to_asm]).
ce(M) -> cc(M, [export_all]).

dm(Mod) ->
    Rel = beam_lib:chunks(code:which(Mod), [abstract_code]),
    {ok, {Mod, [{abstract_code, {_, AC}} ]} } = Rel,
    Path = lists:concat([Mod, ".erl"]),
    {ok, IO} = file:open(Path, write),
    io:fwrite(IO, "~s~n", [erl_prettypr:format(erl_syntax:form_list(AC))]),
    file:close(IO).

%%------------------------------------------------------------------------------
pj() ->
    list_to_atom(element(1, init:script_id())).

vs() ->
    list_to_atom(element(2, init:script_id())).

%%------------------------------------------------------------------------------
log(Str) -> log("log.erl", Str).
log(FileName, Str) -> io:format(element(2, file:open(FileName, [write])), "~p", [Str]).
logw(FileName, Str) -> io:format(element(2, file:open(FileName, [write])), "~w", [Str]).

pf() -> pf(3).
pf(Len) ->
    [{reduction, recon:proc_window(reductions, Len, 200)},
     {message_len, recon:proc_count(message_queue_len, Len)},
     {memory, recon:proc_count(memory, Len)},
     {cnt, recon:inet_window(cnt, Len, 200)},
     {oct, recon:inet_window(oct, Len, 3)}].

em() -> spawn(fun() -> etop:start([{output, text}, {interval, 1}, {lines, 20}, {sort, memory}]) end).
er() -> spawn(fun() -> etop:start([{output, text}, {interval, 1}, {lines, 20}, {sort, reductions}]) end).
eq() -> spawn(fun() -> etop:start([{output, text}, {interval, 1}, {lines, 20}, {sort, msg_q}]) end).
es() -> etop:stop().

-endif.

