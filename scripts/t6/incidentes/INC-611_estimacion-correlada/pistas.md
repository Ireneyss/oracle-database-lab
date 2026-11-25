# INC-611 · «El listado por ciudad y comunidad elige mal el método de unión»

**Ticket (Comercial, 12:15):** «El listado de pedidos de los clientes de una ciudad (filtrando también su comunidad)
es lento y el plan parece pensado para muy pocas filas.» Tu ciudad y tu comunidad están en el detalle del incidente.

**El SQL:** `SELECT ... FROM t6.cliente c JOIN t6.pedido p ON p.id_cliente = c.id_cliente WHERE c.ciudad = :ciu AND c.comunidad = :com`

**Por dónde empezar:** playbook **PB-2 · Una consulta va lenta** (E-Rows frente a A-Rows) y runbook **RB-2**.
Herramientas: `t6 plan SQL_ID` (con GATHER_PLAN_STATISTICS), `t6 estad CLIENTE` (extensiones). Caso: **C08**.

**Lo que se comprueba al verificar:** que la estimación de clientes de tu ciudad y comunidad se acerca a la real.
