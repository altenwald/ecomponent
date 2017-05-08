REBAR = ./rebar

all: compile

doc:
	${REBAR} doc

compile: deps
	${REBAR} compile

deps:
	${REBAR} get-deps

test: compile
	${REBAR} eunit skip_deps=true
	./covertool \
		-cover .eunit/eunit.coverdata \
		-appname ecomponent \
		-output cobertura.xml

clean:
	${REBAR} clean

.PHONY: doc test
