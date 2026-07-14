FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Para que systemd funcione dentro del contenedor
ENV container=docker

# Instalar vsftpd, openssh-server, cron y dependencias
RUN apt update && apt install -y \
    vsftpd \
    openssh-server \
    cron \
    net-tools \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Crear usuario orami
RUN useradd -m -s /bin/bash oramiuser && echo "oramiuser:123456" | chpasswd

# Flags
RUN echo "technova{user_flag_here}" > /home/oramiuser/user.txt && \
    chmod 600 /home/oramiuser/user.txt && \
    chown oramiuser:oramiuser /home/oramiuser/user.txt && \
    echo "technova{root_flag_here}" > /root/root.txt && \
    chmod 600 /root/root.txt

# Configurar vsftpd
COPY config/vsftpd.conf /etc/vsftpd.conf
RUN mkdir -p /var/run/vsftpd/empty && \
    mkdir -p /var/run/vsftpd && \
    touch /etc/vsftpd.chroot_list

# Configurar SSH
RUN mkdir /var/run/sshd && \
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# Directorio FTP anonimo
RUN mkdir -p /srv/ftp/files && \
    echo "credentials: oramiuser:123456" > /srv/ftp/files/leeme.txt && \
    chmod 755 /srv/ftp && \
    chmod 755 /srv/ftp/files && \
    chmod 644 /srv/ftp/files/leeme.txt

# Cronjob vulnerable
RUN echo "* * * * * root /usr/local/bin/backup.sh" > /etc/cron.d/rootjob && \
    chmod 644 /etc/cron.d/rootjob && \
    echo '#!/bin/bash' > /usr/local/bin/backup.sh && \
    echo 'cp /bin/bash /tmp/rootbash && chmod +s /tmp/rootbash' >> /usr/local/bin/backup.sh && \
    chmod 777 /usr/local/bin/backup.sh

# Banner
RUN echo "+---------------------------------------------+" > /etc/motd && \
    echo "|       FTP-Vuln - Boot to Root Challenge      |" >> /etc/motd && \
    echo "|       Dificultad: Facil                      |" >> /etc/motd && \
    echo "|       Objetivo: Encontrar user.txt y root.txt|" >> /etc/motd && \
    echo "+---------------------------------------------+" >> /etc/motd

# Copiar script de entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 21 22 30000-30010

CMD ["/entrypoint.sh"]
