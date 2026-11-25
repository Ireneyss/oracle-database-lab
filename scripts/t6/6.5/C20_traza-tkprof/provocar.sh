#!/usr/bin/env bash
# C20 · provocar · «el alta de cliente va a tirones»: trazar SOLO el módulo de la web (DBMS_MONITOR por servicio y módulo)
# Qué hace : activa la traza de tienda_web / C20_ALTA con t6 traza on, ejecuta 20 s de la aplicación y la desactiva.
#            La aplicación abre fichas con literales y, de vez en cuando, el panel de ventas.
# Efectos  : un archivo de traza *_C20.trc en el directorio de diagnóstico. Errores esperados: ninguno
source "$(dirname "$0")/../../_comun.sh"
KIT6="$(cd "$(dirname "$0")/../.." && pwd)"
titulo "1 · Activar la traza del módulo (con esperas) · t6 traza on tienda_web C20_ALTA"
bash "$KIT6/t6.sh" traza on tienda_web C20_ALTA | grep -av '^$'
titulo "2 · La aplicación trabaja 20 s (su archivo de traza se llamará *_C20.trc)"
carga C20_ALTA 1 20 "IF i = 0 THEN EXECUTE IMMEDIATE 'ALTER SESSION SET tracefile_identifier = C20'; END IF; t6.app.ficha_literal(MOD(i * 7919, 100000) + 1); IF MOD(i, 200) = 0 THEN t6.app.panel_ventas; END IF"
titulo "3 · Desactivar la traza en cuanto termina (una traza olvidada llena el disco) · t6 traza off tienda_web C20_ALTA"
bash "$KIT6/t6.sh" traza off tienda_web C20_ALTA | grep -av '^$'
