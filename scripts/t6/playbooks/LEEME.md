# Playbooks y runbooks del Tema 6

Un **playbook** responde a un síntoma («la base va lenta») y te lleva, en orden, a la causa. Un **runbook** es un
procedimiento con red para aplicar un cambio sin romper nada (con su marcha atrás). Los incidentes del banco
(`incidente --lista`) dicen qué playbook y qué runbook usar; los casos (`caso --lista`) los enseñan paso a paso.

| Síntoma del ticket | Playbook | Runbooks que suele necesitar | Casos que lo enseñan | Incidentes |
|---|---|---|---|---|
| «La base va lenta» (todo, no una pantalla) | PB-1 | RB-1 | C01, C02, C17 | INC-610 |
| «Esta pantalla o este informe va lento» | PB-2 | RB-1, RB-3 | C05–C09, C14, C16, C17 | INC-606, INC-611 |
| «Ayer iba bien y hoy no» (el plan cambió) | PB-3 | RB-2, RB-4 | C10, C12, C13, C18 | INC-605, INC-607, INC-608, INC-610 |
| «Escribe en TEMP» / «falta memoria» | PB-4 | RB-1 | C04, C19, C22 | INC-609 |
| «Mucha CPU con poco trabajo» / análisis | PB-5 | RB-5, RB-3 | C03, C06, C16, C20 | INC-612 |

Regla de oro de los cinco: **medir antes, un solo cambio, medir después con la misma carga, y dejar evidencia**.
