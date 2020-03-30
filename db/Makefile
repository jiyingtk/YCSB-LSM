CC=g++
CFLAGS=-std=c++11 -g2 -c  -Wall -fgnu-tm -L/home/kvgroup/tcj/EBF-extend/multi-bf-lsm/out-shared -Wl,-rpath=/home/kvgroup/tcj/EBF-extend/multi-bf-lsm/out-shared -lleveldb -L/home/kvgroup/tcj/data1/ElasticBF/rocksdb-5.14.fb -Wl,-rpath=/home/kvgroup/tcj/data1/ElasticBF/rocksdb-5.14.fb -lrocksdb
INCLUDES=-I ../ -I /home/kvgroup/tcj/EBF-extend/multi-bf-lsm/include  -I /home/kvgroup/tcj/data1/ElasticBF/rocksdb-5.14.fb/include
SOURCES=$(wildcard *.cc)
OBJECTS=$(SOURCES:.cc=.o)

all: $(SOURCES) $(OBJECTS)

.cc.o:
	$(CC) $(CFLAGS) $(INCLUDES) $< -o $@

clean:
	$(RM) $(OBJECTS)

