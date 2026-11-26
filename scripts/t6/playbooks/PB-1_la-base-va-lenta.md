# PB-1 · «La base va lenta»

Cuando la queja es general (varias pantallas, varios usuarios), no empieces por una sentencia: empieza por la carga.

| Paso | Pregunta | Orden | Qué mirar | Si la respuesta es sí… |
|---|---|---|---|---|
| 1 | ¿Hay más trabajo que CPU? | `t6 salud 5` | AAS frente a CPU_COUNT (semáforo) | Cola de CPU: ¿más sesiones de las que caben? → caso **C01** (Little: N = X · R) |
| 2 | ¿CPU o esperas? | `t6 salud 5` (bloque 2) | % ON CPU y el evento principal | `resmgr:cpu quantum` = límite de CPU (Free: 2). `log file sync` → **C02**. `enq: TX` → bloqueos (Tema 5) |
| 3 | ¿Quién? | `t6 ash 10` y `t6 sesiones` | módulo, acción y SQL_ID con más muestras | Ya tienes un SQL concreto: pasa a **PB-2** |
| 4 | ¿Desde cuándo y cuánto? | `t6 awr lista` → `t6 awr top INI FIN` → `t6 awr addm INI FIN` | deltas del intervalo y hallazgos ADDM | Compara con la línea base (`t6 base ver`) |
| 5 | ¿Cambió algo común? | `t6 plan SQL_ID` de varias sentencias | ¿todas cambiaron de plan a la vez? | Un parámetro de la PDB o estadísticas: **PB-3** (incidente **INC-610**) |

**Antes de tocar nada:** `t6 awr snap` y `t6 base registrar ANTES SQL_ID`. **Después:** la misma carga, `t6 awr snap`,
`t6 base registrar DESPUES SQL_ID` y `t6 base ver` (columna mejora). Runbook **RB-1**.

**Errores típicos:** subir el pool de conexiones «para aguantar más» (C01); culpar a la red sin mirar ASH; arreglar lo
que dice ADDM sin confirmar la causa en el plan (C17, C21).
