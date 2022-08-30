#!/bin/bash
#sample usage:
# sudo apt-get install -y elfutils
# sudo ./eu_stack_collecter.sh `pidof mysqld-vml`
# sudo ./eu_stack_analyser.sh `pidof mysqld-vml`

pid=$1

# TID 59962:
# #0  0x00007f2257d25539
# #1  0x00007f225771e4d1
# #2  0x00007f2259faa6db
# #3  0x00007f2257d2b61f

echo "Analyzing files in /tmp/eu_stack_profiler/"
cat /tmp/eu_stack_profiler/d_*.txt | awk -v pid=$pid '
  BEGIN  { addr_function_map["1"]="123"; }
  /^TID/ { print $0; }
  /^\#/  { stack_level=$1; addr=$2; 
           func_line="";
           if (addr in addr_function_map) {
              # addr is already in the hash map
           } else {
              # find the function name for the address and add in the hashmap
              # example: eu-addr2line 0x00007f2259fb1065 -p 59961 --functions
              cmd="eu-addr2line " addr " -p " pid " --functions "; 
              cmd | getline func_line; 
              close(cmd);
              # Run the command and get the result in func_line variable
              addr_function_map[addr]=func_line;
              #print "Ran " cmd ". In hash added " addr " -> " func_line > "/dev/stderr";
           }
           print stack_level " " addr " " addr_function_map[addr];
          }
  END { }' > /tmp/eu_stack_analyser_stage1.txt

echo "Stage1 completed: /tmp/eu_stack_analyser_stage1.txt"

# Example output of the above 
# TID 60425:
# #0 0x00007f2259fb1065 futex_abstimed_wait_cancelable inlined at /build/glibc-uZu3wS/glibc-2.27/nptl/pthread_cond_wait.c:539 in pthread_cond_timedwait@@GLIBC_2.3.2
# #1 0x00007f2259ab2412 vml_io_getevents
# #2 0x000056417e93c518 _ZN15LinuxAIOHandler7collectEv
# #3 0x000056417e93ce1a _ZN15LinuxAIOHandler4pollEPP10fil_node_tPPvP9IORequest
# #4 0x000056417e942c9b _Z14os_aio_handlermPP10fil_node_tPPvP9IORequest
# #5 0x000056417e7cf971 _Z12fil_aio_waitm
# #6 0x000056417ea431c8 ??
# #7 0x000056417ea3ac9c _ZNSt6thread11_State_implINS_8_InvokerISt5tupleIJ8RunnablePFvmEmEEEEE6_M_runEv
# #8 0x00007f225866e6df ??
# #9 0x00007f2259faa6db start_thread
# #10 0x00007f2257d2b61f __clone

cat /tmp/eu_stack_analyser_stage1.txt | awk '
  BEGIN { s = ""; }
  /^TID/ { print s; s = ""; }
  /^\#/ { if (s != "" ) { s = s " <- " $3} else { s = $3 } }
  END { print s }' > /tmp/eu_stack_analyser_stage2.txt

echo "Stage2 completed: /tmp/eu_stack_analyser_stage2.txt"
cat /tmp/eu_stack_analyser_stage2.txt  | \
      sort | uniq -c | sort -r -n -k 1,1 > /tmp/eu_stack_analyser_stage3.txt

echo "Stage3 completed: /tmp/eu_stack_analyser_stage3.txt"

cat /tmp/eu_stack_analyser_stage3.txt
