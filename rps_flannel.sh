#!/bin/bash
 
start_rps() {
  net_interface=`ip link show | grep "state" | awk '{print $2}' | grep 'flannel' | tr ":\n" " "`
  for em in ${net_interface[@]}
  do
      rq_count=`ls /sys/class/net/$em/queues/rx-* -d | wc -l`
      rps_flow_cnt_value=`expr 32768 / $rq_count`
 
      for ((i=0; i< $rq_count; i++))
      do
          echo $rps_flow_cnt_value > /sys/class/net/$em/queues/rx-$i/rps_flow_cnt
      done
 
      flag=0
      while [ -f /sys/class/net/$em/queues/rx-$flag/rps_cpus ]
      do
          echo `cat  /sys/class/net/$em/queues/rx-$flag/rps_cpus | sed 's/0/f/g' ` >  /sys/class/net/$em/queues/rx-$flag/rps_cpus
          flag=$(($flag+1))
      done
  done
  echo 32768 > /proc/sys/net/core/rps_sock_flow_entries
  sysctl -p
}
 
stop_rps() {
  net_interface=`ip link show | grep "state" | awk '{print $2}' | grep 'flannel' | tr ":\n" " "`
 
  for em in ${net_interface[@]}
  do
      rq_count=`ls /sys/class/net/$em/queues/rx-* -d | wc -l`
 
      for ((i=0; i< $rq_count; i++))
      do
          echo 0 > /sys/class/net/$em/queues/rx-$i/rps_flow_cnt
      done
 
      flag=0
      while [ -f /sys/class/net/$em/queues/rx-$flag/rps_cpus ]
      do
          echo `cat  /sys/class/net/$em/queues/rx-$flag/rps_cpus | sed 's/f/0/g' ` >  /sys/class/net/$em/queues/rx-$flag/rps_cpus
          flag=$(($flag+1))
      done
  done
  echo 0 > /proc/sys/net/core/rps_sock_flow_entries
  sysctl -p
}
 
 
check_rps() {
  net_interface=`ip link show | grep "state" | awk '{print $2}' | grep 'flannel' | tr ":\n" " "`
  for n in $net_interface
  do
      rx_queues=`ls /sys/class/net/$n/queues/ | grep "rx-[0-9]"`
      for q in $rx_queues
      do
          rps_cpus=`cat /sys/class/net/$n/queues/$q/rps_cpus`
          rps_flow_cnt=`cat /sys/class/net/$n/queues/$q/rps_flow_cnt`
 
          echo "[$n]" $q "--> rps_cpus =" $rps_cpus ", rps_flow_cnt =" $rps_flow_cnt
      done
  done
  rps_sock_flow_entries=`cat /proc/sys/net/core/rps_sock_flow_entries`
  echo "rps_sock_flow_entries =" $rps_sock_flow_entries
}
 
case "$1" in
  start)
        echo -n "Starting $DESC: "
        start_rps
        check_rps
        ;;
  stop)
        stop_rps
        check_rps
        ;;
  status)
        check_rps
        ;;
  *)
        echo "Usage: $0 [start|stop|status]"
        ;;
esac
 
exit 0
