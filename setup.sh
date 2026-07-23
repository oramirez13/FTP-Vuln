#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Ejecutar como root: sudo ./setup.sh"
    exit 1
fi

echo "========================================"
echo " Configurando maquina vulnerable FTP-Vuln"
echo "========================================"

echo "[1/8] Actualizando sistema e instalando paquetes..."
apt update && apt upgrade -y
apt install -y vsftpd openssh-server net-tools

echo "[2/8] Creando usuario orami..."
adduser oramiuser --gecos "" --disabled-password
echo "oramiuser:123456" | chpasswd

echo "[3/8] Creando flags..."
echo "technova{user_flag_here}" > /home/oramiuser/user.txt
chmod 600 /home/oramiuser/user.txt
chown oramiuser:oramiuser /home/oramiuser/user.txt

echo "technova{root_flag_here}" > /root/root.txt
chmod 600 /root/root.txt

echo "[4/8] Configurando vsftpd..."
cat > /etc/vsftpd.conf << 'EOF'
listen=YES
listen_ipv6=NO
anonymous_enable=YES
local_enable=YES
write_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_root=/srv/ftp
allow_writeable_chroot=YES
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
seccomp_sandbox=NO
EOF

mkdir -p /srv/ftp/files
echo "credentials: oramiuser:123456" > /srv/ftp/files/leeme.txt

chmod 755 /srv/ftp
chmod 777 /srv/ftp/files

systemctl enable vsftpd
systemctl restart vsftpd

echo "[5/8] Configurando SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

systemctl enable ssh
systemctl restart ssh

echo "[6/8] Creando vector de escalada (cronjob)..."
cat > /etc/cron.d/rootjob << 'EOF'
* * * * * root /usr/local/bin/backup.sh
EOF
chmod 644 /etc/cron.d/rootjob

cat > /usr/local/bin/backup.sh << 'EOF'
#!/bin/bash
tar czf /tmp/backup.tar.gz /home/oramiuser 2>/dev/null
EOF
chmod 777 /usr/local/bin/backup.sh

echo "[7/8] Agregando banner del reto..."
cat > /etc/motd << 'EOF'
+---------------------------------------------+
|       FTP-Vuln - Boot to Root Challenge      |
|       Dificultad: Facil                      |
|       Objetivo: Encontrar user.txt y root.txt|
+---------------------------------------------+

EOF

cat > /etc/issue.net << 'EOF'
+-----------------------------------------------+
|       FTP-Vuln - Boot to Root Challenge        |
|       Dificultad: Facil                        |
+-----------------------------------------------+
EOF

echo "[8/8] Limpiando logs y rastros..."
rm -rf /var/log/*.log /var/log/*.gz /var/log/apt/*
history -c 2>/dev/null
unset HISTFILE
> /root/.bash_history 2>/dev/null
> /home/oramiuser/.bash_history 2>/dev/null

echo ""
echo "========================================"
echo " Configuracion completada!"
echo "========================================"
echo "  FTP anonimo: /srv/ftp/files"
echo "  Credenciales: leeme.txt -> orami:123456"
echo "  SSH: orami / 123456"
echo "  user.txt: /home/oramiuser/user.txt"
echo "  root.txt: /root/root.txt"
echo "  Cronjob: /usr/local/bin/backup.sh (777)"
echo "  Escalada: modificar backup.sh, esperar 1 min, /tmp/rootbash -p"
