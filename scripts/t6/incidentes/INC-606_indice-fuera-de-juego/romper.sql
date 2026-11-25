-- INC-606 · romper · el índice del código postal queda fuera de juego: UNUSABLE (semilla par) o INVISIBLE (impar)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF TERMOUT OFF VERIFY OFF
COLUMN modo NEW_VALUE modo
SELECT CASE MOD(&1, 2) WHEN 0 THEN 'UNUSABLE' ELSE 'INVISIBLE' END AS modo FROM dual;
ALTER INDEX t6.ix_t6_ped_cp VISIBLE;
ALTER INDEX t6.ix_t6_ped_cp &modo;
ALTER SYSTEM FLUSH SHARED_POOL;
@@../_registro INC-606 &1 &2 "modo de rotura &modo"
SET TERMOUT ON
PROMPT Roto: la búsqueda por código postal (versión V2, la buena) ya no va como ayer.
EXIT
