#!/bin/bash

set -euo pipefail

# Configuración
DNS_IP="127.0.0.1"
DNS_PORT="53"
CONTAINER_NAME="coredns"
REPORTE_HTML="reporte_dns.html"
REPORTE_CSV="reporte_dns.csv"
MAX_LATENCIA_MS=100

DOMINIOS=(
    "google.com"
    "microsoft.com"
    "ubuntu.com"
    "grupomapa.services"
    "bomba.sim.services"
    "premium.sim.services"
    "gtboom.sim.services"
    "gtpremium.sim.services"
    "svinprocasa.sim.services"
    "svmegatelas.sim.services"
    "localhost"
)
REGISTROS=("A" "AAAA" "MX" "CNAME" "TXT")

# Inicializar reportes
echo "Dominio,Registro,Resultado,Tiempo(ms),Error" > "$REPORTE_CSV"
echo "<html><head><title>Auditoría DNS</title></head><body>" > "$REPORTE_HTML"
echo "<h1>Reporte Auditoría DNS</h1><table border='1'><tr><th>Dominio</th><th>Registro</th><th>Resultado</th><th>Tiempo (ms)</th><th>Error</th></tr>" >> "$REPORTE_HTML"

# Función para registrar resultados
registrar_resultado() {
    local dominio=$1
    local tipo=$2
    local resultado=$3
    local tiempo=$4
    local error=$5

    echo "$dominio,$tipo,\"$resultado\",$tiempo,$error" >> "$REPORTE_CSV"
    echo "<tr><td>$dominio</td><td>$tipo</td><td>$resultado</td><td>$tiempo</td><td>$error</td></tr>" >> "$REPORTE_HTML"
}

# Verificar contenedor DNS
echo "🔍 Verificando contenedor '$CONTAINER_NAME'..."
if ! docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "❌ Contenedor DNS no está activo."
    registrar_resultado "GENERAL" "Contenedor" "No activo" "N/A" "FAIL"
    exit 1
else
    echo "✅ Contenedor DNS activo."
    restart_count=$(docker inspect --format='{{.RestartCount}}' "$CONTAINER_NAME")
    if (( restart_count > 0 )); then
        echo "⚠️ Contenedor DNS ha reiniciado $restart_count veces."
        registrar_resultado "GENERAL" "Contenedor" "Reinicios: $restart_count" "N/A" "WARNING"
    fi
fi

# Test resolución desde host
echo "🧪 Iniciando pruebas de resolución..."
for dominio in "${DOMINIOS[@]}"; do
    for tipo in "${REGISTROS[@]}"; do
        resultado=$(dig @$DNS_IP -p $DNS_PORT "$dominio" $tipo +time=3 +tries=2 +short)
        query_time=$(dig @$DNS_IP -p $DNS_PORT "$dominio" $tipo +stats | grep "Query time" | awk '{print $4}' || echo "N/A")

        if [[ -z "$resultado" ]]; then
            registrar_resultado "$dominio" "$tipo" "N/A" "$query_time" "FAIL"
        else
            if [[ "$query_time" != "N/A" && "$query_time" -gt "$MAX_LATENCIA_MS" ]]; then
                registrar_resultado "$dominio" "$tipo" "$resultado" "$query_time" "SLOW"
            else
                registrar_resultado "$dominio" "$tipo" "$resultado" "$query_time" "OK"
            fi
        fi
    done
done

# Stress-test
echo "🔥 Ejecutando stress-test (1000 consultas a google.com)..."
if ! command -v parallel >/dev/null 2>&1; then
    echo "⚠️ 'parallel' no está instalado. Instalando..."
    sudo apt-get install -y parallel
fi
seq 1 1000 | parallel -j50 dig @$DNS_IP -p $DNS_PORT google.com +short >/dev/null 2>&1
registrar_resultado "STRESS-TEST" "1000 consultas" "Completado" "N/A" "OK"

# Test resolución desde contenedores Docker
echo "📦 Probando resolución DNS desde todos los contenedores..."
for c in $(docker ps --format '{{.Names}}'); do
    for dominio in "${DOMINIOS[@]}"; do
        res=$(docker exec "$c" dig @$DNS_IP "$dominio" +short || echo "FAIL")
        if [[ -z "$res" || "$res" == "FAIL" ]]; then
            registrar_resultado "$dominio" "Desde $c" "N/A" "N/A" "FAIL"
        else
            registrar_resultado "$dominio" "Desde $c" "$res" "N/A" "OK"
        fi
    done
done

# Cerrar reporte HTML
echo "</table></body></html>" >> "$REPORTE_HTML"

echo "✅ Auditoría completada. Reportes:"
echo "   • $REPORTE_CSV"
echo "   • $REPORTE_HTML"
