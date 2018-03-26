#############################################################
###Author: Thanassis Zakopoulos
#############################################################
#!/bin/bash

export SCRIPT_HOME=/opt/orasync/scripts/threads
##load enviromental variables
source "$SCRIPT_HOME"/envs
##load functions for this script
source "$SCRIPT_HOME"/functions
##log file to use for result parsing
LOG="$SCRIPT_HOME"/threads.log
LOG_PARSED="$SCRIPT_HOME"/threads.log.parsed
SERVERS_FILE="$SCRIPT_HOME"/servers.txt
SERVERS_FILE_PARSED="$SCRIPT_HOME"/servers_parsed.txt
DOMAIN=ote.gr

##empty files in order not to parse older outputs
/bin/cat /dev/null > $LOG
/bin/cat /dev/null > $LOG_PARSED
/bin/cat /dev/null > $SERVERS_FILE

##get results using wlst and python script
. $WEBLOGIC_HOME/server/bin/setWLSEnv.sh 2>/dev/null
$JAVA_HOME/bin/java weblogic.WLST "$SCRIPT_HOME"/threads.py > $LOG

##remove admin from server list
egrep -v admin $SERVERS_FILE > $SERVERS_FILE_PARSED
grep -iv admin $LOG > $LOG_PARSED 


while IFS='' read -r line || [[ -n "$line" ]]; do
    HOST=$(echo $line|awk '{print $1}')
    MANAGED_SERVER=$(echo $line|awk '{print $2}')
    STUCK_THREADS=$(grep $MANAGED_SERVER $LOG_PARSED|grep "stuck threads"|awk '{print $3}')
    HOGGING_THREADS=$(grep $MANAGED_SERVER $LOG_PARSED|grep "hogging threads"|awk '{print $3}')
    TOTAL_THREADS=$(grep $MANAGED_SERVER $LOG_PARSED|grep "total threads"|awk '{print $3}')
    STANDBY_THREADS=$(grep $MANAGED_SERVER $LOG_PARSED|grep "standby threads"|awk '{print $3}')
    ACTIVE_THREADS=`expr $TOTAL_THREADS - $STANDBY_THREADS`
    QUEUE_LENGTH=$(grep $MANAGED_SERVER $LOG_PARSED|grep "queue length"|awk '{print $3}')
    PENDING_REQUESTS=$(grep $MANAGED_SERVER $LOG_PARSED|grep "pending requests"|awk '{print $3}')
    ##send values of each weblogic server to zabbix
        /usr/bin/zabbix_sender -z $ZABBIX -s $HOST.$DOMAIN -k stuck_threads -o $STUCK_THREADS
        /usr/bin/zabbix_sender -z $ZABBIX -s $HOST.$DOMAIN -k 	hogging_threads -o $HOGGING_THREADS
        /usr/bin/zabbix_sender -z $ZABBIX -s $HOST.$DOMAIN -k 	active_threads -o $ACTIVE_THREADS
        /usr/bin/zabbix_sender -z $ZABBIX -s $HOST.$DOMAIN -k 	threads_queue_length -o $QUEUE_LENGTH
        /usr/bin/zabbix_sender -z $ZABBIX -s $HOST.$DOMAIN -k 	threads_pending_requests -o $PENDING_REQUESTS
done < "$SERVERS_FILE_PARSED"
