## Prevent printing output to the screen
redirect('/dev/null','false')
 
## Insert your own password here
connect("weblogic",'exaosb#2016' , 't3://10.53.130.77:8005')
 
domainRuntime()
servers = ls('/ServerRuntimes','true','c')
resultstuck=dict()
resulthogging=dict()
resultexth=dict()
resultpend=dict()
resultql=dict()
for server in servers:
    cd('/ServerRuntimes/' + server + '/ThreadPoolRuntime/ThreadPoolRuntime')
    resultstuck[server] = get('StuckThreadCount')
    resulthogging[server] = get('HoggingThreadCount')
    resulthogging[server] = get('HoggingThreadCount')
    resultexth[server] = get('ExecuteThreadTotalCount')
    resultpend[server] = get('PendingUserRequestCount')
    resultql[server] = get('QueueLength')
 
## Reenable printing output
redirect('/dev/null','true')
for key in resultstuck:
        print(key + " has "  + str(resultstuck[key]) + " stuck threads.")
for key in resulthogging:
        print(key + " has "  + str(resulthogging[key]) + " hogging threads.")
for key in resultexth:
        print(key + " has "  + str(resultexth[key]) + " active threads.")
for key in resultpend:
        print(key + " has "  + str(resultpend[key]) + " pending requests. ")
for key in resultql:
        print(key + " has "  + str(resultql[key]) + "	queue length. ")
