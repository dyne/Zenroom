-module(test).
-on_load(init/0).
-export([init/0, hello/0]).
init() ->
	erlang:load_nif("./test", 0).
hello() ->
	"NIF library not loaded".
