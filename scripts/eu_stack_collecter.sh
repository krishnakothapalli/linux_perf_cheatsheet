#!/bin/bash
#sample usage:
# sudo apt-get install -y elfutils
# sudo $eu_stack_collecter.sh `pidof mysqld-vml`
# sudo $eu_stack_analyser.sh `pidof mysqld-vml`

# Ref: https://developpaper.com/profiling-and-performance-optimization-summary/
pid=$1
sleep_time_between_collection_secs=1 # can be 0.2 secs also
number_of_collections=100
dir="/tmp/eu_stack_profiler"

rm -rf $dir 
mkdir $dir
for x in $(seq 0 $number_of_collections)
do
    eu-stack -q -p $pid > $dir/d_$x.txt || true
    sleep $sleep_time_between_collection_secs
done


#
# /home/narwhal/orcasql-mysql/out/vmlbuild_RelWithDebInfo/subprojects/Source/myfile-common_external/ktr/FlameGraph/stackcollapse-elfutils.pl /tmp/eu_stack_profiler/d*txt

# eu-addr2line 0x00007f2257d2b61f -p 59961 --functions  --pretty-print
