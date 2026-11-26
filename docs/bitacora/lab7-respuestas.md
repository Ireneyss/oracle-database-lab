# Laboratorio 7 · Respuestas · E066

<!--
CÓMO SE RELLENA
- Copia este archivo como docs/bitacora/lab7-respuestas.md y pon tu código en el título.
- Responde con TUS números: cada respuesta cita el archivo de evidencia de donde sale (docs/bitacora/lab7/evidencia/...).
  Una cifra sin evidencia no puntúa. Las cifras del PPTX son de referencia: las tuyas serán parecidas, no iguales.
- 3 a 6 líneas por pregunta. No pegues salidas enteras: el archivo de evidencia ya las tiene.
- No borres los títulos: scripts/lab7/09-verificacion-final.sh comprueba que están todos.
-->
## Parte B · C01 · Más sesiones no es más rendimiento
1. ¿Cuántas llamadas por segundo y qué p95 tuviste con 1, 2 y 8 sesiones? ¿Qué número de sesiones recomiendas y por qué?

Con 1 sesión saqué 5,9 llamadas/s con una p95 de 171 ms, con 2 sesiones 11,4 llamadas/s y 217 ms, y con 8 sesiones 12,3 llamadas/s pero con una p95 de 1.128 ms. O sea, al pasar de 2 a 8 sesiones casi no gané throughput (un 8 % más) y la latencia se multiplicó por 5. Yo dejaría el pool en 2 sesiones, que es lo que vale CPU_COUNT: con eso se atiende prácticamente lo mismo y cada usuario espera mucho menos.

Evidencia: `casos/20261125T200359Z_C01_entender.txt` y `casos/20261126T081614Z_C01_validar.txt`.

2. ¿Qué evento domina con 8 sesiones y qué significa en Oracle Free?

Con 8 sesiones manda resmgr:cpu quantum, con el 74,6 % de las muestras de ASH (232 de 311), y solo el 25,4 % era trabajo real en CPU. Es la espera de turno de CPU que pone el gestor de recursos, que en Oracle Free limita la instancia a 2 CPU. Lo confirma el AAS: 7,6 sesiones activas de media con solo 2 CPU, así que lo que pasaba de 2 era cola, no trabajo.

Evidencia: `casos/20261125T200641Z_C01_diagnosticar.txt`.

3. Comprueba la ley de Little (N = X · R) con tus tres medidas.

Con 1 sesión: 5,9 llamadas/s × 0,166 s = 1,0. Con 2 sesiones: 11,4 × 0,173 = 2,0. Con 8 sesiones: 12,3 × 0,643 = 7,9. En los tres casos sale el número de sesiones. Lo interesante es que de 2 a 8 el throughput casi no sube, así que para que la cuenta cuadre la latencia media tiene que crecer (de 173 a 643 ms). Ese tiempo de más es la cola esperando CPU.

Evidencia: `casos/20261126T081707Z_C01_observar.txt`.

## Parte C · C03 · Literales y análisis completos
1. Análisis completos y tiempo con literales, con variables de enlace y con CURSOR_SHARING = FORCE (tus cifras).

Con literales, las 5.000 fichas tardaron 5.090 ms (1,02 ms cada una) e hicieron 5.074 hard parses, prácticamente uno por ficha. El 87 % del tiempo se fue en analizar (4.410 ms), no en leer la fila. Con variables de enlace bajó a 170 ms y 31 hard parses, unas 30 veces más rápido, y en la shared pool quedó un solo cursor. Con CURSOR_SHARING = FORCE y la misma versión de literales tardó 200 ms con 28 hard parses: casi como con variables. Un detalle de mi base: al acabar la carga con literales solo quedaban 538 cursores de los 5.074 y unos segundos después ninguno, porque Oracle los iba expulsando de la shared pool al no reutilizarse.

Evidencia: `casos/20261126T083553Z_C03_diagnosticar.txt`, `casos/20261126T083626Z_C03_validar.txt` y `casos/20261126T083738Z_C03_observar.txt`.

2. ¿Por qué FORCE es un puente y no la solución? ¿Qué ve el DBA en V$SQL que lo delata (FORCE_MATCHING_SIGNATURE)?

Es un puente porque arregla el síntoma sin tocar la causa: la aplicación sigue concatenando el id, y si se quita el parámetro vuelve el problema. Además cambia todos los literales de la sesión, servicio o PDB, también los que se ponen a propósito para que el optimizador vea el valor y elija el plan, así que puede estropear otras consultas. Lo bueno es que deja rastro: en V$SQL vi un solo cursor (bba34k3qhx6j7) con 5.000 ejecuciones y el texto WHERE id_cliente = :"SYS_B_0", una variable que no escribió nadie. Sin el parche, lo que delata a la aplicación son miles de SQL_ID con una sola ejecución que comparten la misma FORCE_MATCHING_SIGNATURE. En mi caso la firma salió vacía en el diagnóstico porque los cursores ya se habían expulsado, pero los 5.074 hard parses para 5.000 llamadas dicen lo mismo.

Evidencia: `casos/20261126T083738Z_C03_observar.txt` y `casos/20261126T083553Z_C03_diagnosticar.txt`.


## Parte C · C04 · El informe que se desborda a TEMP
1. Bloques de TEMP, tipo de pasada y tiempo del informe antes y después. ¿Qué hacía el disparador de logon?

Antes, el ranking completo de 1.000.000 de pedidos tardaba 1.560 ms y escribía y leía 5.456 bloques en TEMP (42,6 MB). La ordenación necesitaba 48 MB pero solo pudo usar 1.016 KB, así que dio una pasada por disco (1 PASS) con 43 MB de TEMP. El culpable era el disparador T6.C04_LEGADO, AFTER LOGON sobre la cuenta T6_INF: en cada inicio de sesión ponía workarea_size_policy = MANUAL y sort_area_size = 1 MB, así que la sesión ignoraba la PGA automática aunque la instancia permitía hasta 100 MB por área de trabajo. Después de borrar el disparador, el mismo informe completo bajó a 810 ms, con 0 bloques de TEMP y en memoria (OPTIMAL, 63,7 MB). Y pidiendo solo las 100 filas que se ven en pantalla, 90 ms y 0 bloques.

Evidencia: `casos/20261126T091530Z_C04_diagnosticar.txt`, `casos/20261126T091653Z_C04_solucionar.txt` y `casos/20261126T091654Z_C04_validar.txt`.

2. ¿Por qué el TOP 100 cabe en memoria y el informe completo no?

Porque para devolver el informe completo hay que ordenar el millón de filas entero antes de dar la primera: la ordenación es bloqueante y necesita tener todo en el área de trabajo (en mi caso, entre 48 y 64 MB). Con FETCH FIRST 100 ROWS ONLY Oracle hace un TOP-N (SORT ORDER BY STOPKEY): va recorriendo los pedidos y solo se queda con los 100 de más importe, descartando el resto sobre la marcha. Por eso necesitó prácticamente 0 MB (unos pocos KB) y fue OPTIMAL. Me quedo con la idea de que reducir antes de ordenar vale más que ordenar con más memoria: 90 ms frente a los 810 ms del completo ya sin disparador.

Evidencia: `casos/20261126T091806Z_C04_observar.txt` y `casos/20261126T091653Z_C04_solucionar.txt`.


## Parte D · C07 · EXPLAIN PLAN frente al plan real
1. Copia el predicado que delata el problema en el plan real y explica de dónde sale.

En el plan real del cursor de la V1 (DISPLAY_CURSOR del SQL_ID 0dbx7196jdajy) sale: 2 - filter(TO_NUMBER("CODIGO_POSTAL")=:B1), con TABLE ACCESS FULL sobre PEDIDO. Sale de una conversión implícita: la V1 pasa el código postal como NUMBER (en Peeked Binds aparece :B1 (NUMBER): 30038), pero la columna es VARCHAR2(5). Para poder comparar, Oracle convierte la columna a número, y al tener una función sobre la columna el índice IX_T6_PED_CP (que guarda texto) ya no sirve. El propio plan lo avisa en el SQL Analysis Report. En observar vi lo mismo con fechas: comparar FECHA_PEDIDO (DATE) con SYSTIMESTAMP mete un INTERNAL_FUNCTION sobre la columna y hace TABLE ACCESS FULL, mientras que con SYSDATE usa IX_T6_PED_FECHA.

Evidencia: `casos/20261126T092145Z_C07_diagnosticar.txt` y `casos/20261126T092222Z_C07_observar.txt`.

2. Lecturas y p95 de V1 y V2. ¿Por qué EXPLAIN PLAN no lo vio?

Con la V1 cada búsqueda hacía 5.228 lecturas lógicas y la p95 de la web era de 58,3 ms. Con la V2, que recibe el código postal con el mismo tipo que la columna, bajó a 121 lecturas (unas 43 veces menos) y 1,5 ms de p95, usando INDEX RANGE SCAN. EXPLAIN PLAN no lo vio porque no ejecuta la consulta: trata la variable como texto sin mirar qué tipo ni qué valor va a llegar, así que no añade la conversión y predice el índice (coste 94). El plan real sí sabe que llegó un NUMBER, por eso es el que hay que mirar.

Evidencia: `casos/20261126T092144Z_C07_entender.txt`, `casos/20261126T092147Z_C07_solucionar.txt` y `casos/20261126T092148Z_C07_validar.txt`.


## Parte D · C08 · E-Rows frente a A-Rows
1. Estimación y filas reales antes y después del grupo de columnas. ¿En qué línea del plan se separan por primera vez?

Leyendo el plan real de dentro afuera, la primera línea que se separa es la 3 (TABLE ACCESS BY INDEX ROWID BATCHED sobre CLIENTE, con el filtro COMUNIDAD = 'COM09'): estimaba 3 clientes y salieron 56. La línea 4, solo con la ciudad, estaba bien (50 estimadas, 56 reales), y la 5 también si multiplicas por Starts (10 × 56 = 560, salieron 599). Lo de arriba heredó el error: la línea 1 estimaba 28 pedidos y salieron 599. Después de crear el grupo de columnas (CIUDAD, COMUNIDAD) y recoger estadísticas, la línea 3 estima 50 (reales 56) y la línea 1, 496 (reales 599). El plan es el mismo porque es pequeño; lo que se arregla es la estimación.

Evidencia: `casos/20261126T092612Z_C08_diagnosticar.txt`, `casos/20261126T092613Z_C08_solucionar.txt` y `casos/20261126T092615Z_C08_validar.txt`.

2. ¿Por qué el optimizador multiplicaba mal las dos selectividades?

Porque supone que las columnas son independientes: hay 2.000 ciudades y 18 comunidades, así que calcula 100.000 × 1/2.000 × 1/18 ≈ 2,9 clientes. Pero cada ciudad está en una sola comunidad (MAX_COMUNIDADES_POR_CIUDAD = 1): si ya sé que el cliente es de Ciudad0042, el filtro de COM09 no quita a nadie, y el optimizador lo cuenta como si dividiera otra vez entre 18. Un índice o un histograma no lo arreglan porque miran cada columna por separado. El grupo de columnas crea una columna virtual oculta (SYS_STUBJHRJ63BYYQ61EBQAQU2TM_) que cuenta las combinaciones distintas: 2.000, así que la estimación pasa a ser 100.000 / 2.000 = 50.

Evidencia: `casos/20261126T092611Z_C08_entender.txt` y `casos/20261126T093028Z_C08_observar.txt`.


## Parte E · C12 · Estadísticas obsoletas
1. Filas según las estadísticas y reales; método de unión y lecturas antes y después.

Según las estadísticas, CARRITO tenía 100 filas y en realidad había 200.100, porque la carga nocturna metió 200.000 y nadie recogió al terminar (STALE = YES y 200.000 inserciones en DBA_TAB_MODIFICATIONS). Con esa estimación el optimizador eligió NESTED LOOPS: E-Rows 100 en CARRITO, pero salieron 200.000, así que hizo 200.000 búsquedas por la PK de PEDIDO y 200.000 accesos a la tabla, 212.196 lecturas lógicas en total. Después de recoger solo CARRITO con GATHER_TABLE_STATS y no_invalidate => FALSE, las estadísticas quedaron en 200.100 filas y STALE = NO, el plan pasó a HASH JOIN con un solo recorrido de PEDIDO y CARRITO, y el informe bajó a 5.907 lecturas, unas 36 veces menos. En tiempo la diferencia fue pequeña en mi equipo (177 ms frente a unos 150 ms) porque todo estaba en caché, pero el trabajo real cayó muchísimo.

Evidencia: `casos/20261126T093547Z_C12_entender.txt`, `casos/20261126T093548Z_C12_diagnosticar.txt`, `casos/20261126T093549Z_C12_solucionar.txt` y `casos/20261126T093550Z_C12_validar.txt`.

2. ¿Por qué la tarea automática no lo habría arreglado a tiempo? ¿Quién debe recoger y cuándo?

La tarea automática (auto optimizer stats collection, ENABLED) solo recoge dentro de las ventanas de mantenimiento, por la noche (en mi base, THURSDAY_WINDOW a las 22:00 durante 4 horas), y solo las tablas que han cambiado más de un 10 % (STALE_PERCENT). Si la carga termina después de la ventana, el informe de primera hora llega antes que la tarea y se ejecuta con las estadísticas viejas. En mi caso además se ve que WEDNESDAY_WINDOW se quedó en 25-11 a las 22:00 porque esa noche tenía el contenedor apagado, así que la tarea ni se ejecutó. Quien debe recoger es el propio proceso que carga: al terminar la carga, un GATHER_TABLE_STATS de la tabla que ha cambiado, como dice el runbook RB-2.

Evidencia: `casos/20261126T093820Z_C12_observar.txt`.

## Parte E · C13 · El ciclo de estadísticas con red
1. Describe el ciclo que seguiste (pendientes, probar, publicar, restaurar, bloquear) con la vista que comprueba cada paso.

Partí de STALE = YES con 135.277 actualizaciones y ESTADO sin histograma, así que el optimizador estimaba 250.000 pedidos E (un millón entre 4 estados) y había 185.277. Primero puse PUBLISH = FALSE y recogí con histograma en ESTADO: en DBA_TAB_PENDING_STATS apareció la fila pendiente (09:45:23) mientras DBA_TAB_STATISTICS seguía con las publicadas de antes. Luego las probé solo en mi sesión con optimizer_use_pending_statistics = TRUE y un EXPLAIN PLAN: en PLAN_TABLE la estimación salió 185.277, igual que las reales. Como era buena, publiqué con PUBLISH_PENDING_STATS y devolví PUBLISH a TRUE: DBA_TAB_STATISTICS pasó a STALE = NO, DBA_TAB_PENDING_STATS quedó vacía y ESTADO tiene histograma FREQUENCY. Para restaurar, DBA_TAB_STATS_HISTORY guarda las recogidas anteriores (31 días de retención) y con RESTORE_TABLE_STATS a hace 60 segundos ESTADO volvió a NONE en DBA_TAB_COL_STATISTICS. Por último bloqueé con LOCK_TABLE_STATS y DBA_TAB_STATISTICS mostró STATTYPE_LOCKED = ALL.

Evidencia: `casos/20261126T094455Z_C13_diagnosticar.txt`, `casos/20261126T094527Z_C13_solucionar.txt`, `casos/20261126T094528Z_C13_validar.txt` y `casos/20261126T094615Z_C13_observar.txt`.

2. ¿Qué error obtuviste al recoger sobre estadísticas bloqueadas y cómo se recoge si de verdad hace falta?

Al lanzar GATHER_TABLE_STATS sobre PEDIDO con las estadísticas bloqueadas salió ORA-20005: object statistics are locked (stattype = ALL). Es lo que se busca al bloquear una tabla de trabajo que se vacía y se llena: que ni la tarea automática ni nadie le cambie unas estadísticas representativas sin querer. Si de verdad hace falta recoger, hay dos formas conscientes: llamar a GATHER_TABLE_STATS con force => TRUE, o desbloquear con UNLOCK_TABLE_STATS, recoger y volver a bloquear con LOCK_TABLE_STATS. En el caso se desbloqueó con UNLOCK_TABLE_STATS antes de dejar PEDIDO como estaba.

Evidencia: `casos/20261126T094615Z_C13_observar.txt`.

## Parte E · C14 · El índice invisible
1. Lecturas por apertura del panel antes y después. ¿Cómo probaste el índice sin que lo viera nadie más?

Antes, cada apertura del panel hacía 5.266 lecturas lógicas y tardaba 25,6 ms, porque recorría la tabla entera (TABLE ACCESS FULL) para mostrar solo 2.056 pedidos de un millón. Ninguno de los índices de PEDIDO combinaba estado, canal y fecha. Creé el índice (estado, canal, fecha_pedido) con las igualdades primero y el rango al final, como INVISIBLE y ONLINE: en una sesión normal el EXPLAIN PLAN seguía dando TABLE ACCESS FULL, así que nadie más cambiaba de plan. Lo probé solo en mi sesión con optimizer_use_invisible_indexes = TRUE y el plan real pasó a INDEX RANGE SCAN sobre IX_T6_C14_PEND con 116 lecturas y las mismas 2.056 filas. Como la prueba era buena lo hice VISIBLE, y el panel quedó en 118 lecturas y 0,32 ms por apertura, unas 45 veces menos lecturas.

Evidencia: `casos/20261126T104946Z_C14_entender.txt`, `casos/20261126T104948Z_C14_diagnosticar.txt`, `casos/20261126T104952Z_C14_solucionar.txt` y `casos/20261126T104954Z_C14_validar.txt`.

2. Redo con el índice INVISIBLE y VISIBLE: ¿qué demuestra?

Cambiar el canal de 20.000 pedidos generó 9.007 KB de redo sin mantener el índice (UNUSABLE), 10.403 KB con el índice INVISIBLE y 10.403 KB con él VISIBLE. Es decir, invisible y visible cuestan exactamente lo mismo al escribir: unos 1.400 KB más, alrededor de un 15 %. Demuestra que INVISIBLE solo afecta al optimizador, que no lo usa, pero Oracle lo sigue manteniendo en cada INSERT, UPDATE o DELETE para que esté al día si se vuelve a hacer visible. Por eso la marcha atrás con ALTER INDEX ... INVISIBLE es inmediata, pero un índice que no se usa sigue costando en cada escritura y al final hay que borrarlo.

Evidencia: `casos/20261126T105111Z_C14_observar.txt`.

## Parte F · C17 · INC-604 con AWR, ASH y ADDM
1. SLI y SLO; p95 antes y después; instantáneas AWR que usaste.

El SLI es la latencia p95 de la búsqueda por código postal medida en la telemetría de la web (T6.APP_LOG), y el SLO acordado es p95 < 20 ms. Con la V1 y 3 sesiones durante 120 s la p95 fue de 82,1 ms, así que incumplía el SLO, y se atendieron 4.078 búsquedas. Con la V2 y la misma carga la p95 bajó a 1,02 ms y se atendieron 31.781 búsquedas. Para comparar usé dos intervalos AWR: el 19 → 20 (11:04 a 11:06) con la V1 y el 23 → 24 (11:18 a 11:20) con la V2. Con los deltas de AWR, las lecturas por ejecución pasaron de 5.125 a 94. La primera validación con la V2 (intervalo 21 → 22) dio dos FALLO porque el cursor desaparecía de la shared pool nada más terminar la carga; tuve que fijar shared_pool_size = 640M y repetirla, y entonces salieron las cinco comprobaciones en OK.

Evidencia: `casos/20261126T110630Z_C17_entender.txt`, `casos/20261126T112010Z_C17_validar.txt`, `casos/20261126T112047Z_C17_observar.txt` y `herramientas/20261126T111759Z_ajuste-shared-pool.txt`.

2. ¿Qué dijeron ASH, AWR y ADDM, y qué no podían decirte? ¿Cuál fue el ÚNICO cambio?

ASH me dijo quién y en qué: la sentencia 0dbx7196jdajy acumulaba 236 muestras ON CPU y 25 de resmgr:cpu quantum. AWR, en el intervalo 19 → 20, la puso arriba con 4.048 ejecuciones, 249,7 s y 5.125 lecturas por ejecución, con el plan 2571571058. ADDM cuantificó el problema: 2,57 sesiones activas de media con 2 CPU, y el hallazgo Top SQL Statements con el 93,55 % de la actividad recomendaba pasar el SQL Tuning Advisor sobre 0dbx7196jdajy. Lo que ninguna de las tres podía decirme es la causa: eso lo dice el plan, que guardado en AWR es un TABLE ACCESS FULL sobre PEDIDO, el mismo de C07 donde la V1 pasa el código postal como NUMBER y Oracle aplica TO_NUMBER sobre la columna. El único cambio fue desplegar la V2, que recibe el parámetro como VARCHAR2 igual que la columna, sin crear índices ni tocar parámetros para arreglar la búsqueda; la nueva sentencia (53mx77snb43uw) usa INDEX RANGE SCAN sobre IX_T6_PED_CP.

Evidencia: `casos/20261126T110634Z_C17_diagnosticar.txt`, `casos/20261126T110732Z_C17_solucionar.txt` y `casos/20261126T112047Z_C17_observar.txt`.

## Parte F · C18 · SQL Plan Management
1. PLAN_HASH_VALUE y lecturas del lunes, del martes y con la línea base.

El mismo SQL_ID (8hn59jfgw00y7) tuvo tres comportamientos. El lunes, con histograma en ESTADO, usó el plan 1767728868 (INDEX RANGE SCAN sobre IX_T6_PED_ESTADO) con 194 lecturas por ejecución y 3,6 ms. El martes, después de la recogida nocturna con la preferencia METHOD_OPT = FOR ALL COLUMNS SIZE 1, el histograma desapareció, el optimizador estimó 250.000 pedidos en P y cambió al plan 2571571058 (TABLE ACCESS FULL) con 5.227 lecturas y 24,8 ms. Como AWR guardaba el plan del lunes (instantáneas 25 a 26), lo cargué con DBMS_SPM.LOAD_PLANS_FROM_AWR como línea base aceptada (SQL_PLAN_0a27u7nan424ba00b9863, MANUAL-LOAD-FROM-AWR). Con ella, y sin tocar las estadísticas del martes, el informe volvió al plan 1767728868 con 190 lecturas por ejecución, 27 veces menos.

Evidencia: `casos/20261126T112448Z_C18_entender.txt`, `casos/20261126T112451Z_C18_diagnosticar.txt`, `casos/20261126T112454Z_C18_solucionar.txt` y `casos/20261126T112455Z_C18_validar.txt`.

2. ¿Qué hizo la evolución con el plan nuevo y por qué? ¿Qué queda pendiente para que no vuelva a pasar?

Al tener línea base, el plan que quería el optimizador (el recorrido completo) no se usó: SPM lo guardó como SQL_PLAN_0a27u7nan424b95a18d93, AUTO-CAPTURE y no aceptado. La tarea de evolución ejecutó los dos planes con la cuenta de la aplicación (T6_APP), los comparó y el nuevo no pasó el criterio de beneficio: su rendimiento verificado fue 0,10848 veces el del plan de la línea base, o sea, mucho peor. Por eso siguió sin aceptarse. SPM no se fía de lo que cree el optimizador, solo acepta un plan si demuestra que es mejor. Lo pendiente es la causa: la preferencia METHOD_OPT = FOR ALL COLUMNS SIZE 1 de PEDIDO seguirá borrando el histograma de ESTADO en cada recogida. Hay que cambiar esa preferencia para que recoja el histograma de ESTADO y aplicarlo con el ciclo de C13 (pendientes, probar en una sesión y publicar), y mientras tanto la línea base mantiene el plan bueno.

Evidencia: `casos/20261126T112532Z_C18_observar.txt` y `casos/20261126T112447Z_C18_provocar.txt`.

## Parte G · Incidente 1 · INC-6NN
- **Síntoma (con números):**
- **Playbook y pasos seguidos (herramientas y vistas):**
- **Causa raíz:**
- **Arreglo aplicado (órdenes exactas) y por qué ese:**
- **Verificación (archivo de evidencia con todo OK):**
- **Prevención (qué evitaría que se repita):**

## Parte G · Incidente 2 · INC-6NN
- **Síntoma (con números):**
- **Playbook y pasos seguidos (herramientas y vistas):**
- **Causa raíz:**
- **Arreglo aplicado (órdenes exactas) y por qué ese:**
- **Verificación (archivo de evidencia con todo OK):**
- **Prevención (qué evitaría que se repita):**

## Parte G · Incidente 3 · INC-6NN
- **Síntoma (con números):**	
- **Playbook y pasos seguidos (herramientas y vistas):**
- **Causa raíz:**
- **Arreglo aplicado (órdenes exactas) y por qué ese:**
- **Verificación (archivo de evidencia con todo OK):**
- **Prevención (qué evitaría que se repita):**

## Parte H · Reflexión
1. De todo el laboratorio, ¿qué cambio dio más mejora por menos riesgo? Justifícalo con tus números.
2. Un caso no evaluable (sin ★) que hayas hecho y qué aprendiste de él (opcional, cuenta para la certificación).
