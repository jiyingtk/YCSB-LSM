#!/bin/bash
experiment_time=6
DISK=SSD"$experiment_time"
dbfilename=/home/ming/RAID0_"$DISK"/mlsm
configpath=./configDir/leveldb_config.ini
section=basic

function __modifyConfig(){
    key=$1
    value=$2
    ./modifyConfig.py "$configpath" "$section" "$key" "$value"   
}

function __loadLSM(){
    rm -rf "$dbfilename"
    loadname=$1
    loadname="$loadname"_load.txt
    dirname=$2
    levelIn=$3
    ltype=$4
    bb=$5
    workloadw_name=./workloads/glsmworkloadw_"$levelIn".spec
    if [ ! -d "$dirname" ]; then
	mkdir  -p "$dirname"
    fi
    __modifyConfig directIOFlag false
    ./ycsbc -db leveldb -threads 1 -P $workloadw_name -dbfilename "$dbfilename" -configpath "$configpath" -skipLoad false > "$loadname"
    sync;echo 1 > /proc/sys/vm/drop_caches
    sleep 100s
    mv "$loadname" "$dirname"
}

function __runLSM(){
    runname=$1
    runname="$runname"_run
    dirname=$2
    levelIn=$3
    ltype=$4
    bb=$5
    workloadr_name=./workloads/glsmworkloadr_"$levelIn".spec
    base_nums=(8 16 32)
    life_times=(100 1000 10000)
    __modifyConfig directIOFlag true
    if [ ! -d "$dirname" ]; then
	mkdir  -p "$dirname"
    fi
    for base_num in ${base_nums[@]}
#    for life_time in ${life_times[@]}
     do
#	echo life_time "$life_time"
	echo base_num "$base_num"
	section=LRU
#	__modifyConfig LifeTime "$life_time"
	__modifyConfig BaseNum "$base_num"
        ./ycsbc -db leveldb -threads 1 -P $workloadr_name -dbfilename "$dbfilename" -configpath "$configpath" -skipLoad true > "$runname"_base"$base_num".txt
#	./ycsbc -db leveldb -threads 1 -P $workloadr_name -dbfilename "$dbfilename" -configpath "$configpath" -skipLoad true > "$runname"_life_time"$life_time".txt
	sync;echo 1 > /proc/sys/vm/drop_caches
	mv "$runname"_base"$base_num".txt "$dirname"
#	mv "$runname"_life_time"$life_time".txt "$dirname"
	mv testlf1.txt "$dirname"/latency_l"$levelIn"_lsmtype_"$ltype"_bloom_"$bb"_base"$base_num".txt
	mv level?_access_frequencies.txt "$dirname"/
        sleep 100s
    done
    cp configDir/leveldb_config.ini "$dirname"/
}


types=(lsm)
bloombits=6
level=6
dbfilename="$dbfilename""$level"
FilterCapacityRatios=(4.0 6.0)
logbases=(4 5 6)
for FilterCapacityRatio in ${FilterCapacityRatios[@]}
do
    __modifyConfig bloomType 2
    __modifyConfig seekCompactionFlag false
    echo Counterpart bloombits:"$bloombits"
    __modifyConfig bloomBits  "$bloombits"
    section=LRU
    __modifyConfig FilterCapacityRatio "$FilterCapacityRatio"
    section=basic
    for logbase in ${logbases[@]}
    do
	section=LRU
	__modifyConfig LogBase "$logbase"
	section=basic
	dirname=/home/ming/workspace/YCSB-C/lsm_"$DISK"_read_zipfian1.1_multi_filter/experiment"$experiment_time"/BGShrinkUsage_FilterCapacityRatio_"$FilterCapacityRatio"_logbase_"$logbase"lru0_300WRead
	#__loadLSM bloombits"$bloombits"_level"$level"_lsmtype_"$lsmtype" "$dirname" "$level"  "$lsmtype" "$bloombits"
	__runLSM bloombits"$bloombits"_level"$level"_lsmtype_"$lsmtype" "$dirname" "$level"  "$lsmtype" "$bloombits"
    done
done

#__runGLSM


