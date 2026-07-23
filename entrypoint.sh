#!/bin/bash

# Detener el contenedor si cualquier comando falla.
set -e

# Asegurar que existan los directorios que vsftpd necesita.
mkdir -p /var/run/vsftpd/empty /var/run/vsftpd
touch /etc/vsftpd.chroot_list

# Iniciar cron en background.
cron

# Iniciar SSH.
/usr/sbin/sshd

# Iniciar vsftpd en foreground (para mantener el contenedor vivo).
exec /usr/sbin/vsftpd /etc/vsftpd.conf
