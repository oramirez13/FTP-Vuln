#!/bin/bash

# Asegurar que existan los directorios que vsftpd necesita.
mkdir -p /var/run/vsftpd/empty /var/run/vsftpd
touch /etc/vsftpd.chroot_list

# Iniciar cron en background (puede fallar sin systemd, no es critico).
cron || true

# Iniciar SSH (puede fallar si faltan directorios, no es critico).
/usr/sbin/sshd || true

# Iniciar vsftpd en foreground (para mantener el contenedor vivo).
exec /usr/sbin/vsftpd /etc/vsftpd.conf
