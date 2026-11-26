# INC-608 · «El informe por estado empeoró tras el mantenimiento nocturno»

**Ticket (Logística, 07:45):** «El informe de pedidos en un estado concreto (mira el detalle de tu incidente en la
primera línea de `incidente INC-608 verificar`) tardaba milisegundos y hoy lee la tabla entera.»

**El SQL:** `SELECT COUNT(*), SUM(importe), MAX(fecha_pedido) FROM t6.pedido WHERE estado = :valor_de_tu_semilla`

**Por dónde empezar:** playbook **PB-3 · El plan cambió** y runbook **RB-2 · Estadísticas con red**.
Herramientas: `t6 estad PEDIDO` (histogramas, preferencias, historial). Casos: **C12**, **C13**, **C18**.

**Lo que se comprueba al verificar:** que la estimación para tu valor vuelve a ser buena, y que **la próxima recogida
nocturna no lo volverá a romper** (la causa está en las preferencias, no solo en las estadísticas de hoy).
