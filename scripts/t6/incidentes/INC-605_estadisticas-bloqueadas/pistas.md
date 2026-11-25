# INC-605 · «El informe de cestas abandonadas tarda desde la carga de anoche»

**Ticket (Marketing, 08:10):** «El informe de cestas abandonadas tardaba un segundo; hoy tarda bastante más. No hemos cambiado nada.»

**El informe:** `SELECT COUNT(*), SUM(p.importe) FROM t6.cesta k JOIN t6.pedido p ON p.id_pedido = k.id_pedido`
(la herramienta de informes abre su sesión con `optimizer_adaptive_plans = FALSE`).

**Por dónde empezar:** playbook **PB-3 · El plan cambió** y runbook **RB-2 · Estadísticas con red**.
Herramientas: `t6 estad CESTA`, `t6 plan SQL_ID`. Caso que lo prepara: **C12** (y **C13** para lo que encontrarás).

**Lo que se comprueba al verificar:** que las estadísticas de CESTA reflejan las filas reales y que el informe
vuelve a un método de unión acorde con ellas. Documenta en tu bitácora por qué la tarea automática no lo arregló sola.
