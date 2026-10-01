# Respuestas del Laboratorio 3

## 8.1.1. Docker y contenedores
1. **Imagen vs Contenedor**: La imagen es una plantilla estática de solo lectura (como el archivo descargado en G2). El contenedor es una instancia viva y en ejecución creada a partir de esa imagen (lo que arrancamos en G4).
2. **Volúmenes (G5 vs G6)**: En G5 el archivo se guardó en la capa efímera del contenedor, por lo que se perdió al borrarlo. En G6 se usó un volumen persistente (`-v`), lo que guardó el archivo de forma permanente fuera del ciclo de vida del contenedor.
3. **docker ps**: `docker ps` muestra solo los contenedores en ejecución. `docker ps -a` muestra todos (incluidos los detenidos). `STATUS = Exited (0)` significa que el proceso del contenedor terminó correctamente de forma natural y sin errores.
4. **Puertos**: En `-p 8181:8181`, el de la izquierda es el puerto de tu equipo (host) y el de la derecha el del contenedor. En `-p 80:8080`, entrarías por el puerto 80 (HTTP estándar) de tu equipo y el tráfico iría al 8080 del contenedor.
5. **Ciclo de vida**: El contenedor de Oracle mantiene en ejecución el proceso `listener` y el motor de la base de datos de forma continua. `hello-world` solo ejecuta un script que imprime un mensaje y finaliza, apagando el contenedor consigo.
6. **Digest**: Es un identificador único (hash) inmutable. La etiqueta `:latest` puede apuntar a versiones diferentes si Oracle la actualiza; el digest garantiza que estamos usando exactamente la misma versión auditada siempre.
7. **Borrar datos**: Para borrar los datos reales hay que destruir el volumen con `docker volume rm oralab-26ai-data`. `docker rm` solo borra el contenedor, dejando los datos intactos en el volumen.

## 8.1.2. Git, organización y evidencia
8. **GitFlow**: Se usa Issue, Branch y Pull Request para aplicar un flujo de trabajo profesional, permitiendo trazabilidad, versionado y revisión de código antes de alterar la rama principal (`main`).
9. **Source**: `source` ejecuta el script en la sesión actual de la terminal, por lo que las variables exportadas se mantienen disponibles. `bash` abre una subshell, y las variables se pierden al finalizar el script.
10. **Nomenclatura**: `20260915T091230Z` es el timestamp en formato ISO 8601 UTC. `02-docker` indica el orden y tema. `.script.log` indica que es la evidencia generada por el comando `script` de Linux.
11. **.gitattributes**: Fuerza el uso de finales de línea de Linux (`LF`) en los scripts, evitando que el entorno de Windows los convierta a `CRLF` (lo que rompería la ejecución en bash).
12. **Merge commit**: Preserva todo el historial detallado de commits paso a paso (evidencias del proceso). Un squash aplastaría todo en un solo commit, perdiendo la granularidad del trabajo realizado.

## 8.1.3. Seguridad
13. **Capas de seguridad**: Consisten en usar `.env.example` (plantilla), archivo `.env` local, exclusión en `.gitignore`, y permisos restrictivos. Si fallas en la primera capa (no ignorarlo), subirás tu clave real a GitHub por error.
14. **Comandos**: Si se pasa en el comando `docker run`, la contraseña queda registrada en texto plano en el historial de Bash (`.bash_history`) y expuesta temporalmente en la lista de procesos (`ps`).
15. **Claves filtradas**: No basta con borrarla, ya que el historial de Git la mantendrá visible en versiones pasadas. Debes cambiar inmediatamente la contraseña en el servicio afectado y luego purgar el historial o invalidarla.

## 8.1.4. Oracle y herramientas
16. **SPOOL en contenedor**: Es complicado extraer el archivo generado desde el sistema de archivos del contenedor hacia nuestro host. Es mejor usar SQLcl localmente para que el log se escriba directo en nuestra carpeta `docs`.
17. **WHENEVER SQLERROR**: Ordena detener la ejecución y salir devolviendo un código de error al sistema operativo si falla alguna instrucción. Sin esto, el script seguiría ejecutando comandos a ciegas y simulando un falso éxito.
18. **Migraciones**: Son scripts que representan cambios incrementales en la base de datos. No se editan para mantener la consistencia entre entornos; si hay un error, se crea una nueva migración (ej. V002) para corregirlo.
19. **FREEPDB1**: Es la Pluggable Database, donde residen los esquemas de usuario y datos. `FREE` es la Container Database (CDB), reservada para administración del sistema.
20. **SQLcl vs SQL*Plus**: SQLcl es moderno (basado en Java) con formatos ANSI y autocompletado. Un DBA debe dominar SQL*Plus porque es la herramienta nativa que siempre está disponible en cualquier instalación de Oracle.

## 8.1.5. Entorno de trabajo
21. **Ubuntu WSL 2**: Proporciona un kernel de Linux real. Elimina los problemas de rutas mixtas (`C:\` vs `/`) y soluciona fallos con terminales pseudo-TTY y permisos que Git Bash suele arrastrar.
22. **Sistema de archivos**: Clonamos en `~` porque es la partición nativa `ext4` de Linux, siendo muchísimo más rápida. Trabajar en `/mnt/c/` cruza el límite de sistemas de archivos, causando pérdida de rendimiento y conflictos de permisos NTFS. Se recomienda bash porque es el estándar por defecto en la mayoría de servidores frente a zsh.
