#!/usr/bin/env bash
# C23 · diagnosticar · el inventario completo con la herramienta del kit: t6 indices PEDIDO
KIT6="$(cd "$(dirname "$0")/../.." && pwd)"
bash "$KIT6/t6.sh" indices PEDIDO
echo "   -- Lectura: (1) redundancia: IX_T6_PED_CLIENTE (id_cliente) es el prefijo de IX_C23_CLI_FECHA; (2) el factor de"
echo "   -- agrupamiento dice si un rango por ese índice lee pocos bloques o casi una fila por bloque; (3) el uso registrado"
echo "   -- se vuelca cada ~15 min y no cuenta las consultas de SYS: un índice «sin uso» hoy no prueba nada."
echo "   -- Si hiciste C14, verás también IX_T6_PED_ESTADO cubierto por IX_T6_C14_PEND: el inventario encuentra lo que nadie recuerda."
