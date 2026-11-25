# INC-610 · «Muchas consultas cambiaron de plan a la vez en la PDB»

**Ticket (Operaciones, 10:00):** «No es una pantalla: son varias. La búsqueda por código postal, el panel de
pendientes... Todas a la vez, desde que vino ayer el consultor "a afinar la base".»

**Por dónde empezar:** playbook **PB-3 · El plan cambió** (cuando cambian MUCHOS planes a la vez, la causa es común:
un parámetro, unas estadísticas de sistema, una versión del optimizador). Herramientas: `t6 salud`, `t6 top`,
`t6 plan SQL_ID` con `+OUTLINE` en el formato, y las vistas de parámetros de la PDB (V$SYSTEM_PARAMETER, ISDEFAULT,
ISPDB_MODIFIABLE). Casos: **C07**, **C09**, **C17**.

**Lo que se comprueba al verificar:** que la PDB vuelve al valor por defecto (no basta con cambiarlo en tu sesión)
y que la V2 de la búsqueda por código postal vuelve a usar su índice.
