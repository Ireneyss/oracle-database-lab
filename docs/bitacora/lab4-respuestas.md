# Lab 4 · Oracle DBA Workflow I — Respuestas

Rutas de evidencia relativas a `docs/bitacora/lab4/evidencia/`. Las horas son UTC (en la terminal local, +2 h).

## Diferencias de mi entorno respecto al enunciado

- **ARCHIVELOG.** Mi base está en `ARCHIVELOG` (evidencia 00, inventario: `log_mode=ARCHIVELOG`; `script/20261022T165926Z_06-arranque-por-etapas.script.log`), no en NOARCHIVELOG. Por eso aparecen 4 procesos `ARCn` (H) y 2 redo archivados (122 MB, J), y el volumen ocupa 4,8 GB en lugar de 3 GB. No hay FRA: `db_recovery_file_dest` está vacío.
- **`$ORACLE_HOME/dbs` es un enlace simbólico** a `/opt/oracle/oradata/dbconfig/FREE/dbs`, dentro del volumen. Por eso la copia de la Parte A no encontró archivos FUERA.
- **Números distintos** a los del enunciado: los datafiles de negocio son los file# 16–20 (no 25…), la fila 101 está en el bloque 783 (no 782) y la tabla `ACA_ESTUDIANTES` es el objeto 73124.

---

## Puntos de control y retos

### Parte A

**Punto de control — archivos FUERA del volumen.**
Salieron **0 archivos FUERA** (evidencia 00, paso 3). Los cinco datafiles de negocio (file# 16–20, evidencia 01) se crearon en `$ORACLE_HOME/dbs` porque V000 usó rutas relativas (`'academia01.dbf'`) y `db_create_file_dest` estaba vacío, así que Oracle tomó `$ORACLE_HOME/dbs` como carpeta base. En esta imagen `$ORACLE_HOME/dbs` es un enlace a `/opt/oracle/oradata/dbconfig/FREE/dbs`, de modo que están dentro del volumen y sobreviven a `docker rm`, pero en una carpeta no estándar que depende de un enlace que una actualización de imagen podría cambiar. La corrección (Parte C) es la misma: llevarlos a `FREE/FREEPDB1/`.

**Reto — informe de diagnóstico.**

| # | Hallazgo | Riesgo |
| --- | --- | --- |
| 1 | Contraseñas de los cinco `admin_*` en V000, en el historial de Git | Alto |
| 2 | `08-aplicar-migraciones.sh` pasa `sys/<contraseña>` en la línea de comandos (visible con `ps`) | Alto |
| 3 | Datafiles de negocio en `dbconfig/FREE/dbs`, carpeta no estándar que depende de un enlace | Medio |
| 4 | ARCHIVELOG sin FRA: los archivados crecen sin destino gestionado ni límite | Medio |
| 5 | Puerto 8181 publicado sin servicio detrás | Bajo |

Orden: primero 1 y 2, porque son credenciales ya expuestas y cada día que pasan es exposición; después 3, que protege los datos ante un cambio de imagen; luego 4, que puede llenar el disco; y al final 5, que solo es superficie de ataque sin servicio.

### Parte B

**Reto — mínimo privilegio.**
Dar el rol DBA a C##OPS_RO tiene al menos dos riesgos concretos: (1) la cuenta podría modificar o borrar cualquier objeto y crear usuarios o conceder privilegios, así que un despiste o un script con error se convierte en incidencia; (2) si su contraseña se filtra (está en `config/.env` y la usa una herramienta), el atacante obtiene control total de la base en lugar de solo lectura. Además, la auditoría pierde sentido: no se distingue quién mira de quién cambia.
Para leer el alert log basta con un único privilegio de objeto: `GRANT SELECT ON sys.v_$diag_alert_ext TO c##ops_ro CONTAINER = ALL;` (es lo que hace `11-ampliar-ops-ro.sql`, `script/20261022T171255Z_11-ampliar-ops-ro.script.log`).

### Parte C

**Reto — que no vuelva a pasar (OMF).**
Comando: `ALTER SYSTEM SET db_create_file_dest = '/opt/oracle/oradata' SCOPE = BOTH;` (`scripts/lab4/03-reto-omf.sql`, `script/20261022T164937Z_03-reto-omf.script.log`).
`SCOPE = BOTH` porque el parámetro es dinámico (se aplica ya) y además debe quedar escrito en el SPFILE para sobrevivir a reinicios; en la Parte F se ve como `ISDEFAULT = FALSE` y en `v$spparameter`.
Efecto: un `CREATE TABLESPACE prueba_omf;` sin cláusula `DATAFILE` crea el archivo él solo dentro del volumen, con nombre gestionado por Oracle, en `/opt/oracle/oradata/FREE/<GUID de FREEPDB1>/datafile/o1_mf_….dbf` (la carpeta `55E54F210F100828E0630B00580ADFD0` que aparece en la evidencia 05; ese GUID también es un servicio del listener). Matiz observado en la Parte I: si se indica la ruta (por ejemplo, `FILE_NAME_CONVERT` al crear `PDB_LAB4`), esa ruta tiene prioridad sobre OMF.

### Parte E

**Punto de control — ORA-01507 y ORA-01219** (`script/20261022T165926Z_06-arranque-por-etapas.script.log`).
- En **NOMOUNT** la instancia ya existe (lee el SPFILE, reserva la SGA de 1 603 398 928 bytes y arranca procesos), por eso `v$parameter` responde. Pero `v$database` necesita el control file, que aún no se ha abierto: `ORA-01507: database not mounted`.
- En **MOUNT** ya se leyeron los control files: `v$database` responde (`MOUNTED`, `ARCHIVELOG`) y `v$datafile` conoce los 16 datafiles. Pero `dba_tables` es una vista del diccionario, que vive en el tablespace SYSTEM, un datafile todavía cerrado: `ORA-01219`. Solo funcionan las vistas fijas (V$/X$), que leen memoria y control file.
- En **OPEN** se abren datafiles y redo, y FREEPDB1 se abre sola por su estado guardado (`dba_pdb_saved_states`).

**Reto — el parte del reinicio** (alert log, `script/20261022T165945Z_06-alert-log.script.log`).
- Parada pedida: **16:59:26** UTC (`Shutting down ORACLE instance (immediate)`).
- Instancia arrancada: 16:59:30; base abierta (`Completed: ALTER DATABASE OPEN`): **16:59:35**. Duración total del reinicio: unos **9 segundos**, de los cuales 5 s entre arrancar la instancia y abrir la base.
- Recuperación de instancia: **no hubo**. La línea `Crash Recovery excluding pdb … cleanly closed` aparece, pero no hay `Beginning crash recovery` ni `Completed crash recovery`; la parada anterior fue `SHUTDOWN IMMEDIATE`.
- Errores:
  - `ORA-00800 [Set Priority Failed] [VKTM]/[LGWR]` → **conocido**: el contenedor no permite subir la prioridad de esos procesos (falta `CAP_SYS_NICE`); no afecta.
  - `ORA-07427/ORA-27300/ORA-27302 spstp: cannot change directory to dbs` → **conocido / histórico**: fechado el 2026-07-05, cuando se construyó la imagen (aún no existía el enlace `dbs`). No se repite en los arranques de hoy.
- Observación: el alert log tiene 255 líneas de julio, **0 de septiembre** y 78 de octubre. El historial del Lab 3 se perdió al recrear el contenedor en la Parte C porque el ADR (`/opt/oracle/diag`) no está en el volumen.

### Parte F

**Reto — petición de cambio: `open_cursors` a 1000 por ORA-01000.**
- **Valor actual y origen:** 300, escrito en el SPFILE (`*.open_cursors=300`, `ISDEFAULT = FALSE`; `spool/20261022T170136Z_07-parametros-lectura.spool.log`). Es dinámico (`IMMEDIATE`) y modificable por PDB.
- **Diagnóstico previo:** ORA-01000 suele indicar cursores que la aplicación no cierra. Antes de cambiar nada, medir los cursores abiertos por sesión (`v$sesstat` con la estadística `opened cursors current`, o `v$open_cursor`) y ver si crecen sin parar (fuga) o se estabilizan cerca del límite (uso legítimo).
- **Propuesta:** si es una fuga, corregir la aplicación y no tocar el parámetro. Si el uso es legítimo, subirlo solo en la PDB afectada: `ALTER SESSION SET CONTAINER = FREEPDB1; ALTER SYSTEM SET open_cursors = 1000 COMMENT = 'CR-xxx: ORA-01000 app' SCOPE = BOTH;`. `SCOPE = BOTH` para que se aplique ya y sobreviva al reinicio.
- **Prueba:** en el entorno de laboratorio primero; comprobar `v$parameter` y `v$spparameter` y repetir la carga que daba ORA-01000.
- **Rollback:** `ALTER SYSTEM SET open_cursors = 300 SCOPE = BOTH;` en la PDB (o `ALTER SYSTEM RESET open_cursors` para heredar el valor del CDB).
- **Evidencia:** valores antes y después de `v$parameter`/`v$spparameter`, copia del PFILE (`CREATE PFILE FROM SPFILE`) antes del cambio y salida de la prueba.

### Parte G

**Punto de control — experimento de caché** (`script/20261022T170310Z_08-experimento-cache.script.log`).
- Ronda 1 (caché fría): 355 lecturas lógicas y 259 físicas. Ronda 2 (caché caliente): 247 lógicas y 0 físicas.
- En mi caso las lógicas **no** son iguales (el enunciado dice que sí). La ronda 1 tiene 108 de más porque es la primera ejecución: incluye el análisis de la sentencia y las consultas recursivas al diccionario, que también cuentan como lecturas de la sesión.
- Las 259 físicas superan los 244 bloques de la tabla: son los 244 de datos, más la cabecera del segmento, más bloques del diccionario que no estaban en caché. Toda lectura física termina además en una lógica (el bloque se trae a la caché y se lee desde ahí).
- `v$bh` muestra 245 bloques en caché: 244 de datos y 1 de cabecera.
- Tasa de acierto: ronda 1, 1 − 259/355 ≈ **27 %**; ronda 2, 1 − 0/247 = **100 %**.

**Punto de control — PGA** (`script/20261022T170310Z_08-parse-y-pga.script.log`).
- Con PGA automática, ordenar 60 000 filas necesitaba 2675 KB (`KB_OPTIMO`): `OPTIMAL`, 0 KB en TEMP, 30 ms.
- Con 64 KB manuales: **6 PASSES**, 3072 KB escritos en TEMP y 330 ms, 11 veces más lento con una tabla pequeña.
- En el histograma de la instancia, las 2 `VARIAS_PASADAS` son las de mi experimento; en producción cualquier valor distinto de 0 sería una alarma. El *cache hit percentage* de la PGA bajó de 100 % a 81,4 % por la misma razón.
- `maximum PGA allocated` (465,4 MB) no llegó a superar `pga_aggregate_target` (512 MB) en mi caso, pero el objetivo no es un límite: el límite es `pga_aggregate_limit` (2 GB); al acercarse, Oracle cortaría sesiones con ORA-04036.

**Reto — literales** (`scripts/lab4/08-reto-literales.sql`, `spool/20261022T170413Z_08-reto-literales.spool.log`).
Una sola `force_matching_signature` (1863221789280198928) acumula **377 cursores con 377 ejecuciones** en `CON_ID 3` (FREEPDB1): un cursor nuevo por cada valor del literal, con un único ejemplo `SELECT /* lab4_literal */ COUNT(*) … WHERE estudiante_id = 1000`. Es la sentencia que la aplicación ejecuta con literales en lugar de variables de enlace.

### Parte H

**Reto — la sesión que más consume** (`scripts/lab4/09-reto-sesion.sql`, `spool/20261022T170924Z_09-reto-sesion.spool.log`).

| Dato | Valor |
| --- | --- |
| SID | 209 (serial# 14830) |
| Usuario / contenedor | SYS, `CON_ID 3` (FREEPDB1) |
| SPID en Linux | 2754 |
| PGA | 3,3 MB usada, 3,7 MB asignada |
| Consulta | `SELECT COUNT(*) FROM admin_academia.aca_matriculas a, admin_academia.aca_matriculas b WHERE a.matricula_id < 10000` |

Consulta usada: `v$session` unida a `v$process` por `paddr = addr` (SPID y PGA) y a `v$sql` por `sql_id` (texto), filtrando `type = 'USER'` y `status = 'ACTIVE'`, ordenada por `pga_used_mem`. Mejora: excluir la propia sesión de búsqueda (aparece la primera, SID 176) con `AND s.sid <> SYS_CONTEXT('USERENV','SID')`. Las filas sin usuario (SID 64 y 223) son los procesos de jobs J000 y J001.

### Parte I

**Punto de control** (`script/20261022T171135Z_10-que-ve-cada-usuario.script.log`).
- **CON_ID 0 en V$LOG:** los 3 grupos de redo tienen CON_ID 0 porque el redo es de toda la CDB, no de una PDB: todas las PDB escriben en el mismo redo.
- **C##LAB4_AUDITOR** ve 87 sesiones con CON_ID 0 y 1 con CON_ID 1, pero ninguna de FREEPDB1, porque es un usuario común sin `CONTAINER_DATA`. Lo cambiaría `ALTER USER c##lab4_auditor SET CONTAINER_DATA = ALL CONTAINER = CURRENT;`.
- **SELECT ANY TABLE:** el privilegio de esquema dejó leer solo `ADMIN_ACADEMIA` (las 20 000 filas), y `ADMIN_CLINICA` siguió devolviendo ORA-00942. `SELECT ANY TABLE` habría abierto las tablas de todos los esquemas de la PDB, incluido `ADMIN_CLINICA`.

**Reto — acceso de una auditora externa** (diseño, no ejecutado).
```sql
-- Local y en FREEPDB1: solo necesita esa PDB (un usuario local no existe en la raíz ni en otras PDB)
ALTER SESSION SET CONTAINER = FREEPDB1;
CREATE USER auditora_clinica IDENTIFIED BY "<contraseña robusta>" PASSWORD EXPIRE;
GRANT CREATE SESSION TO auditora_clinica;
-- Privilegio de esquema: lee todas las tablas de ADMIN_CLINICA y nada más; READ no permite SELECT ... FOR UPDATE
GRANT READ ANY TABLE ON SCHEMA admin_clinica TO auditora_clinica;
-- Último día
REVOKE READ ANY TABLE ON SCHEMA admin_clinica FROM auditora_clinica;
ALTER USER auditora_clinica ACCOUNT LOCK;   -- o DROP USER auditora_clinica; si no se va a reutilizar
```
Justificación con I.2: un usuario local en la PDB no ve nada fuera de ella (LAB4_ANALISTA no pudo saltar a la raíz: ORA-01031); el privilegio de esquema abre un esquema y no los demás (ADMIN_CLINICA cerrado para quien solo tenía ADMIN_ACADEMIA); y leer no es escribir (el UPDATE dio ORA-41900).

### Parte J

**Punto de control** (`spool/20261022T171258Z_11-archivos.spool.log`, `script/20261022T171259Z_11-archivos-so.script.log`).
- **Password file «relacionado»:** no guarda datos de la base, pero sin él nadie puede autenticarse como SYSDBA por red (`remote_login_passwordfile = EXCLUSIVE`; ahora solo contiene a SYS). Es imprescindible, pero no es la base.
- **Enlaces de `$ORACLE_HOME/dbs`:** la carpeta entera es un enlace a `/opt/oracle/oradata/dbconfig/FREE/dbs`, así que el SPFILE y el password file viven en el volumen. Se gana que sobreviven a recrear el contenedor y entran en la copia del volumen.
- **TEMP:** es el único tablespace que no se respalda: guarda datos temporales de sesiones (ordenaciones, tablas temporales) que no hay que recuperar, y Oracle puede recrear sus tempfiles vacíos.

**Reto — plan de copia.**
Copia en frío completa: datafiles 3954 MB + control files 36 MB + redo online 600 MB + SPFILE y password file (unos KB) ≈ **4590 MB** sin comprimir (la copia comprimida de la Parte A ocupó 510 MB). Con RMAN sobrarían: los redo online (600 MB; RMAN copia los archivados), los tempfiles (ya excluidos), los bloques nunca usados de los datafiles (RMAN solo copia bloques usados: los cinco `TBS_*` de 100 MB están casi vacíos) y la copia manual del control file (RMAN usa autobackup).

### Parte K

**Punto de control — volcado del bloque 783** (`config/20261022T171408Z_12-volcado-bloque.trc.txt`).
- `avsp = fseo − fsbo`: 0x427 − 0xc6 = 0x361, en decimal 1063 − 198 = **865 bytes libres**; coincide con `avsp` y con `tosp`.
- Fecha de registro de la fila 101 (columna 6, `78 7e 0a 16 11 33 19 …`): siglo 120 − 100 = 20, año 126 − 100 = 26, mes 10, día 22, hora 17 − 1 = 16, minuto 51 − 1 = 50, segundo 25 − 1 = 24 → **2026-10-22 16:50:24 UTC**, el momento en que apliqué V002. Los 4 bytes restantes son la fracción de segundo.
- **Un UPDATE de la fila 101** necesita una ranura de la ITL para su transacción. Al visitar el bloque, Oracle ve que la transacción de la ranura 0x01 (`Lck 90`) ya está confirmada y hace la limpieza diferida: pone a 0 su `Lck` y los bytes de bloqueo de esas filas. Después la nueva transacción ocupa una ranura (la 0x02, libre, o la 0x01 ya reutilizable) y solo la fila 101 queda bloqueada por ella (`Lck 1`). Se puede comprobar repitiendo el volcado del bloque tras un UPDATE sin confirmar.

**Reto — abrir otro bloque** (`scripts/lab4/12-reto-otro-bloque.sql`, `script/…_12-reto-otro-bloque.script.log` y traza `config/…_12-reto-volcado-bloque.trc.txt`).
Elegí el estudiante **19500** (ROWID `AAAR2kAAAAAAASVABN`): mismo objeto 73124 y archivo 16, **bloque 1173**, fila 77.

| Campo | Bloque 783 (estudiante 101) | Bloque 1173 (estudiante 19500) |
| --- | --- | --- |
| `nrow` | 90 | 85 |
| `fsbo` | 0xc6 (198) | 0xbc (188) |
| `fseo` | 0x427 (1063) | 0x3f6 (1014) |
| `avsp` = `tosp` | 0x361 (865) | 0x33a (826) = 1014 − 188 |
| ITL 0x01 | `--U-`, `Lck 90` | `--U-`, `Lck 85` |
| `tl` de la fila | 78 | 84 |

`fsbo` es 10 bytes menor porque hay 5 filas menos y cada una ocupa 2 bytes en el directorio de filas. Caben menos filas porque las de este bloque son más largas (84 bytes: el DNI, el nombre y el correo de un ID de 5 cifras tienen más caracteres) y el bloque se llena antes. **Sí se ve la limpieza diferida**: la ranura 0x01 sigue con `Lck 85` y flag `--U-`, es decir, la transacción de V002 confirmó pero nadie ha vuelto a modificar el bloque para limpiar los bytes de bloqueo.

### Parte L

**Punto de control** (`script/20261026T142902Z_13-capacidad.script.log`).
- Estadísticas de ACA_ESTUDIANTES: r = 20 000, R = 76 bytes, PCTFREE 10, **244 bloques** bajo la HWM y 256 asignados.
- Filas por bloque medidas con `DBMS_ROWID`: 231 bloques con filas, de 68 a 95 filas, media **86,6**.
- Fórmula de la Unidad 3: bfr = ⌊(8192 − 96) · 0,9 / 76⌋ = 95 → b = ⌈20 000 / 95⌉ = **211**. Versión Oracle (cabecera 122 y 2 bytes de directorio por fila): bfr 93 → 216.
- Coste medido: lectura lógica **2,6 µs** (400 000 lecturas, 4 por búsqueda, 1040 ms de CPU); física aleatoria **7,5 µs** (5464 lecturas en 41,2 ms); secuencial 4595 bloques en 53 peticiones (~87 bloques por petición) en **45,5 ms**, Bw = 790 MB/s.
- En mi equipo el cociente c_sec / c_aleat sale **1,319** (en el enunciado, 0,762): el bloque secuencial (9,9 µs) me salió más caro que el aleatorio (7,5 µs). Es el efecto de la caché de páginas de Linux: la "lectura física aleatoria" casi nunca va al disco. Con ese cociente, el umbral es (1/86) · 1,319 = **1,53 %** de las filas.

**Reto — dimensiona ACA_MATRICULAS** (`scripts/lab4/13-reto-matriculas.sql`, `script/…_13-reto-matriculas.script.log`).
- Predicción: R = 30 bytes, PCTFREE 10 → bfr = ⌊8096 · 0,9 / 30⌋ = 242 → b = ⌈60 000 / 242⌉ = **248 bloques**.
- Realidad: **370 bloques** bajo la HWM (384 asignados). Con `DBMS_ROWID`: 301 bloques con filas, de 159 a 210, media **199,3** filas por bloque.
- La diferencia tiene dos causas. (1) **Sobrecarga por fila**: en una fila tan corta, los 3 bytes de cabecera, los 5 bytes de longitud (uno por columna) y los 2 del directorio pesan mucho. Con unos 36 bytes reales por fila, ⌊(8192 − 122) · 0,9 / 36⌋ = 201, que coincide con los 199 medidos. En ACA_ESTUDIANTES (filas de 76 bytes) esa sobrecarga se notaba menos. (2) **Bloques sin filas bajo la HWM**: `DBMS_SPACE` da 300 FULL + 1 FS2 + 7 FS4 + **62 sin formatear** = 370. ASSM formatea bloques por lotes, y la HWM sube antes de llenarlos.
- Recorrido completo en un HDD a 150 MB/s: 370 · 8192 B / 150 MB/s ≈ **19 ms**. La tabla es pequeña: lo caro en HDD sería leerla por índice con filas desordenadas, no entera.

### Parte M

**Punto de control** (`script/20261026T142921Z_14-filas-migradas.script.log`).
- MIGRA con PCTFREE 0: 5000 filas en 13 bloques y `CHAIN_CNT` 0. Tras hacer crecer 1 de cada 5 filas a 300 bytes: 58 bloques y **`CHAIN_CNT` 1000 (20 %)**, exactamente las filas con ID múltiplo de 5.
- `LIST CHAINED ROWS` guarda las 1000 filas. La primera es el ID 2935, ROWID `AAAR/3AAAAAABYLAAC` (archivo 25, bloque 5643, ranura 2).
- En el volcado del bloque 5643, la ranura 2 tiene `tl: 9 fb: --H----- … cc: 0` y `nrid: 0x00001626.25a`. Queda solo la cabeza, sin las piezas F ni L. En BIGFILE, la parte anterior al punto es el bloque: 0x1626 = **5670**, y 0x25a = 602 es la ranura nueva.
- ANCHA: la fila de unos 12 000 bytes da `CHAIN_CNT` 1 (encadenada) y la fila "corta" no.
- Tras `MOVE PCTFREE 20`, PK_MIGRA queda `UNUSABLE` y vuelve a `VALID` con `REBUILD`. Resultado: `CHAIN_CNT` 0 en 63 bloques.

### Parte N

**Autopsia** (`spool/20261026T143015Z_15-autopsia-instancia.spool.log`) e informe en `docs/bitacora/lab4-autopsia.md`. Lo que más llama la atención de mi entorno:
- Solo hay 3 errores ORA- en 24 h: `ORA-00800` ×2, ruido del contenedor al arrancar, y `ORA-959` ×1, provocado por `DROP TABLESPACE IF EXISTS tbs_lab4` en la Parte L. El enunciado mostraba 17 porque allí se había hecho la Parte I ese mismo día.
- El arranque de hoy (14:27:48 UTC) hizo **recuperación de instancia** (`Beginning crash recovery of 1 threads`, 0,27 MB de redo aplicados). El contenedor estaba `Exited (255)` porque se cerró Docker Desktop con la base abierta: fue, sin querer, un `SHUTDOWN ABORT`. No se perdió nada.
- `FORCE_LOGGING = YES` y ARCHIVELOG **sin FRA**: los archivados van a `$ORACLE_HOME/dbs/arch` (3 archivos, 228 MB).

**Verificación final** (`script/20261026T143226Z_16-verificacion-final.script.log`): **TODO OK**, 0 fallos.

---

## Preguntas de comprobación

**1.** La copia es consistente porque se tomó tras `SHUTDOWN IMMEDIATE` (evidencia 00, paso 4: *Database closed / dismounted / instance shut down*): el cierre limpio hace un checkpoint final, todos los datafiles quedan con el mismo SCN de checkpoint y no hace falta redo para abrirla. Con la base abierta, cada archivo se copiaría en un instante distinto con bloques a medio escribir: sería inconsistente y solo serviría con recuperación (ARCHIVELOG y RMAN).

**2.** `manifiesto.txt` dice qué es la copia: etiqueta `lab3-final`, fecha 20261022T163416Z, contenedor, volumen, imagen, commit de Git `7dee274`, tipo «copia en frío consistente» y 0 archivos fuera del volumen. `SHA256SUMS` guarda la huella de cada archivo para detectar corrupción o modificación (`sha256sum --check` dio OK a los cuatro). `restaurar-estado.sh` comprueba primero esas sumas y se detiene si alguna falla, y después exige escribir el nombre del volumen antes de borrar nada.

**3.** **RPO** (cuántos datos puedo perder): mi copia es del 2026-10-22 a las 16:34 UTC; si restaurara, perdería todo lo posterior (reubicación de datafiles, V003, V002, OMF…). **RTO** (cuánto tardo en volver a dar servicio): no lo he medido porque no he restaurado; la copia tardó unos 2 minutos (16:32:34 → 16:34:16) más ~10 s de arranque, y el enunciado indica alrededor de un minuto para restaurar. Lo mediré en el simulacro del Lab 5.

**4.** En `$ORACLE_HOME/dbs` (`/opt/oracle/product/26ai/dbhomeFree/dbs/academia01.dbf`, etc., evidencia 01), porque V000 usó rutas relativas y, sin destino por defecto, Oracle las resuelve desde esa carpeta. Lo habría evitado `DB_CREATE_FILE_DEST` apuntando al volumen (OMF), o rutas absolutas en V000.

**5.** Porque `RENAME DATAFILE` solo cambia la ruta guardada en el control file; no mueve el archivo. Si antes no se copia el archivo con el sistema operativo a la nueva ruta (con el tablespace OFFLINE), Oracle no lo encontrará al ponerlo ONLINE (ORA-01157).

**6.** V000 ya se aplicó en todos los entornos: una migración aplicada es historia, y editarla haría que entornos distintos tuvieran estados distintos con el «mismo» V000. Los cambios van en una migración nueva (V003). Borrar las contraseñas del archivo no sirve porque siguen en el historial de Git; invalidarlas sí protege: con `NO AUTHENTICATION`, la contraseña antigua `Academia_2026_*` da ORA-01017.

**7.** Demuestra que el contenedor es desechable y que todo el estado vive en el volumen: tras `docker rm` y recrear con el 05 v2, los 5 tablespaces y las 14 tablas de negocio son idénticos, y ya no se publica el 8181 (`script/…_03-prueba-persistencia.script.log`). Se ejecuta después de reubicar porque, si algún datafile estuviera en la capa del contenedor, el `docker rm` lo borraría; y después de la copia de la Parte A, por si algo sale mal.

**8.** Instancia (cambia al rearrancar o recrear): `STARTUP_TIME` 2026-10-22 16:47:01; `HOST_NAME` 8b68d5c7389b (el ID del contenedor nuevo; antes era 606c30eea60f); SGA de 1536 MB y 60 procesos de background. Base de datos (persiste en disco): `DBID` 1509902213; `CREATED` 2026-07-05; `LOG_MODE` ARCHIVELOG, con 16 datafiles, 2 control files y 3 redo (`spool/20261022T165318Z_05-instancia-y-base.spool.log`, `script/20261022T165741Z_05-instancia-so.script.log`).

**9.** NOMOUNT lee el SPFILE (o PFILE): reserva la SGA y arranca los procesos. MOUNT lee los control files: conoce datafiles y redo, pero no los abre. OPEN abre datafiles y redo online. Por eso en NOMOUNT `v$database` da ORA-01507 (no hay control file abierto) y en MOUNT `dba_tables` da ORA-01219 (el diccionario está en SYSTEM, todavía cerrado).

**10.** `v$parameter` es el valor efectivo en memoria; `v$spparameter`, lo escrito en el SPFILE. Con `db_files` (estático): `SCOPE = MEMORY` falló con ORA-02095; con `SCOPE = SPFILE` quedó 200 en memoria y 300 en el SPFILE, pendiente del próximo arranque; tras `RESET`, el SPFILE volvió a «no especificado» (`script/20261022T170137Z_07-parametros-cambios.script.log`).

**11.** Porque `PROCESSES` dimensiona estructuras de la SGA que se reservan al arrancar. Aunque `v$parameter` diga `ISSYS_MODIFIABLE = IMMEDIATE`, el cambio en memoria dio ORA-02097 + ORA-02095: en la práctica es estático. La metadata orienta; la prueba decide.

**12.** **ASMM** (gestión automática de la memoria compartida), no AMM: `memory_target = memory_size = 0`, `sga_target = 1536M` y `pga_aggregate_target = 512M`. Además, `db_cache_size` y `shared_pool_size` están a 0, así que Oracle reparte la SGA: buffer cache 1024 MB y shared pool 384 MB en `v$sga_dynamic_components` (`spool/20261022T170309Z_08-memoria.spool.log`).

**13.** Ver el punto de control de la Parte G: 355/259 en caché fría y 247/0 en caliente; tasa de acierto ≈ 27 % y 100 %; 245 bloques en `v$bh`.

**14.** Con literales, 1000 consultas provocaron 1092 análisis, de ellos 1008 duros, 660 ms de CPU y 690 ms en total. Con `:id`, 1 análisis (duro) y 10 ms. En `V$SQL` quedaron 414 cursores con literales ocupando 14 699 KB de shared pool, frente a 1 cursor con 1000 ejecuciones y 39 KB. Faltan unos 586 cursores porque la shared pool ya los había expulsado: eso también es coste (`script/20261022T170310Z_08-parse-y-pga.script.log`).

**15.** `v$process` da a LGWR el SPID **1421**, y dentro del contenedor `/proc/1421` es `db_lgwr_FREE` (igual con PMON 1373, DBW0 1419, CKPT 1423…; `script/20261022T171032Z_09-procesos-so.script.log`). `docker top` muestra otro número porque ve el proceso desde el anfitrión: el contenedor tiene su propio espacio de nombres de PID.

**16.** Desde la raíz, SYS ve los datafiles de los tres contenedores: 4 de `CDB$ROOT` + 3 de `PDB$SEED` + 9 de `FREEPDB1` = 16. Dentro de FREEPDB1, las V$ y las CDB_ se filtran a la propia PDB y solo ve sus 9 (`script/20261022T171135Z_10-que-ve-cada-usuario.script.log`).

**17.** Porque Oracle no revela la existencia de objetos que no puedes ver: responde como si no existieran (ORA-00942 en `DBA_TABLES`, `V$SESSION` y `ADMIN_ACADEMIA.ACA_ESTUDIANTES`). Cuando el objeto sí es visible pero falta una acción, 23ai sí lo dice: ORA-41900 *missing UPDATE privilege*.

**18.** Los dos son comunes, pero C##OPS_RO tiene el atributo `CONTAINER_DATA = ALL` (`DEFAULT_ATTR = Y`, `ALL_CONTAINERS = Y`) y desde la raíz ve las filas de todas las PDB; C##LAB4_AUDITOR solo ve la raíz y los datos con CON_ID 0. Los igualaría `ALTER USER c##lab4_auditor SET CONTAINER_DATA = ALL CONTAINER = CURRENT;`.

**19.** Ventaja: un solo `GRANT` cubre todas las tablas del esquema, también las que se creen después, sin mantener una lista tabla a tabla. Riesgo: precisamente eso; si mañana se crea en el esquema una tabla sensible, el usuario la puede leer sin que nadie lo haya decidido.

**20.** `COMMON_USER_PREFIX = C##`. Por eso, en el bloque 3a, `CREATE USER lab4_local` en la raíz falló con ORA-65096 (*common user or role name must start with prefix C##*): en la raíz solo se pueden crear usuarios comunes, y deben llevar el prefijo (`script/20261022T171142Z_10-ciclo-vida-pdb.script.log`).

**21.** **Son la base de datos:** 16 datafiles (3954 MB), 2 control files (36 MB), 3 redo online (600 MB) y 3 tempfiles (60 MB, que no se copian: se recrean). **Relacionados:** SPFILE, password file, el ADR (alert log y trazas) y los 2 redo archivados (122 MB). El password file va en «relacionados» porque no contiene datos de la base, aunque sin él nadie entra como SYSDBA por red.

**22.** 100 MB son 104 857 600 bytes; el archivo mide 104 865 792. La diferencia, 8192 bytes, es exactamente un bloque: el bloque de cabecera del archivo, que Oracle añade al tamaño pedido.

**23.** (1) Los 2 control files están en la misma carpeta y el mismo volumen (`/opt/oracle/oradata/FREE/`): si se pierde ese disco, se pierden los dos. (2) Cada grupo de redo tiene un solo miembro, sin multiplexar: si se corrompe el miembro del grupo actual, no hay copia.

**24.** Porque el alert log y las trazas son el historial de lo que le pasó a la base. Fuera del volumen (`/opt/oracle/diag`, apartado 4 de `11-archivos-so`), se pierden al recrear el contenedor: no se pueden investigar incidencias anteriores. Lo comprobé: tras recrear el contenedor en la Parte C, el alert log tenía 0 líneas de septiembre, todo el Lab 3 había desaparecido.

**25.** ROWID `AAAR2kAAAAAAAMPAAF`, formato OOOOOO FFF BBBBBB RRR en base 64 (A=0 … Z=25, a=26 … z=51, 0=52 … 9=61):

| Trozo | Caracteres | Cálculo | Valor | DBMS_ROWID |
| --- | --- | --- | --- | --- |
| Objeto | `AAAR2k` | 17·64² + 54·64 + 36 | 73124 | `DATA_OBJECT_ID` = 73124 (ACA_ESTUDIANTES) |
| Archivo | `AAA` | 0 | 0 | BIGFILE: archivo absoluto 16 con `ROWID_TO_ABSOLUTE_FNO` |
| Bloque | `AAAAMP` | 12·64 + 15 | 783 | `ROWID_BLOCK_NUMBER(rowid,'BIGFILE')` = 783 |
| Fila | `AAF` | 5 | 5 | `FILA_EN_BLOQUE` = 5 |

**26.** `nrow` = número de filas del bloque (90); `fsbo` = inicio del espacio libre (*free space begin offset*, justo después del directorio de filas: 0xc6); `fseo` = fin del espacio libre (*free space end offset*, donde empiezan las filas, que crecen desde el final: 0x427); `avsp` = espacio disponible. 0x427 − 0xc6 = 0x361 → 1063 − 198 = **865** = `avsp`.

**27.** La ranura 0x01 de la ITL tiene la transacción que insertó las 90 filas del bloque (V002). `Flag --U-` indica que ya hizo commit (*upper bound commit*, confirmado rápido), pero `Lck 90` indica que los bytes de bloqueo de esas 90 filas no se han limpiado. Es la **limpieza diferida de bloques**: el COMMIT no vuelve a visitar todos los bloques que modificó (por eso es rápido); el siguiente proceso que lea o modifique el bloque comprueba que la transacción terminó y limpia la ITL y los bytes de bloqueo.

**28.** `tl: 78` = 3 bytes de cabecera de fila (flag, byte de bloqueo y número de columnas, `cc: 7`) + 7 bytes de longitud (uno por columna, todas de menos de 250 bytes) + 68 bytes de datos (3 + 9 + 9 + 11 + 19 + 6 + 11). 3 + 7 + 68 = 78. Los 68 coinciden con `BYTES_DE_DATOS_FILA_101`.

**29.** Fórmula de la Unidad 3 con mis estadísticas (r = 20 000, R = 76, PCTFREE 10): bfr = ⌊(8192 − 96) · 0,9 / 76⌋ = ⌊95,9⌋ = **95** filas por bloque, y b = ⌈20 000 / 95⌉ = **211** bloques (`script/20261026T142902Z_13-capacidad.script.log`, sección 3). La tabla tiene **244** porque la fórmula simplifica tres cosas:
- Cada fila ocupa algo más que `AVG_ROW_LEN`: 2 bytes del directorio de filas, y la cabecera del bloque es de 122 bytes con 2 ranuras ITL. Con eso salen 93 filas y 216 bloques.
- Las filas reales varían. La sección 2 cuenta de 68 a 95 filas por bloque, con media 86,6, en 231 bloques.
- Bajo la HWM hay 13 bloques casi vacíos: 230 FULL + 1 FS2 + 13 FS4 = 244 (Parte K). Además hay 256 bloques asignados, porque el espacio se reserva por extensiones.

**30.** Con mis cifras (sección 5):
- **Lectura lógica:** 1040 ms de CPU / 400 000 lecturas = **2,6 µs**. Cada búsqueda hace 4: raíz, rama, hoja y tabla.
- **Física aleatoria:** 41,2 ms / 5464 lecturas = **7,5 µs**.
- **Bloque secuencial:** 45,5 ms / 4595 bloques = **9,9 µs** por bloque, a 87 bloques por petición (790 MB/s).

En mi equipo la lectura secuencial por bloque salió más cara que la aleatoria (cociente 1,319). Eso solo pasa porque las dos se sirven desde la RAM de Linux (pregunta 32).

**31.** HDD con Bw = 150 MB/s y lat = 5 ms:
- c_sec por bloque = 8192 B / (150 · 1 048 576 B/s) ≈ **52 µs**.
- c_sec / c_aleat = 52 µs / 5000 µs ≈ **0,0104**.
- Umbral = (1/86) · 0,0104 ≈ 0,000121 → **0,012 %** de las filas, unas 48 de las 400 000 de LECTURAS.

Por encima de eso gana el recorrido completo: 4595 bloques en secuencial son unos 0,24 s, y los mismos 4595 bloques uno a uno son 23 s. En mi contenedor el umbral era del 1,53 %: la misma fórmula da una decisión distinta con otro hardware.

**32.** Porque `ALTER SYSTEM FLUSH BUFFER_CACHE` vacía la caché de Oracle, pero no la caché de páginas de Linux. Casi todas las "lecturas físicas" se sirven desde la RAM del sistema operativo y no desde el disco: 7,5 µs, cuando un SSD tarda unos 100 µs y un HDD unos 5 ms. La media de `db file sequential read` desde el arranque (269 µs, sección 6) es mayor porque incluye las lecturas en frío tras arrancar. **No invalida el método**: medir lógicas, físicas y tiempos y aplicar la fórmula es igual en producción; lo que cambia son las cifras que se introducen.

**33.**

| | Migración | Encadenamiento |
| --- | --- | --- |
| Causa | Un UPDATE agranda una fila que ya no cabe en su bloque (en mi prueba, de 1 a 300 bytes con PCTFREE 0) | La fila mide más que un bloque (mi fila de unos 12 000 bytes en bloques de 8 KB) |
| Qué queda | La cabeza en el bloque original con `fb: --H-----` y `nrid` (dirección nueva) | La primera pieza enlazada con las siguientes |
| Detección | `ANALYZE … COMPUTE STATISTICS` → `CHAIN_CNT` (1000, 20 %); `LIST CHAINED ROWS`; estadística `table fetch continued row` | Igual (`CHAIN_CNT` 1 en ANCHA) |
| Cura | `ALTER TABLE … MOVE (ONLINE)` con PCTFREE adecuado: `CHAIN_CNT` volvió a 0 | No tiene cura reorganizando: bloque mayor (16/32 KB) o rediseño (LOB, tabla aparte) |

**34.** Una búsqueda normal por clave en MIGRA cuesta 3 lecturas lógicas: dos niveles de índice y el bloque de la tabla. Las 200 búsquedas que caen en filas migradas (IDs múltiplo de 5 entre 1 y 1000) necesitan una más para seguir el `nrid`, así que cuestan 4. (800 · 3 + 200 · 4) / 1000 = 3200 / 1000 = **3,2**. Coincide con lo medido: `table fetch continued row` = 200 y 3200 lecturas lógicas (sección 4).

**35.** Porque `MOVE` reescribe las filas en bloques nuevos, cambia el ROWID de todas y el índice sigue apuntando a los ROWID viejos. Oracle lo marca `UNUSABLE`: PK_MIGRA salió `UNUSABLE` y volvió a `VALID` tras `ALTER INDEX … REBUILD`. En producción usaría `ALTER TABLE … MOVE ONLINE`, que mantiene los índices válidos y no bloquea el DML, en una ventana de baja carga, con espacio para la copia y recogiendo estadísticas al terminar.

**36.** Tres hallazgos de mi autopsia (detalle en `docs/bitacora/lab4-autopsia.md`):
1. **ARCHIVELOG sin FRA** (`db_recovery_file_dest_size = 0`, archivados en `$ORACLE_HOME/dbs/arch`, 228 MB). Riesgo: crecen sin límite ni alerta y, si se llena el disco, la base se para. Acción: FRA de 4 GB y retención con RMAN. Prioridad **alta**.
2. **Redo con un solo miembro por grupo** (3 grupos de 200 MB, `members = 1`). Riesgo: si se corrompe el miembro CURRENT, se pierden transacciones confirmadas. Acción: segundo miembro por grupo, en otro disco en producción. Prioridad **alta**.
3. **Parada no controlada**: recuperación de instancia en el arranque de hoy, 0,27 MB de redo, con el contenedor en `Exited (255)`. Riesgo: cada apagado de Docker Desktop es un `SHUTDOWN ABORT`; hoy no se perdió nada, pero se depende siempre de la recuperación. Acción: `docker stop` (que hace un cierre limpio) antes de apagar el equipo. Prioridad **media**.

**37.** Por mínimo privilegio. SYSTEM tiene el rol DBA: un error en una consulta de observación, o una contraseña filtrada, podría modificar o borrar cualquier cosa. C##OPS_RO solo tiene `CREATE SESSION`, `SELECT_CATALOG_ROLE`, `CONTAINER_DATA = ALL` y el `SELECT` puntual sobre `V_$DIAG_ALERT_EXT`. La verificación 16 comprueba que **no tiene ningún privilegio `ANY` de escritura** (`ops_ro_dml = 0`). No puede hacer DML ni DDL, crear usuarios, conceder privilegios, cambiar parámetros ni arrancar o parar la base. Además, es común y con `CONTAINER_DATA` ve todas las PDB desde la raíz.

**38.** (1) Las **contraseñas de los `admin_*` escritas en V000** y guardadas en el historial de Git. V003 las invalida con `NO AUTHENTICATION`, y la contraseña antigua da ORA-01017. (2) **`sys/<contraseña>` en la línea de comandos** de `08-aplicar-migraciones.sh`, visible con `ps` para cualquier usuario del sistema. Ahora todo se ejecuta con `docker exec … sqlplus / as sysdba`, con autenticación del sistema operativo y sin contraseña. Además, la única contraseña que queda (la de C##OPS_RO) vive en `config/.env`, que está fuera de Git, y la verificación 16 lo comprueba.

---

## Preguntas tipo examen

| P | Respuesta | Justificación | Dónde lo comprobé |
| --- | --- | --- | --- |
| 1 | **A, D** | Tras `SHUTDOWN IMMEDIATE` todos los archivos tienen el mismo SCN de checkpoint: la copia es consistente y abre con `STARTUP` sin redo. | Parte A (copia en frío, evidencia 00) |
| 2 | **B** | Sin `MOVE DATAFILE` en línea (Enterprise Edition), el archivo se mueve con el tablespace OFFLINE, se copia con el SO y se hace `RENAME`; Oracle no copia nada. | Parte C (03-reubicar-datafiles) |
| 3 | **A, C** | `STARTUP_TIME` cambió al recrear el contenedor (16:47) y `CREATED` sigue siendo el 2026-07-05; el DBID (1509902213) no cambió. | Parte E (evidencia 05) |
| 4 | **A, C** | En NOMOUNT solo existe la instancia: se lee `v$parameter` y se puede ejecutar `CREATE CONTROLFILE`; el diccionario y ARCHIVELOG necesitan más. | Parte E (06-arranque-por-etapas) |
| 5 | **B** | `ALTER DATABASE ARCHIVELOG` exige la base montada y no abierta (si está abierta, ORA-01126). | Parte E; lo haré en el Lab 5, Parte L |
| 6 | **B** | Con SPFILE, el `SCOPE` por defecto es `BOTH`: memoria y SPFILE. | Parte F (07-parametros-cambios) |
| 7 | **C** | `PROCESSES` es de toda la instancia y no se puede cambiar desde una PDB: ORA-65040. | Parte F (ORA-65040 desde la PDB) |
| 8 | **A, C** | Se arranca con un PFILE bueno y se regenera el SPFILE a partir de él. | Parte F (PFILE versionado) |
| 9 | **B** | Con `SGA_TARGET` > 0, ASMM reparte la SGA; un componente fijado actúa como mínimo. | Parte G (ASMM, pregunta 12) |
| 10 | **A, D** | El área de ordenación y la memoria de sesión de un servidor dedicado son privadas (PGA); el resto es SGA. | Parte G (08-parse-y-pga) |
| 11 | **C** | El COMMIT espera a que LGWR escriba el redo (`log file sync`); DBWn escribe los bloques más tarde. | Parte H; Lab 5, Parte N |
| 12 | **B, D** | PMON y SMON siempre existen; ARCn solo en ARCHIVELOG y CJQ0 solo con jobs. | Parte H (09-procesos) |
| 13 | **B** | Dentro de una PDB las V$ se filtran a su contenedor: SYS ve 9 datafiles de CON_ID 3. | Parte I (pregunta 16) |
| 14 | **B** | Le falta el atributo `CONTAINER_DATA`, igual que a C##LAB4_AUDITOR. | Parte I (pregunta 18) |
| 15 | **A, D** | El privilegio de esquema cubre las tablas futuras de HR y nada fuera de HR; READ no permite UPDATE. | Parte I (ADMIN_CLINICA siguió cerrado) |
| 16 | **B, D** | Control files y redo online son la base; password file, SPFILE y alert log son relacionados. | Parte J (pregunta 21) |
| 17 | **C** | Sin archivado ni copias multiplexadas en otro disco, solo queda la última copia completa. | Parte J (pregunta 23) |
| 18 | **B** | Sin 'BIGFILE', la función reparte los bits como en SMALLFILE; con 'BIGFILE' sale el bloque 783 del volcado. | Parte K (12-bloque) |
| 19 | **A, B** | PCTFREE es la reserva para que crezcan las filas; con PCTFREE 10 una fila aún puede migrar si crece más. | Partes K y M |
| 20 | **B** | bfr = ⌊(8192 − 96) · 0,9 / 180⌋ = ⌊40,5⌋ = 40 → 2 000 000 / 40 = **50 000**. | Parte L (misma fórmula, pregunta 29) |
| 21 | **B** | `db file scattered read` = lectura multibloque a la buffer cache (recorrido completo). | Parte L, sección 6 |
| 22 | **A, C** | Se identifican con `LIST CHAINED ROWS` y se curan con `MOVE ONLINE` y más PCTFREE; DBMS_STATS no calcula `CHAIN_CNT`. | Parte M |
| 23 | **B** | 12 000 bytes no caben en un bloque de 8 KB: fila encadenada que MOVE no arregla. | Parte M (ANCHA, `CHAIN_CNT` 1) |
| 24 | **B** | Cuenta común de solo lectura con el GRANT puntual: es exactamente C##OPS_RO. | Partes B y N |
| 25 | **B** | PDB$SEED es la plantilla de solo lectura (READ ONLY en la autopsia). | Parte I; autopsia sección 1 |
| 26 | **C** | En una PDB solo se crean usuarios locales, y un nombre local no puede empezar por C##: ORA-65094. | Parte I (10-ciclo-vida-pdb) |
| 27 | **B** | Una PDB abierta no se puede borrar (ORA-65025): primero `CLOSE IMMEDIATE`. | Parte I |
| 28 | **A, C** | En MOUNT responden las vistas fijas que leen el control file (V$DATAFILE, V$LOG); las DBA_/CDB_ dan ORA-01219. | Parte E |
| 29 | **A** | KCC = Kernel Cache Control file: X$KCCLE y X$KCCRT salen del control file. | Parte I (definición de V$LOG) |
| 30 | **B** | Las CDB_ existen en la raíz y en cada PDB; desde una PDB solo devuelven sus filas (DBA_ 5 frente a CDB_ 15). | Parte I |
| 31 | **B** | Los tempfiles no se respaldan: se recrean vacíos. | Parte J (punto de control TEMP) |
| 32 | **B** | La instancia ya leyó el SPFILE al arrancar; sigue funcionando y `CREATE SPFILE FROM MEMORY` lo regenera. | Parte F |
| 33 | **B** | V$PWFILE_USERS lista quién está en el password file (en mi base, solo SYS). | Parte J |
| 34 | **A, B** | La cabecera del bloque contiene la ITL y el directorio de filas (slot array). | Parte K (volcado, secciones [A] y [B]) |
| 35 | **B** | Con AUTOALLOCATE, primero extensiones de 64 KB y, al crecer, de 1 MB. | Parte K (12-bloque, sección 3) |
| 36 | **B** | ASSM: el llenado de los bloques se gestiona con mapas de bits (FULL, FS1-FS4). | Partes K y L (DBMS_SPACE) |
| 37 | **B** | Desde 23ai, el tablespace por defecto es BIGFILE y gestionado localmente (TBS_ACADEMIA). | Parte K |
| 38 | **A** | 0 físicas significa que los 4 bloques estaban en la buffer cache (raíz, rama, hoja y tabla). | Parte L (5a: 4 por búsqueda) |
| 39 | **A, B** | Más reserva libre o filas más largas = menos filas por bloque (ACA_MATRICULAS, 30 bytes y 199 por bloque, frente a ACA_ESTUDIANTES, 76 bytes y 87). | Parte L (reto) |
| 40 | **B** | Vacía la caché de todas las sesiones, que vuelven a leer de disco: picos de latencia. | Parte L |
| 41 | **B** | Migrada: cabía y se mudó al crecer; encadenada: no cabe en ningún bloque. | Parte M |
| 42 | **A** | REBUILD (o haber usado MOVE ONLINE) recupera el índice UNUSABLE. | Parte M (PK_MIGRA) |
| 43 | **A** | V$DIAG_ALERT_EXT lee el alert log con SQL; C##OPS_RO tiene su GRANT. | Partes J y N |
| 44 | **A, B** | Se amplía el espacio y se investiga quién crece; borrar redo o reiniciar no tiene sentido. | Parte N (sección 5) |
| 45 | **A, B** | Una sola instancia (SGA y procesos) y un solo redo para toda la CDB (CON_ID 0 en V$LOG). | Partes H e I |
| 46 | **B** | Un usuario local sin `SET CONTAINER` recibe ORA-01031 (LAB4_ANALISTA). | Parte I |
