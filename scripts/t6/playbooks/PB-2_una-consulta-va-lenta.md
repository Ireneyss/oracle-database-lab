# PB-2 · «Esta pantalla (o este informe) va lenta»

Ya hay una sentencia sospechosa. El objetivo es encontrar **por qué** su plan hace más trabajo del necesario.

| Paso | Orden | Qué mirar | Pista → causa típica | Caso |
|---|---|---|---|---|
| 1 · Encontrar el SQL_ID | `t6 top 5 elapsed filtro` · `t6 ash 10 módulo` | ejecuciones, ms y lecturas por ejecución | Muchas ejecuciones baratas: análisis/CPU (**PB-5**) | C03 |
| 2 · El plan REAL | `t6 plan SQL_ID` | Operaciones, **Predicate Information**, A-Rows | `filter(TO_NUMBER(col))` o `filter(UPPER(col))` → el índice no sirve | C07, C16 |
| 3 · Estimación frente a realidad | `t6 plan SQL_ID` (E-Rows × Starts frente a A-Rows) | el primer paso donde se separan | Estadísticas viejas (**PB-3**), columnas correladas, sin histograma | C08, C12 |
| 4 · Método de unión y ruta | el mismo plan | NESTED LOOPS con Starts enormes; FULL con pocas filas | Falta un índice o sobra una estimación | C05, C09, C14 |
| 5 · Memoria | `t6 plan SQL_ID` (Used-Tmp, 1-pass) | áreas de trabajo que se desbordan | **PB-4** | C04, C19 |
| 6 · Decidir UN cambio | runbook RB-2, RB-3 o RB-4 | — | Tipo de dato, índice invisible, estadísticas, SPM | C14, C17 |
| 7 · Medir igual | `t6 base registrar DESPUES SQL_ID` · `t6 base ver` | lecturas y ms por ejecución | Si no mejora, marcha atrás | C01, C17 |

**No confundas:** EXPLAIN PLAN es una predicción (no mira binds ni tipos reales); DISPLAY_CURSOR es lo que pasó (C07).
