CC=g++
CFLAGS=-std=c++11 -g2  -Wall -pthread -I./ -I/home/kvgroup/tcj/EBF-extend/multi-bf-lsm/include -L/home/kvgroup/tcj/EBF-extend/multi-bf-lsm/out-shared -Wl,-rpath=/home/kvgroup/tcj/EBF-extend/multi-bf-lsm/out-shared
LDFLAGS= -lpthread -ltbb -lhiredis -lleveldb -lboost_system -lboost_thread
SUBDIRS=core db redis
SUBSRCS=$(wildcard core/*.cc) $(wildcard db/*.cc)
OBJECTS=$(SUBSRCS:.cc=.o)
EXEC=ycsbc

all: $(SUBDIRS) $(EXEC)

$(SUBDIRS):
	$(MAKE) -C $@

$(EXEC): $(wildcard *.cc) $(OBJECTS)
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir $@; \
	done
	$(RM) $(EXEC)

.PHONY: $(SUBDIRS) $(EXEC)

