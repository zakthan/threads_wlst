#############################################################
###Author: Thanassis Zakopoulos
#############################################################
#!/bin/bash

SCRIPT_HOME=/opt/orasync/scripts/threads
##load enviromental variables
source "$SCRIPT_HOME"/envs
##load functions for this script
source "$SCRIPT_HOME"/functions
##log file to use for result parsing
LOG="$SCRIPT_HOME"/threads.log
LOG_PARSED="$SCRIPT_HOME"/threads.log.parsed

##empty files in order not to parse older outputs
/bin/cat /dev/null > $LOG
/bin/cat /dev/null > $LOG_PARSED

##get results using wlst and python script
. $WEBLOGIC_HOME/server/bin/setWLSEnv.sh 2>/dev/null
$JAVA_HOME/bin/java weblogic.WLST "$SCRIPT_HOME"/OpenSocketsCurrentCount.py > $LOG

##grep only RUNNING instances and not the admin server
grep "RUNNING" $LOG|egrep -v -i admin > $LOG_PARSED

##debug##cat $LOG_PARSED
HOSTS=($(cat $LOG_PARSED |awk '{print $2}'))
NAME=($(cat $LOG_PARSED |awk '{print $3}'))
NUM_OF_CURRENT_OPEN_SOCKETS=($(cat $LOG_PARSED |awk '{print $4}'))
NUM_OF_RUN_INSTANCES=$(wc -l $LOG_PARSED|awk '{print $1}')
START_NUM=0
NUM_OF_AFFECTED_SERVERS=0
for i in $(eval echo "{$START_NUM..$((NUM_OF_RUN_INSTANCES-1))}") 
do
	##send Total_Sockets_Opened value of each weblogic server to zabbix
	/usr/bin/zabbix_sender -z $ZABBIX -s "${HOSTS[$i]}".ote.gr -k Total_Sockets_Opened -o "${NUM_OF_CURRENT_OPEN_SOCKETS[$i]}"
	##make sure that empty entries are gone file_$i keeps an output of ps weblogic for each server
	/bin/cat /dev/null > "$SCRIPT_HOME"/tmp/file_$i
	##if #no of current open sockets for each weblogic is more than $OPEN_SOCKETS_THRESHOLD keep lsof and thread dump at $DUMPS
	if [ "${NUM_OF_CURRENT_OPEN_SOCKETS[$i]}" -gt "$OPEN_SOCKETS_THRESHOLD" ]
	then
		##if $NUM_OF_AFFECTED_SERVERS>0 later on send an email alert
		NUM_OF_AFFECTED_SERVERS=$(expr $NUM_OF_AFFECTED_SERVERS + 1)
		ssh $CURRENT_USER@${HOSTS[$i]} "ps -ef|grep weblogic.Server|grep ${NAME[$i]}|grep -v grep" > "$SCRIPT_HOME"/tmp/file_$i
		REMOTE_WEBLOGIC_PID=$(awk '{print $2}' "$SCRIPT_HOME"/tmp/file_$i)
		echo $REMOTE_USER $REMOTE_WEBLOGIC_PID
		##take an lsof of the weblogic server
		ssh $CURRENT_USER@${HOSTS[$i]} "/usr/sbin/lsof -p $REMOTE_WEBLOGIC_PID" > $DUMPS/lsof_"${HOSTS[$i]}"_"${NAME[$i]}"_"$REMOTE_WEBLOGIC_PID"_"$DATE"
		SSH_EXIT_CODE="$?"
		##if ssh was not successful send an email alert
		if [ "$SSH_EXIT_CODE" != "0" ]
		then
			mail_function "$MAIL_LIST" "Check ssh connectivity between $HOST and ${HOSTS[$i]}"
		fi
		##take a thread dump of the weblogic server. Jstack is for JDK and jcmd for Jrockit
		REMOTE_JAVA_BIN=$(awk '{print $8}' "$SCRIPT_HOME"/tmp/file_$i|sed -e "s/java//")
		ssh $CURRENT_USER@${HOSTS[$i]} "$REMOTE_JAVA_BIN/jcmd $REMOTE_WEBLOGIC_PID Thread.print" > $DUMPS/thread_dump_"${HOSTS[$i]}"_"${NAME[$i]}"_"$REMOTE_WEBLOGIC_PID"_"$DATE"
		SSH_EXIT_CODE="$?"
		##if ssh was not successful send an email alert
		if [ "$SSH_EXIT_CODE" != "0" ]
		then
			mail_function "$MAIL_LIST" "Check ssh connectivity between $HOST and ${HOSTS[$i]}"
		fi
	fi
##send an email alert with the weblogic servers that have more than $OPEN_SOCKETS_THRESHOLD open sockets
	
done

if [ "$NUM_OF_AFFECTED_SERVERS" -gt 0 ]
then 
	sed -i "s/RUNNING/$NL RUNNING/g" "$LOG_PARSED"
	mail_function "$MAIL_LIST" "Check weblogic servers that have more than $OPEN_SOCKETS_THRESHOLD open sockets" "$LOG_PARSED"
fi
