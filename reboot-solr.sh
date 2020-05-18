
#if [ -z "$ID" ]; then
#  while [ -z "$ID" ]
#  do
#    echo "Type your user name: "
#    read ID
#  done
#fi
#echo ""
ID=`whoami`

if [ -z "$SOLR_SERVERS" ]; then
  while [ -z "$SOLR_SERVERS" ]
  do
    echo "Type SOLR server IP(s) space separated: "
    read SOLR_SERVERS
  done
fi
echo ""

if [ -z "$ZOO_SERVERS" ]; then
  while [ -z "$ZOO_SERVERS" ]
  do
    echo "Type ZOOKEEPER server IP(s) space separated: "
    read ZOO_SERVERS
  done
fi
echo -e "\n\n"

echo "#### Stopping SOLR service"
for SOLR in ${SOLR_SERVERS}
do
  echo "SOLR server: ${SOLR}"
  ssh -t ${ID}@${SOLR} "sudo -i /opt/lucidworks/fusion/bin/fusion stop" 2>/dev/n                                                                                                                               ull
  sleep 3
done
echo -e "\n\n"

echo "#### Checking zookeeper running mode ####"
for ZOO in ${ZOO_SERVERS}
do
  MODE=`ssh -t ${ID}@${ZOO} "echo srvr | nc localhost 2181 | grep Mode" 2>/dev/n                                                                                                                               ull`

  echo "Zookeeper Server ${ZOO} --> ${MODE}"

  if [ "${MODE}" == "Mode: leader" ]; then
    LEADER=${ZOO}
  else
    SERVERS="${SERVERS} ${ZOO}"
  fi
done
SERVERS="${SERVERS} ${LEADER}"

echo -e "\n\n"
echo "Processing order: ${SERVERS}"

for SERVER in ${SERVERS}
do

  echo "Processing ${SERVER}"
  ssh -t ${ID}@${SERVER} "sudo -i /opt/lucidworks/zookeeper-3.4.6/bin/zkServer.s                                                                                                                               h stop" 2>/dev/null
  sleep 3
  ssh -t ${ID}@${SERVER} "sudo reboot" 2>/dev/null

  SERVICE=0
  while [ "${SERVICE}" == 0 ]
    do
      echo "Rebooting... Please wait!"
      sleep 10
      ssh -t ${ID}@${SERVER} "sudo -i /opt/lucidworks/zookeeper-3.4.6/bin/zkServ                                                                                                                               er.sh start" 2>/dev/null
      MODE=`ssh -t ${ID}@${SERVER} "echo srvr | nc localhost 2181 | grep Mode" 2                                                                                                                               >/dev/null`

     if [[ ${MODE} = Mode* ]]; then
       echo "Zookeeper Server ${SERVER} --> ${MODE}"
       SERVICE=1
     fi
     echo -e "\n\n"
  done

done

echo "#### Checking zookeeper running mode (after reboot) ####"
for ZOO in ${ZOO_SERVERS}
do
  MODE=`ssh -t ${ID}@${ZOO} "echo srvr | nc localhost 2181 | grep Mode" 2>/dev/n                                                                                                                               ull`

  echo "Zookeeper Server ${ZOO} --> ${MODE}"
done

echo "#### Rebooting SOLR servers"
for SOLR in ${SOLR_SERVERS}
do
   echo "SOLR server: ${SOLR}"
  ssh -t ${ID}@${SOLR} "sudo reboot" 2>/dev/null
  sleep 3
  echo -e "\n\n"
  echo "Check status of: http://${SOLR}:8983/solr"
done

echo "Check status of: http://${SOLR}:8983/solr"
