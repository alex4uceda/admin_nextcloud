#!/usr/bin/env bash
set -euo pipefail

# === Config ===
DNS_PORT_TCP=53
DNS_PORT_UDP=53
BACKUP_DIR="/etc"
RESOLV_BACKUP="${BACKUP_DIR}/resolv.conf.backup-coredns"
RESOLV_RUN="/run/systemd/resolve/resolv.conf"
RESOLV_STUB="/run/systemd/resolve/stub-resolv.conf"

need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Este script requiere sudo/root. Vuelve a ejecutarlo con: sudo $0" >&2
    exit 1
  fi
}

check_tools() {
  command -v docker >/dev/null || { echo "Falta 'docker'." >&2; exit 1; }
  # 'docker compose' moderno; si no, intenta 'docker-compose'
  if docker compose version >/dev/null 2>&1; then
    export COMPOSE="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    export COMPOSE="docker-compose"
  else
    echo "No encontré 'docker compose' ni 'docker-compose'." >&2
    exit 1
  fi
  command -v ss >/dev/null || true
}

backup_resolv() {
  if [[ -f /etc/resolv.conf && ! -f "${RESOLV_BACKUP}" ]]; then
    cp -a /etc/resolv.conf "${RESOLV_BACKUP}"
    echo "Backup de /etc/resolv.conf creado en ${RESOLV_BACKUP}"
  fi
}

stop_systemd_resolved() {
  if systemctl is-active --quiet systemd-resolved; then
    echo "Deteniendo systemd-resolved..."
    systemctl stop systemd-resolved
  else
    echo "systemd-resolved ya está detenido."
  fi
}

prepare_resolv_conf() {
  # Si /etc/resolv.conf es un symlink, reemplazar por archivo plano
  if [[ -L /etc/resolv.conf ]]; then
    rm -f /etc/resolv.conf
  fi

  cat >/etc/resolv.conf <<'EOF'
# resolv.conf para usar CoreDNS local primero
nameserver 127.0.0.1
# Fallback público por si CoreDNS tarda en levantar
nameserver 1.1.1.1
options edns0
EOF
  chmod 644 /etc/resolv.conf
  echo "/etc/resolv.conf apuntando a 127.0.0.1 (fallback 1.1.1.1)"
}

ensure_proxy_net() {
  if ! docker network inspect proxy_net >/dev/null 2>&1; then
    echo "Creando red externa 'proxy_net'..."
    docker network create proxy_net >/dev/null
  fi
}

start_coredns_first() {
  echo "Levantando servicio 'coredns' primero..."
  $COMPOSE up -d coredns

  echo "Esperando a que el puerto 53 esté escuchando..."
  # Intento simple: verificar binding TCP/UDP. No siempre es perfecto, pero útil.
  for i in {1..20}; do
    TCP_OK=0; UDP_OK=0
    if ss -ltn 2>/dev/null | grep -q ":${DNS_PORT_TCP} "; then TCP_OK=1; fi
    if ss -lun 2>/dev/null | grep -q ":${DNS_PORT_UDP} "; then UDP_OK=1; fi
    if [[ $TCP_OK -eq 1 && $UDP_OK -eq 1 ]]; then
      echo "CoreDNS parece estar escuchando en TCP/UDP :53."
      return 0
    fi
    sleep 1
  done
  echo "Aviso: no pude confirmar el binding en :53, continuo de todas formas." >&2
}

start_rest_of_stack() {
  echo "Levantando el resto de servicios (excluyendo coredns)..."
  # Detectar servicios definidos y excluir coredns
  mapfile -t services < <($COMPOSE config --services | grep -v '^coredns$' || true)
  if [[ ${#services[@]} -gt 0 ]]; then
    $COMPOSE up -d "${services[@]}"
  else
    echo "No se detectaron otros servicios en el compose."
  fi
}

main() {
  need_root
  check_tools
  backup_resolv
  stop_systemd_resolved
  prepare_resolv_conf
  ensure_proxy_net
  start_coredns_first
  start_rest_of_stack

  echo "Listo. CoreDNS arriba y luego el resto del stack."
  echo "Para restaurar systemd-resolved, ejecuta: sudo ./02-restore-resolved.sh"
}

main "$@"
