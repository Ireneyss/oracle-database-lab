# RB-2 · Cambiar estadísticas con red

1. Foto de partida: `t6 estad TABLA` (filas, STALE, histogramas, preferencias, bloqueos, historial).
2. Recoger **en pendientes**: `DBMS_STATS.SET_TABLE_PREFS('T6','TABLA','PUBLISH','FALSE')` y `GATHER_TABLE_STATS`.
3. Probar en UNA sesión: `ALTER SESSION SET optimizer_use_pending_statistics = TRUE` y el plan real.
4. Si mejora: `DBMS_STATS.PUBLISH_PENDING_STATS('T6','TABLA')`. Si no: `DELETE_PENDING_STATS`.
5. Devolver `PUBLISH` a TRUE. Si hace falta conservar un histograma, fíjalo en la preferencia METHOD_OPT (INC-608).
6. Tablas de trabajo que se vacían y llenan: estadísticas representativas y `LOCK_TABLE_STATS` (ORA-20005 si alguien
   intenta recoger sin `force => TRUE`). Si están bloqueadas y viejas: `UNLOCK` o `force`, y documenta (INC-605).

**Marcha atrás:** `DBMS_STATS.RESTORE_TABLE_STATS('T6','TABLA', SYSTIMESTAMP - INTERVAL '1' HOUR)`.
Casos: **C12** (obsoletas), **C13** (ciclo completo), **C08** (grupo de columnas).
