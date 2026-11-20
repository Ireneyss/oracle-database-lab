# Lab 6 · Respuestas · E066

## Notas de la bitácora

### Línea base (Parte B)

El 19/11/2026 a las 11:05 UTC, la lista de turno contaba 8 errores ORA- en las últimas 24 horas, todos ORA-00800 (Set Priority Failed, procesos VKTM y LGWR). Es ruido conocido del contenedor: Linux no deja a Oracle subir la prioridad de esos procesos y el error aparece en cada arranque. En ese periodo hubo tres arranques, y validar-arranque.sql mostró 2 desde el último, así que los arranques explican el recuento. No había ORA-00600, ORA-01578 ni ORA-04031. Referencia para los próximos días: un recuento parecido con el mismo número de arranques es normal. Un tipo de error nuevo, o un recuento que suba sin arranques, hay que investigarlo.

Evidencia: `script/20261119T110558Z_01-turno.script.log`, sección 4.

### Ruido conocido (C.3)

Errores del arranque de la Parte C y explicación de cada uno:
- ORA-00800 (×6): Set Priority Failed en VKTM y LGWR. Ruido conocido del contenedor; se anota en la línea base y no se persigue en cada arranque.
- ORA-65019 (×2): provocado a propósito en el paso 2 de C.2, al pedir abrir en READ WRITE una PDB que ya estaba abierta. No es un fallo.

Evidencia: `script/20261119T112912Z_02-estados-pdb.script.log`, sección 4.

## Preguntas de comprobación

### Partes A-C

### Pregunta 1

En las últimas 24 h el alert log tenía **8 errores ORA-**. Son `ORA-00800` (*Set Priority Failed* en VKTM y LGWR), un aviso conocido del contenedor: Oracle intenta subir la prioridad de esos procesos y Docker no se lo permite, así que aparece en cada arranque sin consecuencias. Desde ayer la base ha arrancado tres veces (al levantar el contenedor, en la copia en frío de la Parte A.5 y esta mañana), y `validar-arranque.sql` muestra 2 desde el último arranque, de modo que los reinicios explican la mayoría de los 8. Ese número no es una alarma por sí solo porque, sin compararlo con lo normal en mi base, no dice nada: aquí todo es ruido conocido y no hay errores internos (ORA-00600), de corrupción (ORA-01578) o de memoria (ORA-04031). Me preocuparía si apareciera alguno de esos tipos, o si el recuento subiera sin que la base se hubiera reiniciado.

Evidencia: `script/20261119T110558Z_01-turno.script.log`, sección 4 (8 errores).

### Pregunta 2

La ventana del miércoles es `WEDNESDAY_WINDOW`: empieza a las **22:00** (`byday=WED;byhour=22`) y dura **4 horas**, hasta las 02:00 del jueves. En ella corren las tres tareas de mantenimiento automático (AutoTask), las tres en estado `ENABLED`: la recogida de estadísticas del optimizador (`auto optimizer stats collection`), el asesor de espacio (`auto space advisor`) y el asesor de ajuste de SQL (`sql tuning advisor`). Cada una está asociada a un grupo de ventanas (`ORA$AT_WGRP_OS`, `_SA` y `_SQ`) que incluye las ventanas de los días laborables. El fin de semana las ventanas son más largas (20 horas desde las 06:00), y `WEEKNIGHT_WINDOW` y `WEEKEND_WINDOW` existen pero están desactivadas.

Evidencia: `spool/20261119T110620Z_01-automatizacion.spool.log`, secciones 1 y 2.

### Pregunta 3

Antes del cambio, `db_files` no estaba fijado en el SPFILE (`ISSPECIFIED = FALSE`). Como es un parámetro estático (`ISSYS_MODIFIABLE = FALSE`), `ALTER SYSTEM SET db_files = 250 SCOPE = MEMORY` falló con `ORA-02095`. Con `SCOPE = SPFILE` el cambio se aceptó, pero solo en el archivo: `V$SPPARAMETER`, que lee el SPFILE, mostraba **250** con `ISSPECIFIED = TRUE`, mientras que `V$PARAMETER`, que lee la instancia en marcha, seguía en **200**. Es decir, el SPFILE dice cómo arrancará la base la próxima vez y `V$PARAMETER` dice cómo está funcionando ahora. Sin el `RESET`, el cambio se habría quedado pendiente y en el siguiente reinicio la instancia habría arrancado con `db_files = 250` sin que nadie lo hubiera planeado para ese momento: un cambio escondido que aparece cuando menos se espera.

Evidencia: `script/20261119T112541Z_02-parametros.script.log`, secciones 4 y 5.

### Pregunta 4

`RESET` borra la línea del parámetro en el SPFILE y lo devuelve a su valor por defecto. Para `db_files` era la vuelta atrás correcta porque nunca se había fijado: en la copia de seguridad que hice antes de tocar nada (el PFILE creado desde el SPFILE) **no hay ninguna línea `*.db_files`**, así que «sin fijar» era exactamente el estado original. Para `processes` no lo habría sido, porque en esa misma copia está la línea **`*.processes=200`**: alguien lo fijó a propósito. Un `RESET` quitaría esa línea y Oracle usaría su valor por defecto, que no tiene por qué ser 200, así que no volvería al estado anterior. La vuelta atrás correcta para `processes` sería `ALTER SYSTEM SET processes = 200 SCOPE = SPFILE`.

Evidencia: `config/20261119T112542Z_02-init_desde_spfile.ora` (línea `*.processes=200`, sin línea de `db_files`) y `script/20261119T112541Z_02-parametros.script.log`, sección 6.

### Pregunta 5

Tras el reinicio sin estado guardado, C##OPS_RO intentó entrar por el servicio `freepdb1` y obtuvo **`ORA-01109: database not open`**. La instancia decía «Database opened» porque `STARTUP` abre la instancia y el CDB (la raíz, `CDB$ROOT`), pero las PDB se abren por separado: sin un estado guardado, FREEPDB1 se quedó en **`MOUNTED`** (`ESTADO_GUARDADO = (sin estado guardado)`). El listener conocía el servicio `freepdb1`, pero la PDB que hay detrás no estaba abierta, de ahí el `ORA-01109`. Si la aplicación hubiera entrado por su propio servicio (`academia_app`), habría recibido `ORA-12514`, porque ese servicio no arranca hasta que la PDB se abre. Por eso «la base está arriba» no basta: hay que comprobarlo PDB por PDB y por el camino del consumidor. En la sección 5 abrí FREEPDB1, guardé su estado con `SAVE STATE` y, tras otro reinicio, arrancó sola en `READ WRITE` con `ESTADO_GUARDADO = OPEN`.

Evidencia: `script/20261119T112912Z_02-estados-pdb.script.log`, secciones 4 y 5.

### Partes D-E

### Pregunta 6

La sesión de la aplicación es SID 38, SERIAL# 54880, con proceso servidor SPID 5055 (`oracleFREE (LOCAL=NO)`). Es un proceso dedicado que llegó por red a través del servicio `academia_app`. Estaba en el evento `PL/SQL lock timer`, es decir, esperando dentro de `DBMS_SESSION.SLEEP`, no bloqueada por otra sesión.

USERNAME solo muestra `APP_ACADEMIA`, que es la cuenta compartida por todos los usuarios de la aplicación. MODULE (`matriculas`) y ACTION (`cierre-periodo`) dicen qué parte de la aplicación y qué operación se está ejecutando. CLIENT_IDENTIFIER (`ana.garcia@ucam`) dice qué persona real hay detrás. Con estos datos sé a quién afecta antes de cancelar o matar la sesión.

Evidencia: `script/20261119T114008Z_03-sesiones.script.log`, sección 3.

### Pregunta 7

Después de `ALTER SYSTEM CANCEL SQL` la sesión siguió viva. Se cortó la llamada en curso (la aplicación recibió ORA-01013), pero quedó 1 transacción abierta porque el UPDATE no se había confirmado ni deshecho, y la aplicación respondió «sigo viva».

Después de `ALTER SYSTEM KILL SESSION` quedaron 0 sesiones de la aplicación. El ORA-00031 (marked for kill) es esperado: la sesión estaba dentro de una llamada y Oracle la terminó en cuanto pudo. La aplicación recibió ORA-00028 y después ORA-03114. Oracle deshizo con el undo el UPDATE pendiente (USED_UREC = 1), así que la fila 101 volvió a `ACTIVO`. El alert log registra que la sesión la terminó SYS desde sqlplus.

La diferencia es que CANCEL para la sentencia pero deja la transacción abierta, y KILL termina la sesión y hace rollback de lo que no estaba confirmado.

Evidencia: `script/20261119T114008Z_03-sesiones.script.log`, secciones 4 y 5.

### Pregunta 8

`common_user_prefix` vale `C##`. Los usuarios comunes, que existen en todos los contenedores, tienen que llevar ese prefijo, como `C##OPS_RO`. `APP_ACADEMIA` no lo lleva porque es un usuario local de FREEPDB1 (`COMMON = NO`): se crea dentro de la PDB y solo existe allí.

Evidencia: `script/20261119T113953Z_03-cuenta-app.script.log`.

### Pregunta 9

| Vista | C##OPS_RO en la raíz | C##OPS_RO en FREEPDB1 | APP_ACADEMIA |
|---|---|---|---|
| ALL_TABLES de ADMIN_ACADEMIA | 0 | 0 | 1 |
| DBA_USERS | 37 | 47 | ORA-00942 |
| CDB_USERS | con_id 1: 37, con_id 3: 47 | con_id 3: 47 | ORA-00942 |
| V$DATAFILE | 17 | 10 | ORA-00942 |

Una diferencia: C##OPS_RO lanza la misma consulta sobre V$DATAFILE y obtiene 17 datafiles desde la raíz y 10 desde FREEPDB1. Las vistas V$ se filtran por el contenedor desde el que miras: en la raíz, gracias a CONTAINER_DATA = ALL, ve también los datafiles de la raíz y de PDB$SEED; dentro de la PDB solo ve los suyos. Lo mismo pasa con CDB_USERS: desde la raíz salen la raíz y FREEPDB1, y desde la PDB solo FREEPDB1. APP_ACADEMIA no tiene privilegios de catálogo, así que DBA_, CDB_ y V$ le devuelven ORA-00942. En cambio, ve 1 tabla de ADMIN_ACADEMIA en ALL_TABLES porque tiene permiso sobre esa tabla. C##OPS_RO no ve ninguna, porque SELECT_CATALOG_ROLE deja leer el catálogo pero no los datos. Ninguna de las tres miradas está equivocada: cada una ve lo que le permiten su identidad y su contenedor.

Evidencia: `script/20261119T160939Z_04-tres-miradas.script.log`.

### Pregunta 10

La carga de 10 recorridos completos de PEDIDO hizo 53.870 lecturas lógicas, es decir, 5.387 por recorrido, que son aproximadamente los bloques que ocupa la tabla. Costó 0,35 s de DB time, de los que 0,32 s fueron DB CPU, con 0,34 s de tiempo de reloj.

DB time y DB CPU son casi iguales (alrededor del 91 % del DB time fue CPU). Eso indica que la carga apenas esperó: los bloques de PEDIDO estaban en el buffer cache y todo fue trabajo de CPU. Si el DB time hubiera sido mucho mayor que el DB CPU, la diferencia serían esperas, por ejemplo de E/S o de bloqueos. Los 0,9 s de User I/O de la sección 5 no son de esta carga: son acumulados desde el arranque, con la caché todavía fría.

Evidencia: `script/20261119T161205Z_04-deltas.script.log`, secciones 4 y 5.

### Partes F-G

### Pregunta 11

Antes de la carga, TBS_ACADEMIA_HIST tenía 10 MB asignados, 3,9 MB libres dentro de lo asignado y un máximo alcanzable de 40 MB gracias a AUTOEXTEND con techo. Sobre ese máximo estaba al 15,16 % (776 de 5120 bloques).

Para alertar usaría el porcentaje sobre el máximo. Con AUTOEXTEND, el libre dentro de lo asignado engaña: puede estar casi a cero y el tablespace seguir creciendo hasta 40 MB. Lo que de verdad indica que se va a llenar es cuánto queda hasta el techo. Es la medida de DBA_TABLESPACE_USAGE_METRICS, y sobre ella quedó configurado el umbral de aviso del 80 % y el crítico del 95 %.

Evidencia: `script/20261119T162222Z_05-almacenamiento.script.log`, secciones 2 y 7.

### Pregunta 12

En el ORA-01950 insertó SYS, desde el script SYSDBA, pero quien «pagaba» era CARGA_HIST. La cuota la paga el dueño del segmento, no quien inserta, y CARGA_HIST no tenía ninguna cuota en TBS_ACADEMIA_HIST.

Ampliar el tablespace no habría resuelto el ORA-01536 porque el límite era la cuota de 2 MB de CARGA_HIST (MAX_BYTES 2097152), no el espacio del tablespace. TBS_ACADEMIA_HIST todavía podía crecer hasta 40 MB. Lo que faltaba no era sitio, sino permiso del dueño para usar más.

Evidencia: `script/20261119T162222Z_05-almacenamiento.script.log`, secciones 4 y 5.

### Pregunta 13

La aplicación lanzó la carga a las 16:22:31 y terminó a las 16:22:45, es decir, 14 s en total. Casi todo ese tiempo, unos 12-13 s, la sentencia estuvo suspendida. CDB_RESUMABLE la mostraba como SUSPENDED con el ORA-01536 pendiente, y la sesión 176 de APP_ACADEMIA esperaba en el evento `statement suspended, wait error to be cleared`. Cuando se amplió la cuota de CARGA_HIST a 30 MB, la carga se reanudó sola y terminó con las 20.000 filas.

Oracle dejó en el alert log dos líneas: `statement in resumable session 'carga-historico' was suspended due to` y `statement in resumable session 'carga-historico' was resumed`.

Evidencia: `script/20261119T162230Z_05-resumable.script.log`, secciones 2 a 4.

### Pregunta 14

Antes del DELETE, la tabla tenía 20.000 filas, 2944 bloques y 23 MB, con 23 MB de cuota consumida. Después del DELETE quedaban 2000 filas, pero seguían los mismos 2944 bloques y 23 MB, y la cuota consumida no bajó. Después del SHRINK SPACE quedaron 2000 filas en 304 bloques, 2,4 MB, y la cuota consumida bajó a 2,4 MB.

El DELETE no devolvió el espacio porque borra filas, pero los bloques siguen asignados al segmento por debajo de la marca de agua alta (HWM). Quedan medio vacíos y un recorrido completo los sigue leyendo todos. SHRINK SPACE mueve las filas para compactarlas (por eso exige ROW MOVEMENT), baja la HWM y libera los bloques sobrantes.

Evidencia: `script/20261119T162408Z_05-hwm-shrink.script.log`.

### Pregunta 15

El perfil DEFAULT de mi imagen tenía: FAILED_LOGIN_ATTEMPTS 10, PASSWORD_LOCK_TIME 1 (un día), PASSWORD_LIFE_TIME 180, PASSWORD_GRACE_TIME 7, INACTIVE_ACCOUNT_TIME 365, PASSWORD_REUSE_MAX y PASSWORD_REUSE_TIME UNLIMITED, PASSWORD_ROLLOVER_TIME 0 y PASSWORD_VERIFY_FUNCTION NULL. Es decir, sin ninguna comprobación de complejidad de contraseña.

Dos límites de PRF_PERSONAS para una persona de secretaría:

- FAILED_LOGIN_ATTEMPTS 3: una persona que conoce su contraseña no necesita diez intentos. Con tres se corta un ataque de adivinación y Ana solo tiene que avisar si se equivoca. En la prueba, tres contraseñas erróneas dejaron la cuenta en LOCKED(TIMED), y la correcta ya no entró (ORA-28000) hasta que el DBA la desbloqueó. El bloqueo de 1 minuto es solo para el laboratorio: en producción sería un día o un desbloqueo manual tras confirmar la identidad por otro canal.
- PASSWORD_VERIFY_FUNCTION ora12c_verify_function: obliga a usar contraseñas complejas desde la propia base de datos, sin depender de que cada persona elija bien. La contraseña «corta» se rechazó con ORA-28003 (menos de 8 caracteres). Con el perfil DEFAULT, que tiene la función a NULL, se habría aceptado.

Evidencia: `script/20261119T163441Z_06-gobierno-acceso.script.log`, secciones 1 y 2, y `script/20261119T163451Z_06-probar-acceso.script.log`, sección 3.

### Pregunta 16

Ana pudo leer ACA_MATRICULAS (60.000 filas) por una cadena de roles. Tiene ROL_SECRETARIA_ACADEMIA, este rol incluye ROL_LECTURA_ACADEMIA, y ROL_LECTURA_ACADEMIA tiene el privilegio de esquema SELECT ANY TABLE ON SCHEMA admin_academia. Ese privilegio, nuevo en 23ai, permite leer todas las tablas de ADMIN_ACADEMIA, incluidas las que se creen más adelante, pero solo las de ese esquema. Por eso no hizo falta concederle ACA_MATRICULAS por nombre.

Al intentar cambiar el nombre de un alumno obtuvo ORA-41900: missing UPDATE privilege on "ADMIN_ACADEMIA"."ACA_ESTUDIANTES". Secretaría solo tiene un privilegio de columna, UPDATE (estado): puede cambiar el estado de un estudiante, pero no el nombre. Tampoco puede borrar, y el DELETE dio el mismo error por falta del privilegio DELETE.

Evidencia: `script/20261119T163451Z_06-probar-acceso.script.log`, sección 1, y `script/20261119T163441Z_06-gobierno-acceso.script.log`, sección 6.

### Partes H-I

### Pregunta 17

Con la columna nueva no se invalidó nada. Oracle registra las dependencias a nivel de columna (dependencia de grano fino): ni las vistas ni la función usaban esa columna, así que añadirla no les afecta.

Al ampliar email_institucional se invalidó solo V_CONTACTO_LAB6, que es la única que usa esa columna. V_ACTIVOS_LAB6 y F_TOTAL_ACTIVOS_LAB6 siguieron VALID.

Al ampliar nombres se invalidó V_ACTIVOS_LAB6, que usa esa columna, y en cascada F_TOTAL_ACTIVOS_LAB6. La función no depende de la tabla, sino de la vista: la cadena es F_TOTAL_ACTIVOS_LAB6 → V_ACTIVOS_LAB6 → ACA_EST_LAB6. V_CONTACTO_LAB6 seguía INVALID desde el cambio anterior.

Ninguno de estos cambios dio error. Cuando un usuario llamó a la función, Oracle la recompiló sola en su llamada y devolvió 17.600 activos, pero V_CONTACTO_LAB6 siguió inválida hasta que se recompiló el esquema. Por eso el DBA recompila antes de abrir el servicio, en lugar de esperar a que un usuario tropiece en hora punta. Al final quedaron 0 objetos inválidos en los esquemas de negocio.

Evidencia: `script/20261119T164126Z_07-objetos.script.log`, secciones 2 a 6 y 9.

### Pregunta 18

No. Según V$SGA_TARGET_ADVICE, duplicar la SGA de 1536 MB a 3072 MB no mejoraría el DB time: ESTD_DB_TIME_FACTOR vale 1 en todos los tamaños, y las lecturas físicas estimadas se quedan en 28.507 desde 1152 MB hacia arriba. Solo bajando a 768 MB subirían un poco (30.300), y aun así sin cambiar el DB time. Con la carga actual, más SGA sería memoria desperdiciada.

En la PGA, según V$PGA_TARGET_ADVICE, habría sobreasignaciones por debajo de 384 MB: con 256 MB y con 128 MB la estimación es de 4 sobreasignaciones y un 84 % de aciertos en caché. Desde 384 MB son 0, con un 100 % de aciertos. El objetivo actual es de 512 MB, con over allocation count 0 y un 100 % de aciertos, así que está bien dimensionado y con margen.

Evidencia: `script/20261119T164133Z_07-memoria.script.log`, secciones 3 y 5.

### Pregunta 19

La consulta de la aplicación (SELECT COUNT(*) ... WHERE estado = 'ACTIVO') necesitó 247 lecturas lógicas. En la traza en bruto lo dice la línea FETCH del cursor de esa consulta: `FETCH #128684207912576:c=0,e=2649,p=0,cr=247,cu=0,...,r=1`. Ahí cr=247 son las lecturas consistentes, cu=0 las lecturas en modo actual y p=0 indica que ningún bloque se leyó de disco. tkprof da la misma cifra: 247 en la columna query de la fila Fetch, con disk 0.

La línea EXEC con cr=285 y e=8003159 no es la consulta: pertenece a otro cursor, el bloque PL/SQL que incluye la espera de unos 8 segundos (WAIT nam='PL/SQL lock timer').

Evidencia: `script/20261119T164155Z_07-adr-trazas.script.log`, sección 5.

### Pregunta 20

- INC-601: evidencia clave, la sesión 213 de Ana en "enq: TX - row lock contention" con BLOQ = 19 (APP_ACADEMIA, matriculas/cierre-periodo, dormida, 1 registro de undo). Intervención: ALTER SYSTEM KILL SESSION '19,38818' IMMEDIATE. Validación: alumno 101 en ACTIVO y secciones 1 a 4 del diagnóstico vacías.
- INC-602: evidencia clave, academia_app con ARRANCADO = NO en la sección 6, y la base abierta sin reinicio (arranque 16:08:30). Intervención: DBMS_SERVICE.START_SERVICE('academia_app') y SAVE STATE de FREEPDB1. Validación: app.sh conecta por academia_app y el servicio sale SI.
- INC-603: evidencia clave, APP_ACADEMIA en LOCKED (no LOCKED(TIMED)) a las 17:11, con perfil DEFAULT y 10 intentos. Intervención: ALTER USER app_academia ACCOUNT UNLOCK, sin cambiar la contraseña. Validación: cuenta en OPEN, app.sh conecta y la sección 7 queda vacía.

Evidencia: `script/20261119T165700Z_08-inc601.script.log`, `script/20261119T170333Z_08-inc602.script.log`, `script/20261119T171257Z_08-inc603.script.log`, las evidencias 08-inc602-antes/despues y 08-inc603-antes/despues, y los 08-diagnostico de antes y después de cada intervención.

## Simulacro 1Z0-182

| Pregunta | Respuesta | Dónde lo comprobé |
|---|---|---|
| S1 | B | Parte F: umbral de alerta de TBS_ACADEMIA_HIST (lo vigila MMON) |
| S2 | C | Parte C: sort_area_size es DEFERRED |
| S3 | B | Parte C: init_desde_memoria.ora (126 líneas frente a 35) |
| S4 | B, C | Parte C: OPEN READ WRITE sobre una PDB ya abierta dio ORA-65019 |
| S5 | C | Parte C: estado guardado de FREEPDB1 (SAVE STATE) |
| S6 | B | Parte C: C.2 sección 3, C##OPS_RO recibió ORA-01035 con FREEPDB1 en RESTRICTED |
| S7 | A | Parte D: creación de academia_app; Parte I, INC-602 |
| S8 | B | Parte D: SPID de la sesión de la aplicación |
| S9 | C | Parte D: tras CANCEL SQL seguía 1 transacción abierta |
| S10 | C | Parte D: escalera de privilegios, USER is "PUBLIC" |
| S11 | B | Parte E: 04-deltas, sección 1 |
| S12 | A, C | Parte E: DB time frente a DB CPU |
| S13 | B | Parte F: ORA-01950, insertó SYS y pagaba CARGA_HIST |
| S14 | A, C | Parte F: ORA-30041 sobre TEMP |
| S15 | A, C | Parte F: carga reanudable en SUSPENDED (CDB_RESUMABLE) |
| S16 | B | Parte F: ENABLE ROW MOVEMENT antes del SHRINK |
| S17 | B | Parte G: Ana en LOCKED(TIMED) tras tres fallos |
| S18 | B | Parte G: cascada, el CREATE SESSION de U6_B sobrevive |
| S19 | A, B | Parte H: el MOVE dejó IX_EST_LAB6_ESTADO en UNUSABLE |
| S20 | B | Parte H: traza de la sesión de la aplicación (07-adr-trazas) |
| S21 | C | Parte H: ADR Base /opt/oracle (diagnostic_dest en el PFILE) |
| S22 | C | Parte I: INC-601, identificar al bloqueador antes de actuar |
