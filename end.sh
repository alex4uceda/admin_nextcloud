#!/usr/bin/env bash
set -euo pipefail

RESOLV_BACKUP="/etc/resolv.conf.backup-coredns"
RESOLV_STUB="/run/systemd/resolve/stub-resolv.conf"

need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Este script requiere sudo/root. Vuelve a ejecutarlo con: sudo $0" >&2
    exit 1
  fi
}

check_tools() {
  command -v docker >/dev/null || true
  if docker compose version >/dev/null 2>&1; then
    export COMPOSE="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    export COMPOSE="docker-compose"
  else
    export COMPOSE=""
  fi
}

stop_coredns_container() {
  if [[ -n "$COMPOSE" ]]; then
    # Solo si existe el servicio
    if $COMPOSE config --services 2>/dev/null | grep -q '^coredns$'; then
      echo "Deteniendo contenedor 'coredns' para liberar el puerto 53..."
      $COMPOSE stop coredns || true
    fi
  else
    # fallback: intenta por nombre
    if docker ps -a --format '{{.Names}}' | grep -q '^coredns$'; then
      docker stop coredns || true
    fi
  fi
}

restore_resolv_conf() {
  # Si tenemos backup, restaurarlo
  if [[ -f "${RESOLV_BACKUP}" ]]; then
    echo "Restaurando /etc/resolv.conf desde backup..."
    rm -f /etc/resolv.conf || true
    cp -a "${RESOLV_BACKUP}" /etc/resolv.conf
  else
    # Si no hay backup, usar symlink típico de systemd-resolved
    echo "No hay backup; configurando symlink estándar a stub-resolv.conf..."
    rm -f /etc/resolv.conf || true
    ln -s "${RESOLV_STUB}" /etc/resolv.conf
  fi
}

start_systemd_resolved() {
  echo "Iniciando systemd-resolved..."
  systemctl start systemd-resolved
  systemctl is-active --quiet systemd-resolved && echo "systemd-resolved está activo."
}

main() {
  need_root
  check_tools
  stop_coredns_container
  restore_resolv_conf
  start_systemd_resolved
  echo "Restauración completa. DNS del sistema vuelve a systemd-resolved."
}

main "$@"
