//
//  ycsbc.cc
//  YCSB-C
//
//  Created by Jinglei Ren on 12/19/14.
//  Copyright (c) 2014 Jinglei Ren <jinglei@ren.systems>.
//

#include <cstring>
#include <string>
#include <iostream>
#include <vector>
#include <future>
#include "core/utils.h"
#include "core/timer.h"
#include "core/client.h"
#include "core/core_workload.h"
#include "db/db_factory.h"
#include<boost/timer.hpp>
#include<memory>
using namespace std;

void UsageMessage(const char *command);
bool StrStartWith(const char *str, const char *pre);
string ParseCommandLine(int argc, const char *argv[], utils::Properties &props);
bool end_flag_ = false;
utils::Properties *props_ptr = NULL;
size_t DelegateClient(ycsbc::DB *db, ycsbc::CoreWorkload *wl, const size_t num_ops,
    bool is_loading) {
  FILE *fp_phase = NULL;
  if(!end_flag_){
    db->Init();
    fp_phase = fopen("phase_time.txt","w");
  }
  size_t ops[] = {0,0,0,0};
  double durations[] = {0,0,0,0};
  ycsbc::Client client(*db, *wl);
  size_t oks = 0;
  std::string out_string;
  int skipratio_inload = wl->skipratio_inload;
  cerr<<"skipratio_inload"<<skipratio_inload<<endl;
  cerr<<"num_ops"<<num_ops<<endl;
  struct timeval start_insert_time,end_insert_time,res_time;
  struct timeval start_phase_time,end_phase_time;
  gettimeofday(&start_insert_time,NULL);
  gettimeofday(&start_phase_time,NULL);
  for (size_t i = 0; i < num_ops; ++i) {
    if (is_loading) {
      if(skipratio_inload&&i%skipratio_inload!=0){
	client.DoInsert(false);
	continue;
      }
      oks += client.DoInsert();
    } else {
      oks += client.DoTransaction(ops,durations);
    }
    if(i%10240 == 0){
      if(is_loading && i%102400 == 0){
	cerr<<"operation count:"<<i<<"\r";
	gettimeofday(&end_phase_time,NULL);
	timersub(&end_phase_time,&start_phase_time,&res_time);
	start_phase_time = end_phase_time;
	fprintf(fp_phase,"%lu\n",res_time.tv_sec * 1000000 + res_time.tv_usec);
      }else if(!is_loading){
	cerr<<"operation count:"<<i<<"\r";
      }
    }
  }
  gettimeofday(&end_insert_time,NULL);
  timersub(&end_insert_time,&start_insert_time,&res_time);
  cout<<endl;
  if(!is_loading){
    cout<<"WRITE latency "<<endl;
    cout<<durations[ycsbc::Operation::INSERT]/ops[ycsbc::Operation::INSERT]<<"us"<<" Write ops: "<<ops[ycsbc::Operation::INSERT]<<endl;
    cout<<"READ latency(including zero-result lookup)"<<endl;
    cout<<durations[ycsbc::Operation::READ]/ops[ycsbc::Operation::READ]<<"us"<<" Read ops: "<<ops[ycsbc::Operation::READ]<<endl;
    cout<<"Zero-result lookup: "<<endl;
    cout<<durations[2]/ops[2]<<"us"<<" Zero-result ops: "<<ops[2]<<endl;
    cout<<"IOPS: "<<endl;
    cout<<ops[3]/(durations[3]/1000000)<<endl;
    db->doSomeThing("printStats");
    // db->doSomeThing("printAccessFreq");
    if(wl->adjust_filter_&&!end_flag_){
      db->doSomeThing("printAccessFreq");
      end_flag_ = true;
      ycsbc::CoreWorkload nwl;
      nwl.Init(*props_ptr);
      cout<<"Adjust bloom filter accroding to access frequencies"<<endl;
      //db->doSomeThing();
      return DelegateClient(db,&nwl,num_ops,is_loading);
    }
  }else{
    cout<<"Total time of insert: "<<res_time.tv_sec * 1000000 + res_time.tv_usec<<"us"<<endl;
    cerr<<"oks: "<<oks<<endl;
    cout<<"Per insert time: "<<(res_time.tv_sec * 1000000 + res_time.tv_usec)*1.0/oks<<"us"<<endl;
  }
  end_flag_ = true;
  db->Close();
  if(fp_phase != NULL){
    fclose(fp_phase);
    fp_phase = NULL;
  }
  return oks;
}

int main(const int argc, const char *argv[]) {
  utils::Properties props;
  string file_name = ParseCommandLine(argc, argv, props);
  struct timeval start_main_time,end_main_time,res_main_time;
  ycsbc::DB *db = ycsbc::DBFactory::CreateDB(props);
  if (!db) {
    cout << "Unknown database name " << props["dbname"] << endl;
    exit(0);
  }

  ycsbc::CoreWorkload wl;
  wl.Init(props);
  props_ptr = &props;
  const size_t num_threads = static_cast<size_t>(stoi(props.GetProperty("threadcount", "1")));
  bool skipLoad = utils::StrToBool(props.GetProperty("skipLoad",
						   "false"));
  // Loads data
  ycsbc::WallTimer loadRunTimer;
  loadRunTimer.Start();
  vector<future<size_t>> actual_ops;
  size_t total_ops = 0;
  sscanf(props[ycsbc::CoreWorkload::RECORD_COUNT_PROPERTY].c_str(),"%zu",&total_ops);
  size_t sum = 0;
  gettimeofday(&start_main_time,NULL);
  if(!skipLoad){
	for (size_t i = 0; i < num_threads; ++i) {
	    actual_ops.emplace_back(async(launch::async,
		DelegateClient, db, &wl, total_ops / num_threads, true));
	}
	assert(actual_ops.size() == num_threads);
	for (auto &n : actual_ops) {
	    assert(n.valid());
	    sum += n.get();
	}
	cerr << "# Loading records:\t" << sum << endl;
	cerr << "load time: " << loadRunTimer.elapsed() <<"us"<<endl;
    
    //loadRunTimer.restart();
    // Peforms transactions
	actual_ops.clear();
   }
  total_ops = stoi(props[ycsbc::CoreWorkload::OPERATION_COUNT_PROPERTY]);
  ycsbc::WallTimer timer;
  db->openStatistics();
  timer.Start();
  for (size_t i = 0; i < num_threads; ++i) {
    actual_ops.emplace_back(async(launch::async,
        DelegateClient, db, &wl, total_ops / num_threads, false));
  }
  assert(actual_ops.size() == num_threads);

  sum = 0;
  for (auto &n : actual_ops) {
    assert(n.valid());
    sum += n.get();
  }
  double duration = timer.elapsed();
  cerr<< endl;
  cerr << "# Transaction throughput (KTPS)" << endl;
  cerr << total_ops / (duration/1000000) / 1000 << endl;
  cerr << props["dbname"] << '\t' << file_name << '\t' << num_threads << '\t'<<endl;;
  cerr << "run time: " << timer.elapsed() <<"us"<<endl;
  delete db;
  gettimeofday(&end_main_time,NULL);
  timersub(&end_main_time,&start_main_time,&res_main_time);
  cout<<"Total time of main: "<<res_main_time.tv_sec * 1000000 + res_main_time.tv_usec<<"us"<<endl;

}

string ParseCommandLine(int argc, const char *argv[], utils::Properties &props) {
  int argindex = 1;
  string filename;
  string latency_filename;
  while (argindex < argc && StrStartWith(argv[argindex], "-")) {
    if (strcmp(argv[argindex], "-threads") == 0) {
      argindex++;
      if (argindex >= argc) {
        UsageMessage(argv[0]);
        exit(0);
      }
      props.SetProperty("threadcount", argv[argindex]);
      argindex++;
    } else if (strcmp(argv[argindex], "-db") == 0) {
      argindex++;
      if (argindex >= argc) {
        UsageMessage(argv[0]);
        exit(0);
      }
      props.SetProperty("dbname", argv[argindex]);
      argindex++;
    } else if (strcmp(argv[argindex], "-host") == 0) {
      argindex++;
      if (argindex >= argc) {
        UsageMessage(argv[0]);
        exit(0);
      }
      props.SetProperty("host", argv[argindex]);
      argindex++;
    } else if (strcmp(argv[argindex], "-port") == 0) {
      argindex++;
      if (argindex >= argc) {
        UsageMessage(argv[0]);
        exit(0);
      }
      props.SetProperty("port", argv[argindex]);
      argindex++;
    } else if (strcmp(argv[argindex], "-slaves") == 0) {
      argindex++;
      if (argindex >= argc) {
        UsageMessage(argv[0]);
        exit(0);
      }
      props.SetProperty("slaves", argv[argindex]);
      argindex++;
    } else if (strcmp(argv[argindex], "-P") == 0) {
      argindex++;
      if (argindex >= argc) {
        UsageMessage(argv[0]);
        exit(0);
      }
      filename.assign(argv[argindex]);
      ifstream input(argv[argindex]);
      try {
        props.Load(input);
      } catch (const string &message) {
        cout << message << endl;
        exit(0);
      }
      input.close();
      argindex++;
    } else if(strcmp(argv[argindex],"-dbfilename") == 0){
	argindex++;
	if(argindex >= argc){
	    UsageMessage(argv[0]);
	    exit(0);
	}
	props.SetProperty("dbfilename", argv[argindex]);
        argindex++;
    }else if(strcmp(argv[argindex],"-configpath") == 0){
	argindex++;
	if(argindex >= argc){
	    UsageMessage(argv[0]);
	    exit(0);
	}
	props.SetProperty("configpath", argv[argindex]);
        argindex++;
    }else if(strcmp(argv[argindex],"-skipLoad") == 0){
	argindex++;
	if(argindex >= argc){
	    UsageMessage(argv[0]);
	    exit(0);
	}
	props.SetProperty("skipLoad", argv[argindex]);
        argindex++;
    }else if(strcmp(argv[argindex],"-requestdistribution") == 0){
	argindex++;
	if(argindex >= argc){
	    UsageMessage(argv[0]);
	    exit(0);
	}
	props.SetProperty("requestdistribution", argv[argindex]);
        argindex++;
   }else if(strcmp(argv[argindex],"-zipfianconst") == 0){
	argindex++;
	if(argindex >= argc){
	    UsageMessage(argv[0]);
	    exit(0);
	}
	props.SetProperty("zipfianconst", argv[argindex]);
        argindex++;
   }else {
      cout << "Unknown option '" << argv[argindex] << "'" << endl;
      exit(0);
    }
  }

  if (argindex == 1 || argindex != argc) {
    UsageMessage(argv[0]);
    exit(0);
  }

  return filename;
}

void UsageMessage(const char *command) {
  cout << "Usage: " << command << " [options]" << endl;
  cout << "Options:" << endl;
  cout << "  -threads n: execute using n threads (default: 1)" << endl;
  cout << "  -db dbname: specify the name of the DB to use (default: basic)" << endl;
  cout << "  -P propertyfile: load properties from the given file. Multiple files can" << endl;
  cout << "                   be specified, and will be processed in the order specified" << endl;
}

inline bool StrStartWith(const char *str, const char *pre) {
  return strncmp(str, pre, strlen(pre)) == 0;
}

