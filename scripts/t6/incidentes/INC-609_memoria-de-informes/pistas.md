# INC-609 · «Los informes de la aplicación escriben en TEMP y tardan el doble»

**Ticket (Finanzas, 09:20):** «El informe de ventas por cliente tarda el doble. El DBA de noche dice que la PGA está
de sobra (pga_aggregate_target tiene margen) y que no es cosa de la base.»

**El informe (como T6_APP):** `SELECT id_cliente, COUNT(*), SUM(importe) FROM t6.pedido GROUP BY id_cliente ORDER BY 3 DESC`

**Por dónde empezar:** playbook **PB-4 · TEMP y memoria de trabajo**. Herramientas: `t6 memoria`, `t6 sesiones`,
y las vistas de las áreas de trabajo (V$SQL_WORKAREA). Casos: **C04** (el más parecido), **C19**, **C22**.

**Lo que se comprueba al verificar:** que una sesión NUEVA de la aplicación trabaja con la memoria automática y que
el informe ya no se desborda. Escribe en la bitácora por qué subir pga_aggregate_target no lo habría arreglado.
