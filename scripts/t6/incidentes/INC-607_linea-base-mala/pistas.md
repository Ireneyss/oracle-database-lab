# INC-607 · «El historial del cliente es lento aunque su índice está bien»

**Ticket (Atención al cliente, 16:05):** «Abrir el historial de un cliente tarda. Hemos mirado el índice de ID_CLIENTE
y está perfecto: VALID, VISIBLE y con estadísticas.»

**El SQL de la aplicación (cuenta T6_APP):**
`SELECT /* t6_inc607_historial */ COUNT(*), SUM(p.importe) FROM t6.pedido p WHERE p.id_cliente = :c`

**Por dónde empezar:** playbook **PB-3 · El plan cambió** y runbook **RB-4 · SPM**.
Herramientas: `t6 plan SQL_ID` (mira la sección Note), `t6 spm lista inc607`. Caso que lo prepara: **C18**.

**Lo que se comprueba al verificar:** que la aplicación vuelve a usar el índice y que no queda ningún plan fijado
peor que el del optimizador. Explica en la bitácora por qué el índice «perfecto» no bastaba.
