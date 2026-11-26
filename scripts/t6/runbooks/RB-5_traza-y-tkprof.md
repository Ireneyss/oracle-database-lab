# RB-5 · Trazar un módulo y leerlo con tkprof

1. Delimita: servicio, módulo y acción de la aplicación (`t6 sesiones`, `t6 ash`).
2. `t6 traza on MÓDULO ACCIÓN` (DBMS_MONITOR con esperas; sin binds salvo que haga falta).
3. Reproduce el problema el tiempo justo.
4. `t6 traza off MÓDULO ACCIÓN` **inmediatamente** (una traza olvidada llena el disco de diagnóstico).
5. `t6 traza tkprof IDENTIFICADOR` (sort=exeela,fchela, sys=no): las sentencias más lentas, Parse/Execute/Fetch,
   esperas y «Misses in library cache».
6. Adjunta el .prf al ticket con la conclusión (qué sentencia, cuánto, por qué) y vuelve a trazar tras el arreglo.

Caso **C20**. Varias sesiones del mismo módulo: `trcsess module=...` antes de tkprof.
