He leído la política de uso de IA de la asignatura.

# Declaración de uso de IA · Lab 6 · E066
## Entrada 1
- **Herramienta:** Claude
- **Prompt (literal, copiado tal cual):**
```text
Esta es la próxima tarea que tengo que hacer, ten en cuenta que el lab 5 lo realicé con claude code. El profesor me ha dicho que no puedo hacer con claude auto-merge, no debes incluir nada de eso. Antes de empezar con esta tarea, quiero que me ayudes a ver que todo está correcto y en orden para empezar el laboratorio.
```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```bash
# Copia del kit del Lab 6 al repositorio (Parte A.2)
ZIP=$(ls /mnt/c/Users/*/Downloads/*Lab6*.zip | head -1); echo "$ZIP"
mkdir -p ~/kit-lab6 && unzip -oq "$ZIP" -d ~/kit-lab6
K=~/kit-lab6/repo-kit
diff -u scripts/deployment/env/00-config.sh "$K/scripts/deployment/env/00-config.sh"
cp -r "$K/scripts/." scripts/
cp "$K/config/.env.example" config/.env.example
mkdir -p docs/plantillas && cp "$K/docs/plantillas/IA.md" docs/plantillas/
# Comprobaciones antes de empezar: sin firmas ni archivos de agentes de IA
git tag -l lab5-final
git log --format='%h %an <%ae> %s%n%b' lab5-final..main | grep -inE 'co-authored-by|claude|anthropic|generated with' || echo "Sin firmas de IA desde lab5-final"
git ls-files | grep -iE '^\.claude/|CLAUDE\.md|AGENTS\.md|^\.cursor' || echo "Sin archivos de agente versionados"
ls -a | grep -iE '^\.claude$|^CLAUDE\.md$|^AGENTS\.md$|^\.cursor' || echo "Sin archivos de agente en la carpeta"
git config user.name; git config user.email
```
- **Dónde lo usé (parte, script o pregunta):** Antes de la Parte A (comprobaciones) y Parte A.2 (copia del kit)
- **Propósito (para qué lo necesitaba):** copiar el kit del Lab 6 en mi repositorio y comprobar que partía de un repositorio sin commits ni archivos de agentes de IA
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Comprobaciones inciales
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** docs/bitacora/lab6/evidencia/script/<NOMBRE>_00-preparacion.script.log


