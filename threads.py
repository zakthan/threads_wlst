import os
import sys
scripthome=os.environ["SCRIPT_HOME"]
sys.path.append(scripthome)



## Prevent printing output to the screen
redirect('/dev/null','false')

##connect to admin
#connect(USER,PASSWORD,T3_URL)

connect(url='t3://10.53.130.77:8005',userConfigFile='/opt/orasync/exa_osb_sync_user_projects/domains/exa_sync_osb_domain/ConfigFile',userKeyFile='/opt/orasync/exa_osb_sync_user_projects/domains/exa_sync_osb_domain/KeyFile')

 
 
domainRuntime()
servers = ls('/ServerRuntimes','true','c')
resultstuck=dict()
resulthogging=dict()
resultexth=dict()
resultpend=dict()
resultql=dict()
resultsth=dict()
for server in servers:
    cd('/ServerRuntimes/' + server + '/ThreadPoolRuntime/ThreadPoolRuntime')
    resultstuck[server] = get('StuckThreadCount')
    resulthogging[server] = get('HoggingThreadCount')
    resulthogging[server] = get('HoggingThreadCount')
    resultexth[server] = get('ExecuteThreadTotalCount')
    resultpend[server] = get('PendingUserRequestCount')
    resultsth[server] = get('StandbyThreadCount')
    resultql[server] = get('QueueLength')
 
## Reenable printing output
redirect('/dev/null','true')
for key in resultstuck:
        print(key + " has "  + str(resultstuck[key]) + " stuck threads.")
for key in resulthogging:
        print(key + " has "  + str(resulthogging[key]) + " hogging threads.")
for key in resultexth:
        print(key + " has "  + str(resultexth[key]) + " total threads.")
for key in resultpend:
        print(key + " has "  + str(resultpend[key]) + " pending requests. ")
for key in resultql:
        print(key + " has "  + str(resultql[key]) + "   queue length. ")
for key in resultsth:
        print(key + " has "  + str(resultsth[key]) + "   standby threads. ")

##get the names of the weblogic servers
domainConfig()
serverList=cmo.getServers();

domainRuntime()
cd('/ServerRuntimes/')



## store servernames and manages server names within servers.txt file
for server in serverList:
        name=server.getName()
        cd(name)
        serverHost=cmo.getCurrentMachine();
        serverName=cmo.getName();
        orig_stdout = sys.stdout
	file=os.path.join(scripthome, 'servers.txt')
	f = open(file, 'a+')
	sys.stdout = f
	print "%s %s" %(serverHost,serverName)
	sys.stdout = orig_stdout
	f.close()
        cd('..')

exit()
