He leído la política de uso de IA de la asignatura.

# Declaración de uso de IA · Lab 7 · E066

<!--
CÓMO SE RELLENA (léelo y borra este comentario si quieres; el script de evaluación lo ignora)
- La PRIMERA línea es obligatoria y no se toca: «He leído la política de uso de IA de la asignatura.»
- Copia este archivo como docs/bitacora/lab7-ia.md (junto a lab7-respuestas.md) y pon tu código en el título.
  Cada laboratorio tiene el suyo: el del Lab 6 (lab6-ia.md) no se toca.
- Si NO has usado IA: deja solo la línea «No he usado IA.» y borra la entrada de ejemplo.
- Si la has usado: borra la línea «No he usado IA.» y escribe UNA entrada por cada uso, con los 7 campos.
  Un campo vacío es una entrada incompleta (D3: −0,5 por entrada).
- Preguntar a la IA como tutor o corregir la ortografía de un texto propio está permitido: decláralo también.
  Si no copiaste código, escribe «no aplica» en «Código recibido» y en «Evidencia de ejecución» (no cuentan como vacíos).
  Los demás campos son siempre obligatorios.
- Una entrada con TODOS los campos vacíos (la de ejemplo sin tocar) no cuenta: se ignora.
- El código copiado de una IA puntúa si lo EJECUTAS en tu contenedor, lo EXPLICAS con tus palabras,
  dices para qué lo usaste y adjuntas aquí el código y el prompt LITERAL.
-->

## Entrada 1
- **Herramienta:** Claude
- **Prompt (literal, copiado tal cual):**
```text
he cerrado sin querer la terminal
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
cd ~/oracle-database-lab
source scripts/deployment/env/00-config.sh
ESTUDIANTE=$(grep -o 'E[0-9]\{3\}' config/.env)
ls docs/bitacora/*.save 2>/dev/null || echo "Sin copias de emergencia"
grep -n "^## Entrada\|PENDIENTE\|No he usado" docs/bitacora/lab7-ia.md
grep -n "^Con 1 sesión\|^Evidencia" docs/bitacora/lab7-respuestas.md | head -5
```
- **Dónde lo usé (parte, script o pregunta):** Parte B, al cerrar sin querer la terminal mientras pegaba las respuestas de C01
- **Propósito (para qué lo necesitaba):** recuperar el entorno de trabajo y comprobar que no había perdido nada de lo que estaba editando
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** las tres primeras líneas rehacen lo que se pierde al cerrar una terminal: vuelvo al repositorio, cargo la configuración del laboratorio y vuelvo a poner mi código de alumno en la variable ESTUDIANTE. Docker y la base no se ven afectados, porque no dependen de la ventana. El ls busca archivos .save, que son las copias de emergencia que deja nano cuando se cierra con cambios sin guardar. Los dos grep comprueban qué entradas tiene la bitácora de IA y si las respuestas de C01 se habían guardado con sus líneas de evidencia.
- **Evidencia de ejecución (archivo de docs/bitacora/lab7/evidencia con mi cabecera):** docs/bitacora/lab7/evidencia/herramientas/20261126T082820Z_recuperar-terminal.txt

## Entrada 2
- **Herramienta:** Claude
- **Prompt (literal, copiado tal cual):**
```text
FALLO Línea base ANTES y DESPUES registradas (t6 base ver C17)
FALLO La V2 usa el índice IX_T6_PED_CP
   evidencia: docs/bitacora/lab7/evidencia/casos/20261126T110938Z_C17_validar.txt
!! Hay comprobaciones en FALLO: repasa la fase solucionar
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```sql
SELECT component, ROUND(current_size/1048576) mb FROM v$sga_dynamic_components WHERE component IN ('shared pool','DEFAULT buffer cache');
ALTER SYSTEM SET shared_pool_size = 640M SCOPE = BOTH;
SELECT component, ROUND(current_size/1048576) mb FROM v$sga_dynamic_components WHERE component IN ('shared pool','DEFAULT buffer cache');
```
- **Dónde lo usé (parte, script o pregunta):** Parte F, caso C17, fase validar
- **Propósito (para qué lo necesitaba):** que la validación de C17 encontrara en memoria el cursor de la V2, que la shared pool expulsaba nada más terminar la carga
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** la primera consulta enseña cuánta memoria tienen la shared pool y el buffer cache (432 y 976 MB). El ALTER SYSTEM fija un mínimo de 640 MB para la shared pool; como la SGA es automática (sga_target 1.536 MB), Oracle saca esa memoria del buffer cache. SCOPE = BOTH lo aplica ya y lo guarda en el SPFILE para los siguientes arranques. La última consulta comprueba el resultado: 640 MB de shared pool y 768 MB de buffer cache. Lo hice porque tenía 7.006 reloads en la SQL AREA: los cursores se expulsaban por falta de sitio. La vuelta atrás sería ALTER SYSTEM RESET shared_pool_size, porque antes no estaba fijado.
- **Evidencia de ejecución (archivo de docs/bitacora/lab7/evidencia con mi cabecera):** docs/bitacora/lab7/evidencia/herramientas/20261126T111759Z_ajuste-shared-pool.txt y docs/bitacora/lab7/evidencia/casos/20261126T112010Z_C17_validar.txt
