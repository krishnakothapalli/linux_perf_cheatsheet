#!/bin/bash
nsamples=1
sleeptime=1
pid=$(pidof mysqld-vml)

for x in $(seq 1 $nsamples)
do
  gdb -ex "set pagination 0" -ex "thread apply all bt" -batch -p $pid
  sleep $sleeptime
done | \
awk '
  BEGIN { s = ""; }
  /^Thread/ { print s; s = ""; }
  /^\#/ { fn= $2 " in " $4;  gsub(/0x[0-f]+/, "",fn);  gsub(/[0-9]+/, "",fn);  if (s != "" ) { s = s " <-- " fn} else { s = fn} }
  END {gsub(/[[:blank:]]/, "", s); print s }' | \
sort | uniq -c | sort -r -n -k 1,1
