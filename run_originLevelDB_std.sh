#!/bin/bash
experiment_time=4
value_size=1KB
DISK=HDD"$experiment_time"
#dbfilename_o=/home/ming/"$DISK"_"$value_size"/lsm
dbfilename_o=./ssd/lsm
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
    workloadw_name=./workloads/glsmworkloadw_"$levelIn"_"$sizeRatio"_"$value_size"_2.spec
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
    workloadr_name=./workloads/"$workload_prefix"glsmworkloadr_"$levelIn"_"$sizeRatio"_"$value_size"_2.spec
    echo workloadrname:"$workloadr_name"
    __modifyConfig directIOFlag "$directIOFlag"
    for j in `seq 1 1`
    do
	let count=300/"$j"
	vmstat -n "$j" "$count"  > vmstat_"$count".txt &
	if [ x$workload_prefix != x ]
	then
	    echo "have arguments" 
	    echo $workload_prefix
            ./ycsbc -db leveldb -threads 8 -P $workloadr_name -dbfilename "$dbfilename" -configpath "$configpath" -skipLoad true -requestdistribution "$requestdistribution" -zipfianconst "$zipfianconst" 
	else
            echo ./ycsbc -db leveldb -threads 8 -P $workloadr_name -dbfilename "$dbfilename" -configpath "$configpath" -skipLoad true -requestdistribution "$requestdistribution" -zipfianconst "$zipfianconst" \> "$runname"_"$j".txt 2\>\&1
            ./ycsbc -db leveldb -threads 8 -P $workloadr_name -dbfilename "$dbfilename" -configpath "$configpath" -skipLoad true -requestdistribution "$requestdistribution" -zipfianconst "$zipfianconst" > "$runname"_"$j".txt 2>&1
            echo finish ycsbc
	    sync;echo 1 > /proc/sys/vm/drop_caches
	    if [ ! -d "$dirname" ]; then
		mkdir  -p "$dirname"
	    fi
	    mv "$runname"_"$j".txt "$dirname"
	    mv testlf1.txt "$dirname"/tlatency_"$runname"_"$j"_noseek_fix"$j".txt
	    mv nlf1.txt "$dirname"/tnlatency_"$runname"_"$bb"_"$j"_noseek_fix"$j".txt
	    cp vmstat_"$count".txt "$dirname"/vmstat_count"$count"_"$j".txt
            #sleep 100s
	fi
    done

}


types=(lsm)
bloom_bit_array=(4)
level=6
maxOpenfiles=60000
# directIOFlag=true
directIOFlag=false
blockCacheSizes=(8) #MB
sizeRatio=10
requestdistribution=zipfian
zipfianconsts=(1.1)
#dbfilename="$dbfilename_o""$level"
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
	for bloombits in ${bloom_bit_array[@]}
	do
	    echo bloombits:"$bloombits"
	    __modifyConfig bloomBits  "$bloombits"
	    dbfilename="$dbfilename_o"l"$level"b"$bloombits"s"$sizeRatio"
	    echo dbfilename: "$dbfilename"
	    if [ "$requestdistribution" = "zipfian" ]; then
                echo "zipfian"
		for zipfianconst in ${zipfianconsts[@]}
		do
			dirname=./result
		    #dirname=/home/ming/experiment/lsm_"$DISK"_read_zipfian"$zipfianconst"/experiment"$experiment_time"_"$value_size"/bloombits"$bloombits"level"$level"/open_files_"$maxOpenfiles"_notfound_100WRead_directIO"$directIOFlag"_blockCacheSize"$blockCacheSize"MB_sizeRatio"$sizeRatio"
		# __loadLSM load_bloombits"$bloombits"_level"$level"_lsmtype_"$lsmtype" "$dirname" "$level"  "$lsmtype" "$bloombits" 		    
		__runLSM tl03_bloombits"$bloombits"_level"$level"_lsmtype_"$lsmtype" "$dirname" "$level"  "$lsmtype" "$bloombits" 
		done
	    else
		echo "$requestdistribution"
		dirname=./result
		#dirname=/home/ming/experiment/lsm_"$DISK"_read_"$requestdistribution"/experiment"$experiment_time"_"$value_size"/bloombits"$bloombits"level"$level"/open_files_"$maxOpenfiles"_notfound_100WRead_directIO"$directIOFlag"_blockCacheSize"$blockCacheSize"MB_sizeRatio"$sizeRatio"
		zipfianconst=1.1
		# __loadLSM load_bloombits"$bloombits"_level"$level"_lsmtype_"$lsmtype" "$dirname" "$level"  "$lsmtype" "$bloombits" 
		__runLSM tl03_bloombits"$bloombits"_level"$level"_lsmtype_"$lsmtype" "$dirname" "$level"  "$lsmtype" "$bloombits" 
	    fi

	done
    done
done
#__runGLSM


