Error 1:

Error "No space left on device" occurred when attempting to transfer the config tool to the remote server.

Commands ran:
df -kh to check the Filesystem & du -sh to check the most sized file.
Root file system was 100% full. 

Troubleshooting:
Tried to zip few logs in /var/ directory to make some space in read only filesystem. 
Eventually found out through some google search and difference in df -kh and du -sh output that there could be some file which is deleted but still hold by some process.

Solution:
File found: lsof | grep "deleted" & then performed kill on the process to see the file system back to normal.
root@ip-172-31-255-64:/etc# lsof | grep "deleted"
named      1488           root    3w      REG              202,1 7436820480      26448 /tmp/tmp.kVKxGgJgTy (deleted)

root@ip-172-31-255-64:/etc# lsof | grep "deleted"
named      1488           root    3w      REG              202,1 7436820480      26448 /tmp/tmp.kVKxGgJgTy (deleted)
root@ip-172-31-255-64:/etc#
root@ip-172-31-255-64:/etc# kill -9 1488
root@ip-172-31-255-64:/etc#
root@ip-172-31-255-64:/etc# lsof | grep "deleted"
root@ip-172-31-255-64:/etc#
root@ip-172-31-255-64:/etc# df -kh .
Filesystem      Size  Used Avail Use% Mounted on
/dev/xvda1      7.8G  817M  6.6G  11% /


   
-------------------------------------------------------------------------------
Error 2:

Multiple errors when running sudo apt-get update  

Missing host entry in /etc/hosts file and wrong DNS entry(127.0.0.1) in /etc/resolv.conf 
  
Troubleshooting:
  Took the host info from /etc/hostname file along with IP address. 

Solution:
  Added hostname (ip-172-31-255-64) to `/etc/hosts`
	root@ip-172-31-255-64:~# more /etc/hosts
	127.0.0.1 localhost
	# The following lines are desirable for IPv6 capable hosts
	3.91.192.6 ip-172-31-255-64

  Added 8.8.8.8 in /etc/resolv.conf
  
	more /etc/resolv.conf
	nameserver 8.8.8.8
	root@ip-172-31-255-64:~#


----------------------------------------------------------------------------------------------------------------
Error 3:

Issue when starting the Apache instance

Error message:

 * Starting web server apache2                                                                                                                                                                directive globally to suppress this message
(98)Address already in use: AH00072: make_sock: could not bind to address [::]:80
(98)Address already in use: AH00072: make_sock: could not bind to address 0.0.0.0:80
no listening sockets available, shutting down
AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 3.91.192.6. Set the 'ServerName'
AH00015: Unable to open logs
Action 'start' failed.
The Apache error log may have more information.

Solution:
	• Apache instance use apache2.conf to start the instance. 
	• Based on online search on  AH00558: apache2 error. Added ServerName entry in apache2.conf 
		root@ip-172-31-255-64:~# date
		Tue Feb 26 10:19:25 UTC 2019
		root@ip-172-31-255-64:~# more /etc/apache2/apache2.conf | grep -i ServerName
		ServerName ip-172-31-255-64
		
	• For the port error (could not bind to address[::] 80) [ AH00072: make_sock]
		○ Found port 80 already used by another process 
     
		root@ip-172-31-255-64:/etc/apache2# netstat -plnt
		Active Internet connections (only servers)
		Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
		tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      1484/nc
		tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      14625/sshd
		tcp6       0      0 :::22                   :::*                    LISTEN      14625/sshd
		○ Kill the process 1484 (kill -9 1484) & Port 80 was available to use.
		root@ip-172-31-255-64:/etc/apache2# netstat -plnt
		Active Internet connections (only servers)
		Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
		tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      14625/sshd
		tcp6       0      0 :::22                   :::*                    LISTEN      14625/sshd
		

Still had same error:
Action 'start' failed.
The Apache error log may have more information.


-----------------------------------------------------------------------------
Error 4:
Curl command still failed to run.

Troubleshooting:
Ran curl command and seems packets were not reaching.
Did some google search & checked the filtered status on port 80 using nmap command.
After flushing the iptables using 'iptables -F'. I did some study on this incase there was more rules & impact on this command. 
Although the curl started to work fine. 

Solution:
	root@ip-172-31-255-64:~# iptables --list
	Chain INPUT (policy ACCEPT)
	target     prot opt source               destination
	
	Chain FORWARD (policy ACCEPT)
	target     prot opt source               destination
	
	Chain OUTPUT (policy ACCEPT)
	target     prot opt source               destination
	root@ip-172-31-255-64:~#
	root@ip-172-31-255-64:~#
	root@ip-172-31-255-64:~# nmap -sV 80
	
	Starting Nmap 6.40 ( http://nmap.org ) at 2019-02-26 10:36 UTC
	setup_target: failed to determine route to 80 (0.0.0.80)
	WARNING: No targets were specified, so 0 hosts scanned.
	Nmap done: 0 IP addresses (0 hosts up) scanned in 0.05 seconds
	
	


