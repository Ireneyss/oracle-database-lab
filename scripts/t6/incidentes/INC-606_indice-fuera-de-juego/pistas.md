# INC-606 · «La búsqueda por código postal va lenta y nadie ha desplegado nada»

**Ticket (Atención al cliente, 11:30):** «La pantalla de pedidos por código postal vuelve a ir lenta, como en el INC-604.
Desarrollo jura que sigue en producción la V2.»

**La búsqueda:** `t6.app.buscar_cp_v2(:cp)` (marca `t6_cp_v2` en el SQL). Pruébala con la aplicación:
`ESTUDIANTE` no importa aquí; basta con `caso C17 solucionar` o llamar a `buscar_cp_v2` desde T6_APP.

**Por dónde empezar:** playbook **PB-2 · Una consulta va lenta** y runbook **RB-3 · Índices con red**.
Herramientas: `t6 top 5 gets t6_cp`, `t6 plan SQL_ID`, `t6 indices PEDIDO`. Casos: **C07**, **C14**, **C17**.

**Lo que se comprueba al verificar:** que el índice está utilizable y visible y que la V2 vuelve a usarlo.
Anota en la bitácora qué estado encontraste (cambia según tu semilla) y con qué vista lo viste.
