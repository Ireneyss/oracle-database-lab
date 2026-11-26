-- INC-610 · romper · un «ajuste» de un consultor a nivel de PDB: optimizer_index_cost_adj muy alto (los índices «cuestan» más)
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO OFF FEEDBACK OFF TERMOUT OFF VERIFY OFF
COLUMN v NEW_VALUE valor
SELECT TO_CHAR(2000 + MOD(&1 * 37, 50) * 100) AS v FROM dual;
ALTER SYSTEM SET optimizer_index_cost_adj = &valor SCOPE = BOTH;
ALTER SYSTEM FLUSH SHARED_POOL;
@@../_registro INC-610 &1 &2 "optimizer_index_cost_adj = &valor en FREEPDB1"
SET TERMOUT ON
PROMPT Roto: varias pantallas de la web van lentas a la vez desde esta mañana.
EXIT
