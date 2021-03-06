# Respect the environment
ifeq ($(CC),)
  CC=gcc
endif

UNAME=$(shell uname)
CPU=$(shell uname -p)
MARCH=$(shell uname -m)

WARNINGS = -Wall
DEBUG = -g -ggdb3

CFLAGS = $(WARNINGS) $(DEBUG) 

COMP=$(CC)
ifeq ($(UNAME),Darwin)
  LDOPT=-dynamiclib -undefined dynamic_lookup
  LINKER=$(CC) $(LDOPT)
  SUFFIX=dylib
  BIN_RPATH=
  SONAME=-current_version $(VERSION) -compatibility_version $(VERSION) -install_name /usr/local/lib/librubinius-$(VERSION).$(SUFFIX)
  ifeq ($(CPU),powerpc)
    export MACOSX_DEPLOYMENT_TARGET=10.4
  endif
else
  LDOPT=-shared
  LINKER=$(CC) -shared
  BIN_RPATH=-Wl,-rpath -Wl,/usr/local/lib
  SUFFIX=so
  SONAME=-Wl,-soname,librubinius-$(VERSION).$(SUFFIX)
endif

ifndef VERBOSE
  COMP=@echo CC $@;$(CC)
  LINKER=@echo LINK $@;$(CC) $(LDOPT)
endif

RBXLIB=librubinius-$(VERSION).$(SUFFIX)
