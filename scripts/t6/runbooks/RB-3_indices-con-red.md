# RB-3 · Crear o retirar un índice con red

**Crear**
1. Inventario: `t6 indices TABLA` (columnas en orden, redundancia por prefijo, factor de agrupamiento, uso). Caso **C23**.
2. `CREATE INDEX ... INVISIBLE ONLINE` (primero las columnas de igualdad, el rango al final).
3. Probar en una sesión: `ALTER SESSION SET optimizer_use_invisible_indexes = TRUE` + `t6 plan SQL_ID`.
4. `ALTER INDEX ... VISIBLE` y medir (RB-1). Medir también el coste de escritura (caso **C15**).
**Marcha atrás:** `ALTER INDEX ... INVISIBLE` (inmediata, sin reconstruir). Caso **C14**.

**Retirar**
1. Semanas de DBA_INDEX_USAGE (se vuelca cada ~15 min, no cuenta a SYS) y AWR.
2. ¿Protege una FK o una restricción? ¿Es basado en función y lo usa una pantalla rara (INC-612)?
3. `INVISIBLE` una temporada → si nadie se queja, `DROP`. Nunca un DROP directo «porque no se usa».

**Índice fuera de juego** (INC-606): `status = UNUSABLE` → `ALTER INDEX ... REBUILD ONLINE`; `INVISIBLE` → `VISIBLE`.
