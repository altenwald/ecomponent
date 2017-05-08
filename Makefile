REBAR = ./rebar

all: compile

doc:
	${REBAR} doc

compile:
	${REBAR} compile

get-deps:
	${REBAR} get-deps

test: get-deps compile
	${REBAR} eunit skip_deps=true
	./covertool \
		-cover .eunit/eunit.coverdata \
		-appname ecomponent \
		-output cobertura.xml

clean:
	${REBAR} clean

.PHONY: doc test
