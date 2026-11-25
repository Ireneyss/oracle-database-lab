# INC-612 · «¿Olvidaste tu contraseña?» tarda y consume CPU

**Ticket (Seguridad web, 18:40):** «La pantalla de recuperar contraseña tarda casi un segundo con pocos usuarios y la
CPU sube. Ayer, un compañero borró "los índices que nadie usaba" para ahorrar espacio.»

**El SQL de la web:** `SELECT MAX(id_cliente) FROM t6.cliente WHERE UPPER(email) = UPPER(:correo)` (tu correo de
prueba está en el detalle del incidente).

**Por dónde empezar:** playbook **PB-5 · Análisis y CPU** y runbook **RB-3 · Índices con red**. Herramientas:
`t6 top 5 cpu`, `t6 plan SQL_ID` (mira los predicados), `t6 indices CLIENTE`. Caso: **C16** (y C23 para la moraleja).

**Lo que se comprueba al verificar:** que la búsqueda por correo vuelve a ir por índice. En la bitácora: ¿qué
habría evitado el borrado (INVISIBLE antes que DROP, DBA_INDEX_USAGE durante semanas)?
