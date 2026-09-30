#!/usr/bin/env bash
source scripts/deployment/env/00-config.sh
echo "== Descarga o confirmacion de la imagen =="
docker pull "$IMG"
echo
echo "== Imagen local y su digest (version exacta instalada) =="
docker images --digests container-registry.oracle.com/database/free
