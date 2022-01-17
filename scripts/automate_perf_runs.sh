#$ ./krishna_auto.sh >> output.txt 2>&1
#egrep  "RUNNING MYSQL|transactions|real	" output.txt
#egrep  "RUNNING MYSQL|transactions|real	|thds:" output.txt
# egrep  "RUNNING MYSQL|transactions|real|rtt min/avg/max/mdev|Avg rtt" output.txt
#egrep  "RUNNING|transactions|real|Max rtt|write: IOPS="  output.txt

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
do
    source parameters
    # calculate thread count dynamically
    #thread_count=$((i*50))
    thread_count=300
    # reboot VMs
    # need to do "az login"
     echo "REBOOTING the systems...."
    az vm restart -g krkothap-test-remove2-rg -n replica1
    az vm restart -g krkothap-test-remove2-rg -n replica2
    az vm restart -g krkothap-test-remove2-rg -n narwhal-metadata-server
    sleep 240
    # need to start ./periodic_stats_collector.sh only once
    ./periodic_stats_collector.sh&
       
        source parameters

       echo "=========RUNNING MYSQL WITH VML $i== threads ${thread_count}==========="
       ssh ${adminUser}@$hostip1 'bash -s' << EOF
       bash ./vmlprep.sh
       bash ./vmlprep.sh
       sleep 60

EOF
       ssh ${adminUser}@$hostip1 'bash -s' << EOF
       echo "STATS BEFORE"
       bash ./stats.sh
EOF
        export vmlEnable=1
        ./setup_mysql.sh; sleep 10; #TIME for metadata to startup
        ./setup_mysql.sh; sleep 10; #running second time as there is some bug in config and it crashes
        
       ./run_bench.sh -r 600 -t ${thread_count} -p 1; sleep 10 ;
       ./run_bench.sh -r 600 -t ${thread_count} -p 0;sleep 10 ;
       ./run_bench.sh -r 600 -t ${thread_count} -p 0;sleep 10 ;

       ssh ${adminUser}@$hostip1 'bash -s' << EOF
       echo "STATS AFTER"
       bash ./stats.sh
EOF

       ssh ${adminUser}@$hostip1 'bash -s' << EOF       
       echo "--VML LOGS--"
       more /home/narwhal/mysqld-vml-init.err /home/narwhal/mysqld-vml.err | cat
       rm  /home/narwhal/mysqld-vml-init.err /home/narwhal/mysqld-vml.err 
EOF

ssh ${adminUser}@${metadatahostip} 'bash -s' << EOF11
        echo "--METADATA LOG--"
        more /home/narwhal/mysqld-init.err /home/narwhal/mysqld.err
        rm  /home/narwhal/mysqld-init.err /home/narwhal/mysqld.err
EOF11
       
       
    echo "REBOOTING the systems...."
    az vm restart -g krkothap-test-remove2-rg -n replica1
    az vm restart -g krkothap-test-remove2-rg -n replica2
    az vm restart -g krkothap-test-remove2-rg -n narwhal-metadata-server
    sleep 240
    ./periodic_stats_collector.sh&       
       

    
        echo "=========RUNNING MYSQL WITH OUT VML $i== threads ${thread_count}==========="
        ssh ${adminUser}@$hostip1 'bash -s' << EOF
        bash ./nonvmlprep.sh
        bash ./nonvmlprep.sh
        sleep 60
EOF

       ssh ${adminUser}@$hostip1 'bash -s' << EOF
       echo "STATS BEFORE"
       bash ./stats.sh
EOF
        
       export vmlEnable=0
       ./setup_mysql.sh; sleep 10;
       ./setup_mysql.sh; sleep 10; #running second time as there is some bug in config and it crashes
       ./run_bench.sh -r 600 -t ${thread_count} -p 1; sleep 10 ;
       ./run_bench.sh -r 600 -t ${thread_count} -p 0;sleep 10 ;
       ./run_bench.sh -r 600 -t ${thread_count} -p 0;sleep 10 ;
       
       ssh ${adminUser}@$hostip1 'bash -s' << EOF
       echo "STATS AFTER"
       bash ./stats.sh
EOF
       
ssh ${adminUser}@$hostip1 'bash -s' << EOF       
       echo "--NON-VML LOGS--"
       more /home/narwhal/mysqld-init.err /home/narwhal/mysqld.err | cat
       rm  /home/narwhal/mysqld-vml.err /home/narwhal/mysqld.err 
EOF


done
