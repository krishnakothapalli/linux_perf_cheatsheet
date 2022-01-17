
ssh ${adminUser}@$hostip1 'bash -s' <<EOF
  sleep 60
  #sudo vmstat --timestamp --wide 60 &
  #iostat -xmc 60 &
  #top  60&
  #dstat -a 60 &
  # Tools will display printable chars with 'dumb' terminal
  TERM=dumb
  while true; do
   sleep 60
   date
   echo "free -m"
   free -m
   echo "vmstat --timestamp  --wide 2 3"
   vmstat --timestamp  --wide 2 3
   echo "iostat -xmc -y 2 3"
   iostat -xmc -y 2 3
   echo "dstat -a 2 3"
   dstat -a 2 3
   echo "nping --tcp -p 22 10.0.0.4"
   sudo  nping --tcp -p 22 10.0.0.4
   echo "nping --tcp -p 3306 10.0.0.4"
   sudo  nping --tcp -p 3306 10.0.0.4
   echo "ping 10.0.0.4 -c 3"
   ping 10.0.0.4 -c 3
   echo "ip tcp_metrics show | grep 10.0.0.4"
   ip tcp_metrics show | grep 10.0.0.4
   echo "page faults: pid,min_flt,maj_flt,cmd"
   ps -o pid,min_flt,maj_flt,cmd -A | grep mysqld
   echo "cat /proc/net/sockstat;ss -s"
   cat /proc/net/sockstat;ss -s
   echo "top "
   TERM=dumb top -b -n 2 | grep "load average" -A 10
   #TERM=dumb top  -p $(pidof mysqld) -d 2 -n 2 
   #TERM=dumb top  -p $(pidof mysqld-vml) -d 2 -n 2
   #pgrep -x mysqld > /dev/null &&  TERM=dumb top  -p $(pidof mysqld) -d 2 -n 2|| echo "mysqld Process not found" 
   #pgrep -x mysqld-vml >/dev/null &&  TERM=dumb top  -p $(pidof mysqld-vml) -d 2 -n 2|| echo "mysqld-vml Process not found"

  done

EOF
