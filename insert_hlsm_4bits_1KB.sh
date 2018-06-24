#!/bin/bash
experiment_time=4
value_size=1KB
DISK=SSD"$experiment_time"
dbfilename_o=/home/ming/"$DISK"_"$value_size"/hlsm
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
    workloadw_name=./workloads/ilsmworkloadw_"$levelIn"_"$sizeRatio"_"$value_size".spec
    echo workloadname:"$workloadw_name"
    __modifyConfig directIOFlag false
    ./ycsbc -db leveldb -threads 1 -P $workloadw_name -dbfilename "$dbfilename" -configpath "$configpath" -skipLoad false > "$loadname"
    sync;echo 1 > /proc/sys/vm/drop_caches
    sleep 100s
    if [ ! -d "$dirname" ]; then
	mkdir  -p "$dirname"
    fi
    mv "$loadname" "$dirname"
    cp configDir/leveldb_config.ini "$dirname"
}

function __runLSM(){
    runname=$1
    runname="$runname"_run
    dirname=$2
    levelIn=$3
    ltype=$4
    bb=$5
    workloadr_name=./workloads/ilsmworkloadr_"$levelIn"_"$sizeRatio"_"$value_size".spec
    echo workloadrname:"$workloadr_name"
    __modifyConfig directIOFlag "$directIOFlag"
    for j in `seq 1 1`
    do
	let count=300/"$j"
	vmstat -n "$j" "$count"  > vmstat_"$count".txt &
        ./ycsbc -db leveldb -threads 1 -P $workloadr_name -dbfilename "$dbfilename" -configpath "$configpath" -skipLoad true -requestdistribution "$requestdistribution" -zipfianconst "$zipfianconst" > "$runname"_"$j".txt
	sync;echo 1 > /proc/sys/vm/drop_caches
	if [ ! -d "$dirname" ]; then
	    mkdir  -p "$dirname"
	fi
	mv "$runname"_"$j".txt "$dirname"
	mv testlf1.txt "$dirname"/latency_l"$levelIn"_lsmtype_"$ltype"_bloom_"$bb"_"$j"_noseek_fix"$j".txt
	mv nlf1.txt "$dirname"/nlatency_l"$levelIn"_lsmtype_"$ltype"_bloom_"$bb"_"$j"_noseek_fix"$j".txt
	cp vmstat_"$count".txt "$dirname"/vmstat_count"$count"_"$j".txt
        #sleep 100s
    done

}

lsmtype=hlsm
bloom_bit_array=(4)
level=6
sizeRatio=10
requestdistribution=uniform
zipfianconsts=(0.99) 
directIOFlag=false
for bloombits in ${bloom_bit_array[@]}
do
	echo bloombits:"$bloombits"
	__modifyConfig bloomBits  "$bloombits"
	__modifyConfig sizeRatio  "$sizeRatio"
	echo level:"$level"
	dbfilename="$dbfilename_o"l"$level"b"$bloombits"s"$sizeRatio"
	echo "$dbfilename"		
        __modifyConfig bloomFilename /home/ming/workspace/blooml"$level"_"$bloombits"_h1_"$sizeRatio".txt       	
	if [ "$requestdistribution" = "zipfian" ]; then
	    echo "zipfian"
	    for zipfianconst in ${zipfianconsts[@]}
	    do
		__runLSM insertl03bloombits"$bloombits"_level"$level"_lsmtype_"$lsmtype" /home/ming/experiment/hlsm_"$DISK"_read/skipratio0_"$requestdistribution""$zipfianconst"_sizeRatio"$sizeRatio" "$level"  "$lsmtype" "$bloombits"
	    done
	else
	    echo "$requestdistribution"
	    __runLSM insertl03bloombits"$bloombits"_level"$level"_lsmtype_"$lsmtype" /home/ming/experiment/hlsm_"$DISK"_read/skipratio0_"$requestdistribution"_sizeRatio"$sizeRatio" "$level"  "$lsmtype" "$bloombits"
	fi

done






























