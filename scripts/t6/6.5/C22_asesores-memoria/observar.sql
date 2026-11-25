-- C22 · observar · lo que debes retener
@@../../_formato
SET ECHO OFF
PROMPT == Lo que debes retener ==
PROMPT 1. La memoria es de la instancia: los asesores se leen en la raíz (CDB$ROOT); una PDB solo puede limitar su parte.
PROMPT 2. SGA: V$SGA_TARGET_ADVICE (factor de DB time). Buffer cache: V$DB_CACHE_ADVICE. PGA: V$PGA_TARGET_ADVICE.
PROMPT 3. Se elige el punto donde la curva se aplana: más memoria a partir de ahí no da nada (rendimientos decrecientes).
PROMPT 4. Una foto no basta: se miran semanas de AWR (DBA_HIST_*_ADVICE y DBA_HIST_PGASTAT) en horas punta.
PROMPT 5. Variante de examen: «sube pga_aggregate_target y no mejora»: una sesión en MANUAL (caso C04) o un trigger de logon.
EXIT
