-- C06 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN s.t * 3 < p.t THEN 'OK    ' ELSE 'FALLO ' END || 'SQL puro: ' || ROUND(s.t) || ' ms frente a ' || ROUND(p.t) || ' ms con la función' AS resultado
  FROM (SELECT MIN(elapsed_time / executions / 1000) t FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c06 sql%') s,
       (SELECT MIN(elapsed_time / executions / 1000) t FROM v$sql WHERE sql_text LIKE 'SELECT /* t6_c06 plsql%') p
UNION ALL
SELECT CASE WHEN (SELECT SUM(ROUND(importe * 1.21, 2)) FROM t6.pedido) = (SELECT SUM(t6.con_iva(importe)) FROM t6.pedido)
            THEN 'OK    ' ELSE 'FALLO ' END || 'Las dos formas dan exactamente el mismo total' FROM dual;
EXIT
