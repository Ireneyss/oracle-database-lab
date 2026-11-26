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
2. ¿Por qué FORCE es un puente y no la solución? ¿Qué ve el DBA en V$SQL que lo delata (FORCE_MATCHING_SIGNATURE)?

## Parte C · C04 · El informe que se desborda a TEMP
1. Bloques de TEMP, tipo de pasada y tiempo del informe antes y después. ¿Qué hacía el disparador de logon?
2. ¿Por qué el TOP 100 cabe en memoria y el informe completo no?

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
