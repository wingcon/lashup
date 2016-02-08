%%%-------------------------------------------------------------------
%%% @author sdhillon
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. Feb 2016 9:47 PM
%%%-------------------------------------------------------------------
-module(lashup_nerve_center).
-author("sdhillon").

%% API
-export([start_link/0]).

start_link() ->
  AcceptorPool = 10,
  Dispatch = routes(),
  RetData = cowboy:start_http(?MODULE, AcceptorPool, [{port, 0}],
    [{env, [{dispatch, Dispatch}]}]
  ),
  setup_reload(),
  maybe_log(),
  RetData.

maybe_log() ->
  case catch ranch:get_port(?MODULE) of
    Port when is_integer(Port) ->
      lager:info("Nerve Center Started on Port: ~p", [Port]);
    _Else -> ok
  end.

routes() ->
  cowboy_router:compile(routes2()).
routes2() ->
  [
    {'_', [
      {"/", cowboy_static, {priv_file, lashup, "static/index.html"}},
      {"/websocket", lashup_nerve_center_ws_handler, []},
      {"/static/[...]", cowboy_static, {priv_dir, lashup, "static"}}
    ]}
  ].

setup_reload() ->
  sync:onsync(fun onsync/1).

onsync(Modules) ->
  case lists:member(?MODULE, Modules) of
    true ->
      lager:debug("Reloading routes"),
      cowboy:set_env(?MODULE, dispatch, routes());
    false ->
      ok
  end.


