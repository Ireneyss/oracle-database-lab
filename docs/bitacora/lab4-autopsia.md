# Lab 4 · Autopsia de la instancia FREE

Fuente: `docs/bitacora/lab4/evidencia/spool/20261026T143015Z_15-autopsia-instancia.spool.log` (ejecutada con C##OPS_RO, solo lectura), más el alert log consultado como SYSDBA el mismo día. Horas en UTC.

## Ficha

| Dato | Valor |
| --- | --- |
| Instancia / host | FREE en `8b68d5c7389b` (Oracle 23.26.3.0.0), arrancada el 2026-10-26 14:27 |
| Base | FREE, DBID 1509902213, CDB, `ARCHIVELOG`, `FORCE_LOGGING = YES`, `FLASHBACK_ON = NO` |
| Contenedores | CDB$ROOT, PDB$SEED (810 MB, READ ONLY) y FREEPDB1 (1432 MB, READ WRITE) |
| Memoria | SGA máx. 1529 MB (buffer cache 1104 MB, shared pool 384 MB); PGA objetivo 512 MB, asignada 390 MB, máximo 541 MB |
| Procesos | 93 de segundo plano y 5 servidores; ARC0 y ARC1 presentes |
| Archivos | 16 datafiles (3954 MB), 3 tempfiles (60 MB), 2 control files (36 MB), 3 miembros de redo (600 MB), 3 archivados en disco (228 MB) |

## Hallazgos

| # | Sección | Evidencia (valor exacto) | Riesgo | Acción | Prioridad |
| --- | --- | --- | --- | --- | --- |
| 1 | 1 · 4 | `LOG_MODE = ARCHIVELOG` pero `db_recovery_file_dest` vacío y `db_recovery_file_dest_size = 0`; los archivados van a `LOG_ARCHIVE_DEST_1 = $ORACLE_HOME/dbs/arch` (3 archivos, 228 MB) | Los archivados crecen sin límite ni vigilancia dentro del volumen; sin FRA no hay retención gestionada ni aviso al 80 %, y si el disco se llena la base se detiene (ORA-00257) | Configurar FRA con tamaño (4 GB) y pasar ahí el archivado; política de retención con RMAN | Alta |
| 2 | 4 | 2 control files, los dos en `/opt/oracle/oradata/FREE/` | Punto único de fallo: un borrado o un fallo del volumen se lleva las dos copias | Multiplexar una tercera copia (Lab 5); en producción, en discos distintos | Alta |
| 3 | 4 | 3 grupos de redo de 200 MB con **1 miembro** cada uno (`v$log.members = 1`) | Si se corrompe el miembro del grupo CURRENT se pierden transacciones confirmadas | Añadir un segundo miembro por grupo (Lab 5) | Alta |
| 4 | 1 · 10 | Alert log: el último arranque (2026-10-26 14:27:48) hizo `Beginning crash recovery of 1 threads` y aplicó 0,27 MB de redo; no hay `Shutting down` desde el 22-10. El contenedor estaba `Exited (255)` | La base se cerró de golpe al apagarse Docker Desktop, como un corte de luz. No se perdió nada (WAL + SMON), pero es una parada no controlada | Parar la base (`SHUTDOWN IMMEDIATE` / `docker stop`) antes de cerrar Docker Desktop o apagar el equipo | Media |
| 5 | 4 | `diagnostic_dest = /opt/oracle`, fuera del volumen | Al recrear el contenedor se pierde el alert log (ya pasó con septiembre) | ADR persistente (volumen) o envío del alert log a un sistema de logs | Media |
| 6 | 6 | ADMIN_CLINICA, ADMIN_FINTECH, ADMIN_LOGISTICA y ADMIN_RETAIL con `ALTURA_MAX` vacía | Sin estadísticas: el optimizador elige planes a ciegas | `DBMS_STATS.GATHER_SCHEMA_STATS` y dejar activo el job automático | Media |
| 7 | 2 | `maximum PGA allocated = 541 MB` > `aggregate PGA target = 512 MB` | El objetivo no es un límite; si se repite en producción, más PGA y menos memoria para el resto | Vigilar `v$pgastat` y las áreas de trabajo en varias pasadas; aquí lo causaron los experimentos de las Partes G y L | Baja |
| 8 | 6 | ADMIN_ACADEMIA: 9 índices, 2 con clustering factor cercano al número de filas | Esos índices dejan de compensar pronto en consultas por rango | Analizarlos con números (Lab 5, Parte E) | Baja |
| 9 | 9 | `_instance_recovery_bloom_filter_size = 1048576` (parámetro oculto) y `local_listener` vacío | Un parámetro con guion bajo cambiado sin documentar es una sorpresa en una migración o ante soporte | Documentar que lo fija la imagen de Oracle Free; no tocarlo sin indicación de soporte | Baja |
| 10 | 10 | 3 errores ORA- en 24 h: `ORA-00800` ×2 (VKTM y LGWR al arrancar) y `ORA-959` ×1 | 00800 es ruido conocido del contenedor (no puede subir la prioridad); 959 lo provocó el laboratorio (`DROP TABLESPACE IF EXISTS tbs_lab4` de la Parte L cuando el tablespace no existía) | Excluir 00800 de las alertas y documentarlo; 959, ninguna | Baja |

Puntos sanos: ningún tablespace pasa del 2,3 % de uso; ningún índice inválido; ninguna cuenta de la casa tiene el rol DBA (sección 7 vacía); solo hay 1 usuario común propio (C##OPS_RO) y 9 locales en FREEPDB1; `FORCE_LOGGING = YES` y el listener publica solo `free`, `freeXDB` y `freepdb1`.

## Resumen para dirección

1. La base funciona, tiene espacio de sobra y nadie tiene más permisos de los necesarios.
2. Hay tres riesgos altos que pueden causar pérdida de datos o una parada: las copias de seguridad automáticas del registro de cambios no tienen límite ni vigilancia, y los archivos de control y de registro no tienen copia en otro sitio.
3. Los tres se corrigen en el siguiente laboratorio (Lab 5) sin parar el servicio más de unos minutos.
