#ifndef BASIC_CONFIG_HH_
#define BASIC_CONFIG_HH_

#include <string>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/ini_parser.hpp>
#include <boost/smart_ptr.hpp>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include<cstddef>
typedef  unsigned long long  ULL;

template<typename T>
class Basic_ConfigMod {
public:

    static T& getInstance() {
         // Guaranteed to be destroyed
        if(instance == NULL){
	    instance = boost::make_shared<T>();
	}
        // Instantiated on first use
        return *instance;
    }

    void setConfigPath (const char* key);
  
protected:
    Basic_ConfigMod() {}
    ~Basic_ConfigMod() {}
    static boost::shared_ptr<T> instance;
    boost::property_tree::ptree _pt;
    bool readBool (const char* key);
    bool readBool (const char* key, const bool defaultVal);
    int readInt (const char* key);
    double readFloat(const char* key);
    ULL readULL (const char* key);
    unsigned long readUL(const char *key);
    std::string readString (const char* key);
    size_t readSize_t(const char* key);
     
};
class LevelDB_ConfigMod:public Basic_ConfigMod<LevelDB_ConfigMod>{
private:
    friend class Basic_ConfigMod<LevelDB_ConfigMod>;
    std::string _bloom_filename;
    std::string _vlog_filename;
    std::string _bloom_bits_array_filename;
    int _max_open_files;
    bool _hierarchical_bloom_flag;
    int _bloom_bits;
    bool _open_log;
    int _max_file_size;
    uint64_t _region_divide_size;
    int _bloom_type;  //0 means origin bloom filter, 1 means  hierarchical bloom filter, 2 means multi_bloom_filter
    bool _compression_flag;
    bool _directIO_flag;
    bool _seek_compaction_flag;
    bool _force_disable_compaction_flag;
    bool _statistics_open;
    int _lrus_num;
    double _filters_capacity_ratio;
    double _l0_base_ratio;
    int _base_num;
    uint64_t _life_time;
    bool _setFreCountInCompaction;
    int _logBase;
    int _init_filter_num;
    double _slowRatio;
    double _changeRatio;
    int _sizeRatio;
    int _valueSize;
    int _runMode;
    int _filterBaseLg;
    double _extraValue1;
    bool _forceDeleteLevel0File;
    size_t _blockCacheSize;
    bool _useLRUCache;
public:
    std::string getBloom_filename();
    std::string getVlogFilename();
    int getMax_open_files();
    int getBloomType();
    int getBloom_bits();
    bool getOpen_log();
    int getMax_file_size();
    uint64_t getRegion_divide_size();
    void setConfigPath(const char*key);
    bool getCompression_flag();
    bool getDirectIOFlag();
    bool getSeekCompactionFlag();
    bool getForceDisableCompactionFlag();
    bool getStatisticsOpen();
    std::string getBitsArrayFilename();
    int getLRUsNum();
    double getFiltersCapacityRatio();
    double getL0BaseRatio();
    int getBaseNum();
    uint64_t getLifeTime();
    bool getSetFreCountInCompaction();
    int getLogBase();
    int getInitFilterNum();
    double getSlowRatio();
    double getChangeRatio();
    size_t getBlockCacheSize();
    bool getUseLRUCache();
    int getSizeRatio();
    int getValueSize();
    int getFilterBaseLg();
    int getRunMode();
    double getExtraValue1();
    bool getForceDeleteLevel0File();
};

#endif
