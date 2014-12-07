-module(ecomponent_php).
-author('manuel@altenwald.com').

-behaviour(ephp_func).

-export([
    process_script/2,
    xml_to_php/1,
    php_to_xml/1,

    init/0,
    ecomponent_send_message/2
]).

-include_lib("ephp/include/ephp.hrl").
-include_lib("exmpp/include/exmpp.hrl").
-include("ecomponent.hrl").

init() -> [
    ecomponent_send_message
].

process_script(Info, Filename) ->
    {ok, Ctx} = ephp:context_new(to_bin(Filename)),
    register_info(Ctx, Info),
    ephp:register_module(Ctx, ?MODULE), 
    ephp:eval(Filename, Ctx, element(2, file:read_file(to_str(Filename)))),
    ok.

%% Wrappers

ecomponent_send_message(_Ctx, {_, PhpMessage}) ->
    Message = php_to_xml(PhpMessage),
    ecomponent:send_message(Message),
    null.

%% Conversors

register_info(Ctx, #message{}=M) ->
    Value = ?DICT:from_list([
        {<<"type">>, to_bin(M#message.type)},
        {<<"from">>, exmpp_jid:to_binary(exmpp_jid:make(M#message.from))},
        {<<"to">>, exmpp_jid:to_binary(exmpp_jid:make(M#message.to))},
        {<<"xmlel">>, xml_to_php(M#message.xmlel)},
        {<<"server">>, to_bin(M#message.server)}
    ]),
    ephp:register_var(Ctx, <<"_MESSAGE">>, Value);

register_info(Ctx, #presence{}=P) ->
    Value = ?DICT:from_list([
        {<<"type">>, to_bin(P#presence.type)},
        {<<"from">>, exmpp_jid:to_binary(exmpp_jid:make(P#presence.from))},
        {<<"to">>, exmpp_jid:to_binary(exmpp_jid:make(P#presence.to))},
        {<<"xmlel">>, xml_to_php(P#presence.xmlel)},
        {<<"server">>, to_bin(P#presence.server)}
    ]),
    ephp:register_var(Ctx, <<"_PRESENCE">>, Value);

register_info(Ctx, #params{}=P) ->
    Value = ?DICT:from_list([
        {<<"type">>, to_bin(P#params.type)},
        {<<"from">>, exmpp_jid:to_binary(exmpp_jid:make(P#params.from))},
        {<<"to">>, exmpp_jid:to_binary(exmpp_jid:make(P#params.to))},
        {<<"ns">>, to_bin(P#params.ns)},
        {<<"payload">>, xml_to_php(P#params.payload)},
        {<<"iq">>, xml_to_php(P#params.iq)},
        {<<"features">>, list_to_array(P#params.features)},
        {<<"info">>, ?DICT:from_list(P#params.info)},
        {<<"server">>, to_bin(P#params.server)}
    ]),
    ephp:register_var(Ctx, <<"_IQ">>, Value).

list_to_array(List) ->
    {_, Array} = lists:foldl(fun(El, {I, Dict}) ->
        {I+1, ?DICT:store(I, El, Dict)}
    end, {0, ?DICT:new()}, List),
    Array.

xml_to_php([]) ->
    ?DICT:new();

xml_to_php(#xmlel{name=Name, attrs=Attrs, children=Children}) ->
    {CData, Els} = lists:partition(fun
        (#xmlcdata{}) -> true;
        (_) -> false
    end, Children),
    ?DICT:from_list([
        {<<"name">>, to_bin(Name)},
        {<<"attrs">>, xml_to_php(Attrs)},
        {<<"children">>, xml_to_php(Els)},
        {<<"cdata">>, get_cdata(CData)}
    ]);

xml_to_php([#xmlattr{}|_]=Attrs) ->
    lists:foldl(fun(#xmlattr{name=Name, value=Value}, Dict) ->
        ?DICT:store(Name, Value, Dict)
    end, ?DICT:new(), Attrs);

xml_to_php([#xmlel{}|_]=Els) ->
    {_,Array} = lists:foldl(fun(El, {I, Dict}) ->
        {I+1, ?DICT:store(I, xml_to_php(El), Dict)}
    end, {0, ?DICT:new()}, Els),
    Array.

get_cdata([]) ->
    <<>>;

get_cdata([#xmlcdata{}|_]=CData) ->
    lists:foldl(fun(#xmlcdata{cdata=Text}, ResText) ->
        <<ResText/binary, Text/binary>>
    end, <<>>, CData).

php_to_xml(Dict) ->
    CDATA = case ?DICT:find(<<"cdata">>, Dict) of
    {ok, Text} when byte_size(Text) > 0 ->
        [#xmlcdata{cdata=Text}];
    _ ->
        []
    end,
    Els = case ?DICT:find(<<"children">>, Dict) of
    {ok, E} ->
        lists:map(fun({_,Child}) ->
            php_to_xml(Child)
        end, ?DICT:to_list(E));
    _ ->
        []
    end,
    Attrs = case ?DICT:find(<<"attrs">>, Dict) of
    {ok, A} ->
        [ exmpp_xml:attribute(K,V) || {K,V} <- ?DICT:to_list(A) ];
    _ ->
        []
    end,
    Name = case ?DICT:find(<<"name">>, Dict) of
        {ok, N} -> N;
        _ -> <<"noname">>
    end,
    #xmlel{
        name = Name,
        attrs = Attrs,
        children = Els ++ CDATA
    }.

to_bin(undefined) -> null;
to_bin(Atom) when is_atom(Atom) -> atom_to_binary(Atom, utf8);
to_bin(Str) when is_list(Str) -> list_to_binary(Str);
to_bin(Bin) when is_binary(Bin) -> Bin.

to_str(Bin) when is_binary(Bin) -> binary_to_list(Bin);
to_str(Str) when is_list(Str) -> Str.
