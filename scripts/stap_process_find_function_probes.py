# prints function names based on the stap -l output and create correspoding probes
# Sample usage:
#  Update variables below
#  $ python3 stap_process_find_function_probes.py  > /tmp/function_probes.txt
import re;
import sys;
import subprocess;

# replace path name of your code
my_code_dir="/home/narwhal/linux_perf_cheatsheet"

# replace your library name or program name
my_process_name = "/tmp/simple"

# update this with your list
ignore_function_set = ("Start", "Pop", "AioEvents", "weak_io_getevents", "StopRequested", "test_and_set", "set", "~set", "event_base_set", "event_set", "fetch_sub", "fetch_add", "fetch_or", "dup", "set", "APPEND_CHAIN", "APPEND_CHAIN_MULTICAST", "unlock", "lock", "assert_owner", "owns_lock")

# >>>>>>> unlock latency micro sec. min/avg/max:4/44/212463 count:92594
stap_output_filename = "/tmp/stap_output.txt"

out_function_set = set()

debug = 0
stap_command = """/usr/bin/stap -l 'process("{ProcessName}").function("*")' > {OutputFile}  2>&1 """.format(ProcessName=my_process_name, OutputFile=stap_output_filename)

print("Running command:"+stap_command)

return_code=subprocess.call(stap_command, shell=True)
if return_code !=0:
    print("ERROR stap program returned error:"+return_code)
    exit(return_code)

#Sample input line format
#process("/tmp/simple").function("io_thread_function@/home/narwhal/linux_perf_cheatsheet/simple.cc:82")
for line in open(stap_output_filename, "r").readlines(): #sys.stdin:
    # parse out the function name
    match_function = re.search('function\(\"(?P<function_name>.*)@(?P<file_name>.*):', line)
    # filter out some functions that have < and _ at the beginning and only in the my_code_dir. Ignore header files
    if match_function and  re.search("<", line) is None and re.search("function\(\"_", line) is None and re.search("function\(\"operator", line) is None :
        function_name = match_function.group('function_name')
        file_name = match_function.group('file_name')
        if debug != 0 :
            print ("function_name:" + function_name)
            print ("file_name:" + file_name)        
        if function_name not in ignore_function_set and re.search(" ", function_name) is None and re.search(my_code_dir, file_name): # and file_name.find(".h:") == -1 :
            #print function_name
            out_function_set.add(function_name)
        else:
            if debug != 0 :            
                print ("IGNORING:" + file_name + ":" + function_name)        

call_probe = "probe "
return_probe = "probe "
for function_name in sorted(out_function_set):
    call_probe = call_probe+"""process("{ProcessName}").function("{FunctionName}"),""".format(ProcessName=my_process_name, FunctionName=function_name)
    return_probe = return_probe +"""process("{ProcessName}").function("{FunctionName}").return,""".format(ProcessName=my_process_name, FunctionName=function_name)

call_probe = call_probe[:-1] # remove last "," character
return_probe = return_probe[:-1] # remove last "," character
print ("=======Call probe is====================")
print (call_probe)
print ("=======Return probe is====================")
print (return_probe)
    
    
    
