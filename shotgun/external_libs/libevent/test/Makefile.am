AUTOMAKE_OPTIONS = foreign no-dependencies

LDADD = ../libevent.la
CPPFLAGS = -I.. -I../compat

EXTRA_DIST = regress.rpc

noinst_PROGRAMS = test-init test-eof test-weof test-time regress bench

BUILT_SOURCES = regress.gen.c regress.gen.h
test_init_SOURCES = test-init.c
test_eof_SOURCES = test-eof.c
test_weof_SOURCES = test-weof.c
test_time_SOURCES = test-time.c
regress_SOURCES = regress.c regress.h regress_http.c regress_dns.c \
	regress.gen.c regress.gen.h
bench_SOURCES = bench.c

regress.gen.c regress.gen.h: regress.rpc
	../event_rpcgen.py regress.rpc || echo "No Python installed"

DISTCLEANFILES = *~
CLEANFILES = regress.gen.h regress.gen.c

test: test-init test-eof test-weof test-time regress

verify: test
	@./test.sh

bench test-init test-eof test-weof test-time: ../libevent.la
