#!/usr/bin/env bash
# scripts/deployment/env/00-config.sh
export CONT_NAME="oralab-26ai"
export VOL_NAME="oralab-26ai-data"
export IMG="container-registry.oracle.com/database/free:latest"
export PORT_DB=1521
export PORT_ORDS=8181
export SERVICE_CDB="FREE"
export SERVICE_PDB="FREEPDB1"
export BACKUP_DIR="$(pwd)/backups"
export EVID="docs/bitacora/evidencia"
ts() { date -u +%Y%m%dT%H%M%SZ; }
