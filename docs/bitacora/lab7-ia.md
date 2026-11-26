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
- **Evidencia de ejecución (archivo de docs/bitacora/lab7/evidencia con mi cabecera):** docs/bitacora/lab7/evidencia/herramientas/NOMBRE_DEL_PASO_1

