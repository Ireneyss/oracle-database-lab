# Runbook · Pérdida de un datafile de aplicación (Oracle 26ai Free, contenedor `oralab-26ai`)

**Cuándo usarlo:** una consulta o el alert log muestran, juntos:
- `ORA-01116: error in opening database file N` → Oracle no puede abrir el archivo N.
- `ORA-01110: data file N: '/ruta/archivo.dbf'` → **qué** archivo es.
- `ORA-27041: unable to open file` + `Linux-x86_64 Error: 2: No such file or directory` → **por qué**: el sistema operativo no lo encuentra (disco roto, borrado, montaje perdido).
- A veces también `ORA-63999: data file suffered media failure`: un proceso de fondo (CKPT o DBWn) lo detectó y Oracle **cerró la PDB** para protegerla.

Si el archivo es de `SYSTEM` o del undo de la raíz (CDB$ROOT), **no** es este runbook: la instancia se detiene y hay que hacer `STARTUP MOUNT` → `RESTORE` → `RECOVER` → `OPEN`. Avisa al responsable de la base de inmediato.

## 1. Comprobaciones previas (2 minutos, todo de solo lectura)

```sql
-- sqlplus / as sysdba (docker exec -it oralab-26ai sqlplus / as sysdba)
SELECT log_mode FROM v$database;                         -- debe ser ARCHIVELOG; si es NOARCHIVELOG -> solo restaurar la copia en frío completa (se pierde lo posterior): escalar
SELECT name, open_mode FROM v$pdbs;                       -- READ WRITE (camino 1) o MOUNTED (camino 2)
SELECT file#, name, status FROM v$datafile WHERE file# = &n;
SELECT * FROM v$recovery_area_usage WHERE number_of_files > 0;   -- la FRA no debe estar llena
```

```text
-- rman target /
LIST BACKUP OF DATAFILE n;        -- debe haber al menos una copia; si no hay: escalar (no seguir)
```

## 2. Reparación

**Camino 1 · la PDB sigue en READ WRITE** (solo el tablespace afectado está caído):

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER DATABASE DATAFILE n OFFLINE;          -- aísla el archivo; el resto de la PDB sigue en servicio
```
```text
RMAN> RESTORE DATAFILE n;                   -- copia el archivo desde la copia de RMAN (vuelve al SCN de la copia)
RMAN> RECOVER DATAFILE n;                   -- aplica redo archivado + online hasta ahora: RPO 0
```
```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER DATABASE DATAFILE n ONLINE;
```

**Camino 2 · la PDB está MOUNTED (ORA-63999)** (toda la PDB está caída; la CDB y las demás PDB, no):

1. Espera a que `v$pdbs` diga `MOUNTED` (no lances RMAN mientras se está cerrando: da ORA-01089 / ORA-01219).
2. `RMAN> RESTORE DATAFILE n;` y `RMAN> RECOVER DATAFILE n;`
3. `ALTER SESSION SET CONTAINER = FREEPDB1; ALTER DATABASE DATAFILE n ONLINE;`
4. `ALTER PLUGGABLE DATABASE FREEPDB1 OPEN;`. Al abrir, Oracle puede recuperar solo los otros archivos de la PDB (alert log: `ORA-01113 … needs media recovery` y `Recovering data file … from a fuzzy backup`). Es normal tras un cierre brusco de la PDB.

## 3. Verificar que funcionó

```sql
SELECT name, open_mode FROM v$pdbs;                                   -- FREEPDB1 READ WRITE
SELECT file#, status FROM v$datafile WHERE file# = &n;                -- ONLINE
SELECT COUNT(*) FROM admin_academia.aca_estudiantes;                  -- consulta de control: 20000
SELECT * FROM v$recover_file;                                         -- sin filas
```
Busca en el alert log `Media Recovery Complete` y `Completed: ALTER PLUGGABLE DATABASE FREEPDB1 OPEN`. **El incidente no está cerrado hasta que `v$pdbs` diga READ WRITE.**

## 4. Después

- Haz una copia nueva del tablespace (`BACKUP TABLESPACE FREEPDB1:<ts>;`): la anterior ya tiene que recorrer más redo.
- Anota en el registro de incidencias la hora del fallo, el camino seguido, el RTO (fallo → PDB abierta) y el RPO (0 si RECOVER terminó).
- **Avisa** al responsable de la base y al equipo de la aplicación afectada al empezar (servicio degradado) y al terminar. Si el fallo es de disco, abre una incidencia de sistemas: otro archivo de ese disco puede ser el siguiente.

Referencia medida en el laboratorio (simulacro D, `docs/bitacora/lab5/evidencia/script/*_14d-perdida-datafile.script.log`): camino 2, RTO 10 s, RPO 0.
