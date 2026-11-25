# Kit del Tema 6 · Optimización (Laboratorio 7)

Este kit acompaña al **PPTX del Laboratorio 7** y a la **guía del Laboratorio 7 (docx)**. Todo lo que ves en las
diapositivas se ejecuta con tres órdenes: `caso`, `t6` e `incidente`. Funciona en el contenedor **oralab-26ai**
(Oracle AI Database 26ai Free, PDB FREEPDB1, esquema TIENDASUR con 1 millón de pedidos, el mismo de los Labs 4–6).

## 1 · Dejarlo listo (una sola vez, unos 5 minutos)

```bash
# 1. Descarga kit-t6-lab7.zip del aula virtual (queda en la carpeta Descargas de Windows)
# 2. En Ubuntu (WSL2), dentro de tu repositorio:
cd ~/oracle-database-lab
cp /mnt/c/Users/$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')/Downloads/kit-t6-lab7.zip /tmp/
unzip -o /tmp/kit-t6-lab7.zip -d scripts/          # crea scripts/t6/
bash scripts/t6/instalar.sh                        # comprueba la base y crea los alias caso, t6, incidente
source ~/.bashrc
caso --preparar                                    # crea el banco T6 (unos 40 s; repetible)
caso --lista                                       # los 23 casos; ★ = evaluables
t6 salud                                           # prueba: la caja de herramientas responde
```

Si el contenedor está parado: `docker start oralab-26ai` y espera 1 minuto. `instalar.sh` te dice qué falta, si
falta algo (instancia parada, FREEPDB1 cerrada, FRA llena, ESTUDIANTE sin definir en `config/.env`...).

## 2 · Los casos: seis fases, siempre las mismas

| Fase | Orden | Qué hace |
|---|---|---|
| 1 | `caso C03 provocar` | deja la base con el problema del enunciado |
| 2 | `caso C03 entender` | el síntoma que ve el usuario, con números |
| 3 | `caso C03 diagnosticar` | las vistas y herramientas que encuentran la causa |
| 4 | `caso C03 solucionar` | la solución de referencia (**inténtalo antes tú**) |
| 5 | `caso C03 validar` | cada línea dice `OK` o `FALLO` |
| 6 | `caso C03 observar` | qué ha cambiado, la variante de examen y lo que debes retener |

`caso --ref C03 validar` muestra la salida de referencia de esa fase para comparar con la tuya.
Cada fase guarda su salida en `scripts/t6/salidas/` y, si `config/.env` tiene `ESTUDIANTE="E0NN"`, su **evidencia**
con cabecera de alumno en `docs/bitacora/lab7/evidencia/casos/`.

**Los ★ (evaluables en el Lab 7):** C01, C03, C04, C07, C08, C12, C13, C14, C17, C18.
El resto (C02, C05, C06, C09–C11, C15, C16, C19–C23) prepara la certificación 1Z0-182.

| Sección | Casos |
|---|---|
| 6.1 Metodología y línea base | C01★ C02 |
| 6.2 Procesamiento de SQL | C03★ C04★ C05 C06 |
| 6.3 Planes de ejecución | C07★ C08★ C09 C10 C11 |
| 6.4 Estadísticas e índices | C12★ C13★ C14★ C15 C16 |
| 6.5 Herramientas de diagnóstico | C17★ C18★ C19 C20 C21 C22 C23 |

## 3 · La caja de herramientas `t6`

Las mismas órdenes que usan los playbooks, los runbooks y los incidentes (todas en FREEPDB1 como SYSDBA):

```
t6 salud [min]          ¿más trabajo que CPU? ¿CPU o esperas? ¿quién?        (PB-1)
t6 top [n] [orden]      sentencias que más pesan
t6 plan SQL_ID          plan REAL con E-Rows/A-Rows, predicados y binds      (PB-2)
t6 ash [min] [filtro]   ASH minuto a minuto
t6 sesiones [módulo]    sesiones activas de la aplicación
t6 base registrar|ver   línea base antes/después                             (RB-1)
t6 estad TABLA          estadísticas, histogramas, pendientes, historial     (RB-2)
t6 indices TABLA        inventario, redundancia, uso                         (RB-3)
t6 spm lista|cargar|evolucionar|quitar                                       (RB-4)
t6 awr snap|lista|top|addm|informe                                           (RB-1)
t6 traza on|off|tkprof                                                       (RB-5)
t6 memoria              asesores de SGA y PGA
t6 fra [--liberar]      ocupación de la FRA (libérala si pasa del 80 %)
```

## 4 · Playbooks y runbooks

- **Playbooks** (`playbooks/`, empieza por `LEEME.md`): qué hacer ante un síntoma. PB-1 la base va lenta ·
  PB-2 una consulta va lenta · PB-3 el plan cambió · PB-4 TEMP y memoria · PB-5 análisis y CPU.
- **Runbooks** (`runbooks/`): cómo hacer un cambio con red. RB-1 línea base y AWR · RB-2 estadísticas con red ·
  RB-3 índices con red · RB-4 SPM · RB-5 traza y tkprof.

## 5 · El banco de incidentes (Parte G del Lab 7)

```bash
incidente --mios               # tus 3 incidentes (dependen de tu código E0NN)
incidente INC-6NN romper       # rompe la base con TU semilla
incidente INC-6NN pistas       # el síntoma y el playbook por el que empezar
incidente INC-6NN verificar    # OK / FALLO; tu evidencia queda en docs/bitacora/lab7/evidencia/incidentes/
```

Cada alumno recibe una avería distinta (valores, columnas y umbrales salen de su semilla): la evidencia de otro
alumno no te sirve.

## 6 · Limpieza y problemas frecuentes

- `caso --preparar` devuelve el banco T6 a su punto de partida (repetible); `caso --limpiar` lo borra todo.
- «FRA al 80 %»: `t6 fra --liberar`. Si la base se queda en *mounted* con ORA-19809/ORA-16038, igual.
- «Falta el banco T6»: `caso --preparar`.
- Las cifras de tus salidas pueden variar unos milisegundos respecto a la referencia; lo que importa es el orden de
  magnitud y que `validar` diga `OK`.
