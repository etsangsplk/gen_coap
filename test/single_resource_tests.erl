%
% The contents of this file are subject to the Mozilla Public License
% Version 1.1 (the "License"); you may not use this file except in
% compliance with the License. You may obtain a copy of the License at
% http://www.mozilla.org/MPL/
%
% Copyright (c) 2015 Petr Gotthard <petr.gotthard@centrum.cz>
%

% tests per ETSI CoAP test specifications (and few more)
-module(single_resource_tests).

-export([coap_discover/2, coap_get/4]).

-include_lib("eunit/include/eunit.hrl").
-include_lib("gen_coap/include/coap.hrl").

% fixture is my friend
single_resource_test_() ->
    {setup,
        fun() ->
            application:start(gen_coap),
            coap_server_content:add_handler([<<"text">>], ?MODULE, undefined)
        end,
        fun(_State) ->
            application:stop(gen_coap)
        end,
        fun single_resource/1}.

coap_discover(Prefix, _Args) ->
    [{absolute, Prefix, []}].

% resource generator
coap_get(_ChId, _Prefix, [Size], Request) ->
    {ok, text_resource(binary_to_integer(Size))}.

single_resource(_State) ->
    [
    % discovery
    ?_assertMatch({ok,content,#coap_resource{format= <<"application/link-format">>, content= <<"</text>">>}},
        coap_client:request(get, "coap://127.0.0.1/.well-known/core")),
    % resource access
    ?_assertEqual({ok,content,text_resource(128)}, coap_client:request(get, "coap://127.0.0.1/text/128")),
    ?_assertEqual({ok,content,text_resource(1024)}, coap_client:request(get, "coap://127.0.0.1/text/1024")),
    ?_assertEqual({ok,content,text_resource(1984)}, coap_client:request(get, "coap://127.0.0.1/text/1984")),
    ?_assertEqual({error,method_not_allowed}, coap_client:request(post, "coap://127.0.0.1/text", text_resource(128))),
    ?_assertEqual({error,method_not_allowed}, coap_client:request(post, "coap://127.0.0.1/text", text_resource(1024))),
    ?_assertEqual({error,method_not_allowed}, coap_client:request(post, "coap://127.0.0.1/text", text_resource(1984))),
    ?_assertEqual({error,method_not_allowed}, coap_client:request(put, "coap://127.0.0.1/text")),
    ?_assertEqual({error,method_not_allowed}, coap_client:request(delete, "coap://127.0.0.1/text"))
    ].

text_resource(Size) ->
    #coap_resource{format= <<"text/plain">>, content=large_binary(Size, <<"X">>)}.

large_binary(Size, Acc) when Size > 2*byte_size(Acc) ->
    large_binary(Size, <<Acc/binary, Acc/binary>>);
large_binary(Size, Acc) ->
    Sup = binary:part(Acc, 0, Size-byte_size(Acc)),
    <<Acc/binary, Sup/binary>>.

% end of file
