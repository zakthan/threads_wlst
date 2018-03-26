import os
import sys
scripthome=os.environ["SCRIPT_HOME"]
sys.path.append(scripthome)

print scripthome
print scripthome
print scripthome


## store servernames and manages server names within servers.txt file
orig_stdout = sys.stdout
##file=scripthome."servers.txt"
file=os.path.join(scripthome, 'servers.txt')
print file
print file
print file
f = open(file, 'a+')
sys.stdout = f
print "test test test"
sys.stdout = orig_stdout
f.close()

