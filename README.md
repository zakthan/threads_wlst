This scipt is reading the values of Total Sockets Opened from a weblogic domain using wlst commands.
It is a bash script that is calling a python script to connect to weblogic.
According to the values of Total Sockets Opened of managed weblogic servers with state RUNNING it takes lsof and thread dumps and it also alerts with an email if threshold is exceeded.
It runs from one server and it uses ssh keys to connect to the hosts of the domain passwordless.
It stores output under $SCRIPT_HOME/lsof_dumps
