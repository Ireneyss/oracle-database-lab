-- C09 · provocar · el examen de rutas de acceso: un índice compuesto nuevo (CANAL, IMPORTE) y siete preguntas de negocio
-- Efectos: crea T6.IX_T6_PED_CANAL_IMP (observar lo borra). Errores esperados: ninguno
@@../../_formato
ALTER SESSION SET CONTAINER = FREEPDB1;
SET ECHO ON
CREATE INDEX IF NOT EXISTS t6.ix_t6_ped_canal_imp ON t6.pedido (canal, importe);
EXEC DBMS_STATS.GATHER_INDEX_STATS('T6', 'IX_T6_PED_CANAL_IMP')
SET ECHO OFF
SELECT index_name, (SELECT LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY column_position) FROM dba_ind_columns c
                     WHERE c.index_owner = i.owner AND c.index_name = i.index_name) AS columnas
  FROM dba_indexes i WHERE table_owner = 'T6' AND table_name = 'PEDIDO' ORDER BY index_name;
EXIT
