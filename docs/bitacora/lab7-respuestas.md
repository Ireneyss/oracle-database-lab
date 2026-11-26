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
2. Lecturas y p95 de V1 y V2. ¿Por qué EXPLAIN PLAN no lo vio?

## Parte D · C08 · E-Rows frente a A-Rows
1. Estimación y filas reales antes y después del grupo de columnas. ¿En qué línea del plan se separan por primera vez?
2. ¿Por qué el optimizador multiplicaba mal las dos selectividades?

## Parte E · C12 · Estadísticas obsoletas
1. Filas según las estadísticas y reales; método de unión y lecturas antes y después.
2. ¿Por qué la tarea automática no lo habría arreglado a tiempo? ¿Quién debe recoger y cuándo?

## Parte E · C13 · El ciclo de estadísticas con red
1. Describe el ciclo que seguiste (pendientes, probar, publicar, restaurar, bloquear) con la vista que comprueba cada paso.
2. ¿Qué error obtuviste al recoger sobre estadísticas bloqueadas y cómo se recoge si de verdad hace falta?

## Parte E · C14 · El índice invisible
1. Lecturas por apertura del panel antes y después. ¿Cómo probaste el índice sin que lo viera nadie más?
2. Redo con el índice INVISIBLE y VISIBLE: ¿qué demuestra?

## Parte F · C17 · INC-604 con AWR, ASH y ADDM
1. SLI y SLO; p95 antes y después; instantáneas AWR que usaste.
2. ¿Qué dijeron ASH, AWR y ADDM, y qué no podían decirte? ¿Cuál fue el ÚNICO cambio?

## Parte F · C18 · SQL Plan Management
1. PLAN_HASH_VALUE y lecturas del lunes, del martes y con la línea base.
2. ¿Qué hizo la evolución con el plan nuevo y por qué? ¿Qué queda pendiente para que no vuelva a pasar?

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
