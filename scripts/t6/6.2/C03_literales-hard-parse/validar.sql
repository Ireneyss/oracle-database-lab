-- C03 · validar · cada línea dice OK o FALLO
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF
SELECT CASE WHEN b.hard_parses < 0.01 * l.hard_parses THEN 'OK    ' ELSE 'FALLO ' END || 'Hard parses: ' || b.hard_parses || ' con variables de enlace frente a ' || l.hard_parses || ' con literales' AS resultado
  FROM t6.c03_medida b, t6.c03_medida l WHERE b.modo = 'BIND' AND l.modo = 'LITERAL'
UNION ALL
SELECT CASE WHEN b.ms_total < 0.5 * l.ms_total THEN 'OK    ' ELSE 'FALLO ' END || 'Tiempo total: ' || b.ms_total || ' ms frente a ' || l.ms_total || ' ms'
  FROM t6.c03_medida b, t6.c03_medida l WHERE b.modo = 'BIND' AND l.modo = 'LITERAL'
UNION ALL
SELECT CASE WHEN b.cursores <= 2 THEN 'OK    ' ELSE 'FALLO ' END || 'Cursores en la shared pool: ' || b.cursores || ' con variables, '
       || l.cursores || ' con literales (y los que ya expulsó)'
  FROM t6.c03_medida b, t6.c03_medida l WHERE b.modo = 'BIND' AND l.modo = 'LITERAL';
EXIT
