# Resumen Ejecutivo Tecnico - FTP-Vuln

## Definicion
Maquina vulnerable tipo CTF (Capture The Flag) de nivel principiante, disenada para practicar ciberseguridad ofensiva. El objetivo es comprometer completamente un sistema Ubuntu Server partiendo de un acceso inicial hasta obtener privilegios de root (boot-to-root).

## Stack tecnologico
- **Sistema base**: Ubuntu Server 20.04/22.04
- **Servicios expuestos**: vsftpd 3.0.3 (FTP), OpenSSH (SSH)
- **Despliegue**: Docker (recomendado) o VM via setup.sh
- **Puertos**: 21 (FTP), 22 (SSH), 30000-30010 (FTP pasivo)

## Vectores de vulnerabilidad
1. **FTP con acceso anonimo habilitado** - Permite conexion sin credenciales
2. **Credenciales debiles** - Usuario `orami` con contraseña `123456`
3. **SSH con autenticacion por contraseña** - Permite acceso remoto
4. **Cronjob con script de permisos 777** - Se ejecuta como root cada minuto y cualquier usuario puede modificarlo

## Ruta de explotacion

| Paso | Accion | Resultado |
|------|--------|-----------|
| 1 | Enumeracion con nmap | Descubrimiento de puertos 21 y 22 |
| 2 | Acceso FTP anonimo | Descarga de archivo con credenciales |
| 3 | Acceso SSH | Shell como usuario orami |
| 4 | Enumeracion de cronjobs | Identificacion de backup.sh ejecutado como root |
| 5 | Modificacion del script | Inyeccion de payload malicioso |
| 6 | Ejecucion del cronjob | Obtencion de shell como root |
| 7 | Lectura de flags | user.txt y root.txt |

## Flags
- `/home/orami/user.txt` - Flag de usuario
- `/root/root.txt` - Flag de root

## Archivos del proyecto

| Archivo | Descripcion |
|---------|-------------|
| `Dockerfile` | Configuracion del contenedor |
| `setup.sh` | Script de configuracion para VM |
| `config/vsftpd.conf` | Configuracion FTP vulnerable |
| `README.md` | Documentacion completa en ingles |
| `procedimiento.md` | Guia detallada en espanol |
| `step-by-step` | Comandos rapidos de referencia |
| `writeup.txt` | Walkthrough para subir a plataformas |

## Dependencias para atacante
- nmap, ftp, ssh (o alternativas: curl, netcat)
- Docker Engine 20+ (para despliegue rapido)

## Notas de seguridad
- No requiere exploits externos ni Metasploit
- Vulnerabilidad basada en malas configuraciones de permisos
- Simula un escenario real de escalada de privilegios
