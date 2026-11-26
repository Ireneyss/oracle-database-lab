# RB-4 · SQL Plan Management (que el plan bueno no se pierda)

1. Localiza el SQL y sus planes: `t6 plan SQL_ID` (memoria y AWR) y `t6 spm lista filtro`.
2. Carga el plan **probado** como línea base aceptada:
   - desde la caché: `t6 spm cargar SQL_ID` (DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE);
   - desde AWR, si ya no está en memoria: DBMS_SPM.LOAD_PLANS_FROM_AWR con el plan elegido por sus números (caso **C18**).
3. Comprueba en el plan la nota «SQL plan baseline … used». La sentencia la debe analizar la cuenta de la aplicación.
4. Los planes nuevos entran NO aceptados: `t6 spm evolucionar HANDLE` los ejecuta y solo acepta si son mejores.
5. Arregla también la causa (estadísticas, parámetro): SPM da tiempo, no la solución definitiva.

**Marcha atrás:** `t6 spm quitar HANDLE` (o `ALTER_SQL_PLAN_BASELINE ... enabled => 'NO'`).
**Antipatrón:** fijar (FIXED = YES) un plan sin medirlo: INC-607.
