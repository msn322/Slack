# CmTool
This is very rudimentary configuration management tool used to deploy simple PHP application on production servers.
Scripts are documented on every function they perform. 

# Usage 
Usage 
* Transfer the TAR file to the destination server in tmp directory
  root@server: cd /tmp
  root@server: scp –r cmt.tar root@server_name:/tmp/
* Extract the TAR content in /tmp directory
  root@server: tar -xvf cmt.tar 
  root@server: ls 
  bootstrap.sh*  cmt.sh*  index.php  metadata.json  README.md
* Change permissions
  root@server: chmod +x cmt.sh bootstrap.sh 
* Run bootstrap.sh in order to resolve dependency  
  root@server: ./bootstrap.sh 
* Run cmt.sh
  root@server: ./cmt.sh 
* Test Output on Prod 1 & Prod 2
   root@server: curl http://IP address 
					

  
# Configuration:

Assumption:
* Script used for configuring 2 production servers.
* Both production servers are not remotely managed.


Below requirements are fulfilled using the scipt:

=> bootstrap.sh is used to install the dependencies (jq). This command is used to extract values from metadata.properties files(in JSON    format)

=> Main script allows below functions
   * To Install/Uninstall a package, add the package name under install/uninstall field in metadata.json on a separate line.
   * To restart the services when metadata of the index.php changes
   * MD5SUM is checked for index.php before the application is redeployed.
   * All file configuration are also mentioned in metadata.json (owner, group and mode)
   * Edit the metadata.json to add/remove packages and services.
   * Edit the index.php to redeploy the application. This will also trigger the service restart.
   e.g: 
     root@ip-172-31-255-167:~/manpreet# more /var/log/syslog | grep 'cmt.sh'
			Feb 26 11:08:58 ip-172-31-255-167 ./cmt.sh:CM Tool: [INFO] No change in application, returning without deploying
			Feb 26 11:09:16 ip-172-31-255-167 ./cmt.sh:CM Tool: [INFO] Deploying application...
			Feb 26 11:09:16 ip-172-31-255-167 ./cmt.sh:CM Tool: [INFO] Restarting service apache2..
			Feb 26 11:13:33 ip-172-31-255-167 ./cmt.sh:CM Tool: [INFO] No change in application, returning without deploying
			Feb 26 11:24:22 ip-172-31-255-167 ./cmt.sh:CM Tool: [INFO] Deploying application...
			Feb 26 11:24:22 ip-172-31-255-167 ./cmt.sh:CM Tool: [INFO] Restarting service apache2..

   
# Troubleshooting 
* All functions are logged in syslogs.
* Script logging is done using syslog
	<Time stamps>  <hostname>  <script>:<log tag> : [INFO/ERROR] <Message> 
	e.g:
	Feb 24 22:23:34 ip-172-31-255-167 ./cmt.sh:CM Tool: [INFO] Installing apache2..
