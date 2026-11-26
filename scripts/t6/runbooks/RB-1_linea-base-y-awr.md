# RB-1 · Línea base, AWR y ADDM (medir antes y después)

1. Nombra el SLI y el SLO (p. ej. «p95 de la búsqueda < 20 ms») y anótalo en la bitácora.
2. `t6 awr snap` → anota el número (INI).
3. Reproduce la carga real (la aplicación, no SYS) el tiempo suficiente (ADDM necesita ~2 minutos de actividad).
4. `t6 awr snap` → FIN. `t6 base registrar ANTES SQL_ID INC-xxx`.
5. Diagnóstico: `t6 awr top INI FIN`, `t6 awr addm INI FIN`, `t6 awr informe INI FIN` (guarda el informe completo).
6. Aplica **un solo** cambio (otro runbook).
7. Repite 2–4 con la **misma** carga y `t6 base registrar DESPUES SQL_ID INC-xxx`.
8. `t6 base ver INC-xxx`: la mejora es la evidencia del cierre. Caso completo: **C17**.

**Marcha atrás:** la del runbook del cambio. **Licencia:** AWR/ADDM son Diagnostics Pack en EE (en Free están).
