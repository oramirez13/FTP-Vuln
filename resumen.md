# Resumen - FTP-Vuln

## Definición

Máquina vulnerable tipo CTF de nivel principiante, diseñada para practicar ciberseguridad ofensiva. El objetivo es comprometer completamente un sistema Ubuntu Server partiendo de un acceso inicial hasta obtener privilegios de root (boot-to-root).

## Stack tecnológico

- **Sistema base**: Ubuntu Server 20.04/22.04
- **Servicios expuestos**: vsftpd 3.0.3 (FTP), OpenSSH (SSH)
- **Despliegue**: Docker (recomendado) o VM via setup.sh
- **Puertos**: 21 (FTP), 22 (SSH), 30000-30010 (FTP pasivo)

## Vectores de vulnerabilidad

1. **FTP con acceso anónimo habilitado** - Permite conexión sin credenciales
2. **Credenciales debiles** - Usuario `orami` con contraseña `123456`
3. **SSH con autenticación por contraseña** - Permite acceso remoto
4. **Cronjob con script de permisos 777** - Se ejecuta como root cada minuto y cualquier usuario puede modificarlo

## Ruta de explotacion

| Paso | Accion                  | Resultado                                       |
| ---- | ----------------------- | ----------------------------------------------- |
| 1    | Enumeración con nmap    | Descubrimiento de puertos 21 y 22               |
| 2    | Acceso FTP anónimo      | Descarga de archivo con credenciales            |
| 3    | Acceso SSH              | Shell como usuario orami                        |
| 4    | Enumeración de cronjobs | Identificación de backup.sh ejecutado como root |
| 5    | Modificación del script | Inyección de payload malicioso                  |
| 6    | Ejecución del cronjob   | Obtención de shell como root                    |
| 7    | Lectura de flags        | user.txt y root.txt                             |

## Flags

- `/home/orami/user.txt` - Flag de usuario
- `/root/root.txt` - Flag de root

## Archivos del proyecto

| Archivo              | Descripción                          |
| -------------------- | ------------------------------------ |
| `Dockerfile`         | Configuración del contenedor         |
| `setup.sh`           | Script de configuración para VM      |
| `config/vsftpd.conf` | Configuración FTP vulnerable         |
| `README.md`          | Documentación completa en inglés     |
| `procedimiento.md`   | Guía detallada en español            |
| `step-by-step`       | Comandos rápidos de referencia       |
| `writeup.txt`        | Walkthrough para subir a plataformas |

## Dependencias para el atacante

- nmap, ftp, ssh (o alternativas: curl, netcat)
- Docker Engine 20+ (para despliegue rapido)

## Notas de seguridad

- No requiere exploits externos ni Metasploit
- Vulnerabilidad basada en malas configuraciones de permisos
- Simula un escenario real de escalada de privilegios
