-- C06 · observar · dos alternativas que conservan la función: caché de subconsulta escalar y WITH FUNCTION
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF SERVEROUTPUT ON
EXEC t6.contador.n := 0
SELECT /* t6_c06 escalar */ SUM((SELECT t6.con_iva(importe) FROM dual)) AS total FROM t6.pedido;
EXEC DBMS_OUTPUT.PUT_LINE('llamadas reales con caché escalar: ' || t6.contador.n)
WITH FUNCTION iva(p NUMBER) RETURN NUMBER IS BEGIN RETURN ROUND(p * 1.21, 2); END;
SELECT /* t6_c06 with */ SUM(iva(importe)) AS total FROM t6.pedido
/
COLUMN forma FORMAT A15
SELECT REGEXP_SUBSTR(sql_text, 't6_c06 (\w+)', 1, 1, NULL, 1) AS forma, ROUND(elapsed_time / executions / 1000) AS ms_ejec,
       ROUND(cpu_time / executions / 1000) AS cpu_ms
  FROM v$sql WHERE sql_text LIKE '%t6_c06%' AND sql_text NOT LIKE '%v$sql%' AND command_type = 3 ORDER BY 2 DESC;
PROMPT == Lo que debes retener ==
PROMPT 1. Una función PL/SQL en el SELECT se paga UNA VEZ POR FILA: el coste repetido es coste serio.
PROMPT 2. Mejor la regla en SQL. Si hay que conservar la función: caché escalar (si la entrada tiene pocos valores),
PROMPT    WITH FUNCTION, PRAGMA UDF o DETERMINISTIC. Mide siempre: la caché escalar no ayuda con 1 000 000 de valores distintos.
EXIT
