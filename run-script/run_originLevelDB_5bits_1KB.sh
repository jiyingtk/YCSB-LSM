#!/bin/bash
experiment_time=5
value_size=1KB
DISK=SSD"$experiment_time"
dbfilename_o=/home/ming/"$DISK"_"$value_size"/lsm
configpath=./configDir/leveldb_config.ini
section=basic
#arrayname=5
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
    workloadw_name=./workloads/glsmworkloadw_"$levelIn"_"$sizeRatio"_"$value_size".spec
    echo workloadname:"$workloadw_name"
    __modifyConfig directIOFlag false
    ./ycsbc -db leveldb -threads 1 -P $workloadw_name -dbfilename "$dbfilename" -configpath "$configpath" -skipLoad false > "$loadname"
    sync;echo 1 > /proc/sys/vm/drop_caches
    if [ ! -d "$dirname" ]; then
	mkdir  -p "$dirname"
    fi
    mv "$loadname" "$dirname"
    sleep 100s
    cp configDir/leveldb_config.ini "$dirname"
}

function __runLSM(){
    runname=$1
    runname="$runname"_run
    dirname=$2
    levelIn=$3
    ltype=$4
    bb=$5
    workloadr_name=./workloads/"$workload_prefix"glsmworkloadr_"$levelIn"_"$sizeRatio"_"$value_size".spec
    echo workloadrname:"$workloadr_name"
    __modifyConfig directIOFlag "$directIOFlag"
    for j in `seq 1 2`
    do
	let count=300/"$j"
	vmstat -n "$j" "$count"  > vmstat_"$count".txt &
	if [ x$workload_prefix != x ]
	then
	    ./ycsbc -db leveldb -threads 1 -P $workloadr_name -dbfilename "$dbfilename" -configpath "$configpath" -skipLoad true -requestdistribution "$requestdistribution" -zipfianconst "$zipfianconst" 
	else
            ./ycsbc -db leveldb -threads 1 -P $workloadr_name -dbfilename "$dbfilename" -configpath "$configpath" -skipLoad true -requestdistribution "$requestdistribution" -zipfianconst "$zipfianconst" > "$runname"_"$j".txt
	    sync;echo 1 > /proc/sys/vm/drop_caches
	    if [ ! -d "$dirname" ]; then
		mkdir  -p "$dirname"
	    fi
	    mv "$runname"_"$j".txt "$dirname"
	    mv testlf1.txt "$dirname"/latency_"$runname"_"$j"_noseek_fix"$j".txt
	    mv nlf1.txt "$dirname"/nlatency_"$runname"_bloom_"$bb"_"$j"_noseek_fix"$j".txt
	    cp vmstat_"$count".txt "$dirname"/vmstat_count"$count"_"$j".txt
            sleep 100s
	fi
    done

}


types=(lsm)
bloombits=(5)
level=6
maxOpenfiles=60000
directIOFlag=true
blockCacheSizes=(8 16 32 64) #MB
sizeRatio=10
requestdistribution=zipfian
zipfianconsts=(1.10 1.20)
#dbfilename="$dbfilename_o"l"$level"s"$sizeRatio"b"$bloombits"a"$arrayname"
dbfilename="$dbfilename_o"l"$level"b"$bloombits"s"$sizeRatio"
workload_prefix=$1
for blockCacheSize in ${blockCacheSizes[@]}
do
    let bcs=blockCacheSize*1024*1024
    __modifyConfig blockCacheSize "$bcs"
    __modifyConfig sizeRatio "$sizeRatio"
    for lsmtype in ${types[@]}
    do
	__modifyConfig bloomType 0
	__modifyConfig seekCompactionFlag false
	__modifyConfig maxOpenfiles "$maxOpenfiles"
	echo bloombits:"$bloombits"
	__modifyConfig bloomBits  "$bloombits"
	#dbfilename="$dbfilename_o"l"$level"b"$bloombits"s"$sizeRatio"
	echo dbfilename: "$dbfilename"
	if [ "$requestdistribution" = "zipfian" ]; then
            echo "zipfian"
	    for zipfianconst in ${zipfianconsts[@]}
	    do
		dirname=/home/ming/experiment/lsm_"$DISK"_read_zipfian"$zipfianconst"/experiment"$experiment_time"_"$value_size"/bloombits"$bloombits"level"$level"/open_files_"$maxOpenfiles"_notfound_100WRead_directIO"$directIOFlag"_blockCacheSize"$blockCacheSize"MB_sizeRatio"$sizeRatio"
		__runLSM l03_bloombits"$bloombits"_level"$level"_lsmtype_"$lsmtype" "$dirname" "$level"  "$lsmtype" "$bloombits" 
	    done
	else
	    echo "$requestdistribution"
	    dirname=/home/ming/experiment/lsm_"$DISK"_read_"$requestdistribution"/experiment"$experiment_time"_"$value_size"/bloombits"$bloombits"level"$level"/open_files_"$maxOpenfiles"_notfound_100WRead_directIO"$directIOFlag"_blockCacheSize"$blockCacheSize"MB_sizeRatio"$sizeRatio"
	    __runLSM l03_bloombits"$bloombits"_level"$level"_lsmtype_"$lsmtype" "$dirname" "$level"  "$lsmtype" "$bloombits" 
	fi
    done
done
#__runGLSM


