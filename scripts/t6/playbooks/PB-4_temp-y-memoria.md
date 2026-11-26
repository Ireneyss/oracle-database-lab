# PB-4 · «Escribe en TEMP» / «falta memoria»

| Paso | Orden | Qué mirar | Causa → acción |
|---|---|---|---|
| 1 · ¿Qué se desborda? | `t6 plan SQL_ID` (OMem, 1Mem, Used-Tmp) · V$SQL_WORKAREA | OPTIMAL, 1-PASS, MULTI-PASS por operación | Ordenaciones, hash join, ventanas (C04, C19) |
| 2 · ¿Con qué política trabaja la sesión? | `t6 sesiones` · V$SES_OPTIMIZER_ENV | workarea_size_policy, sort_area_size | MANUAL: un ALTER SESSION o un **disparador de logon** (INC-609, C04) |
| 3 · ¿Hay PGA para todos? | `t6 memoria` | V$PGA_TARGET_ADVICE, over allocation count | Si sobra memoria y aun así se desborda, NO es la PGA: vuelve al paso 2 |
| 4 · ¿Hace falta ordenar tanto? | el SQL | TOP-N sin FETCH FIRST, ventanas enteras | Reescribir: C04 (TOP100 en memoria) |
| 5 · Dimensionar | `t6 memoria` y semanas de AWR | dónde se aplana la curva | C22: el tamaño mínimo con (casi) todo el beneficio |

**Error típico:** subir pga_aggregate_target cuando la sesión está en MANUAL (no cambia nada).
