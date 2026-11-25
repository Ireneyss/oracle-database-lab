# PB-3 · «Ayer iba bien y hoy no» (el plan cambió)

| Paso | Orden | Qué mirar | Causa → acción |
|---|---|---|---|
| 1 · ¿Mismo SQL, otro plan? | `t6 plan SQL_ID` (bloque de historia AWR) · `t6 awr top INI FIN` | PLAN_HASH_VALUE distinto para el mismo SQL_ID | Confirma la regresión (C18) |
| 2 · ¿Cambiaron las estadísticas? | `t6 estad TABLA` | LAST_ANALYZED, STALE, histogramas, historial, **preferencias**, bloqueos | Viejas → recoger (RB-2, C12). Bloqueadas → INC-605. Preferencia SIZE 1 → INC-608 |
| 3 · ¿Cambió un parámetro? | `V$SYSTEM_PARAMETER` en FREEPDB1 (ISDEFAULT = FALSE) | optimizer_*, cursor_sharing | Si cambiaron MUCHOS planes a la vez → INC-610: `ALTER SYSTEM RESET` en la PDB |
| 4 · ¿Hay SPM o perfiles? | `t6 spm lista filtro` y la sección Note del plan | «SQL plan baseline … used», FIXED = YES | Una línea base mala → INC-607 (RB-4) |
| 5 · ¿Binds? | `t6 plan SQL_ID` (+PEEKED_BINDS), V$SQL IS_BIND_AWARE | el valor espiado en el primer análisis | C10 (bind peeking y ACS) |
| 6 · Arreglar con red | RB-2 (pendientes → publicar, restaurar) o RB-4 (SPM desde caché o AWR) | — | Medir antes y después (RB-1) |

**Clave:** arreglar HOY (restaurar estadísticas, cargar la línea base buena) y arreglar la CAUSA (la preferencia, el
job de carga, el parámetro) para que mañana no vuelva a pasar.
