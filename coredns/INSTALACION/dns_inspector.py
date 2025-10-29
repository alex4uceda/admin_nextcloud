#!/usr/bin/env python3

import sys
import socket
import subprocess
import time
import dns.resolver
import dns.name
import dns.query
import dns.zone
from rich.console import Console
from rich.table import Table

console = Console()


def resolve_dns(domain):
    console.print(f"[bold cyan]🔎 Resolviendo registros DNS para[/bold cyan] [yellow]{domain}[/yellow]")
    resolver = dns.resolver.Resolver()
    records = ["A", "AAAA", "MX", "NS", "CNAME", "TXT", "SRV"]

    table = Table(title=f"Registros DNS para {domain}")
    table.add_column("Tipo", style="bold")
    table.add_column("Valor", style="green")
    table.add_column("Descripción", style="magenta")
    table.add_column("Tiempo (ms)", justify="right")
    table.add_column("Evaluación", justify="center")

    for record in records:
        try:
            start = time.time()
            answers = resolver.resolve(domain, record, lifetime=5)
            elapsed = (time.time() - start) * 1000  # tiempo en milisegundos

            for rdata in answers:
                desc = describe_record(record, str(rdata))
                eval_time = evaluate_resolution_time(elapsed)
                table.add_row(record, str(rdata), desc, f"{elapsed:.2f}", eval_time)

        except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN, dns.resolver.NoNameservers):
            continue
        except Exception as e:
            console.print(f"[red]Error consultando {record}: {e}[/red]")

    console.print(table)


def describe_record(rtype, value):
    if rtype == "A" or rtype == "AAAA":
        return "Servidor web o API"
    if rtype == "MX":
        return "Servidor de correo"
    if rtype == "NS":
        return "Servidor DNS autoritativo"
    if rtype == "CNAME":
        return "Alias a otro dominio (posible CDN)"
    if rtype == "TXT":
        return "Información adicional (SPF, DKIM, etc.)"
    if rtype == "SRV":
        return "Servicios específicos (VoIP, LDAP, etc.)"
    return "Registro desconocido"


def evaluate_resolution_time(ms):
    if ms < 100:
        return "[green]🟢 Rápido[/green]"
    elif ms < 300:
        return "[yellow]🟡 Medio[/yellow]"
    else:
        return "[red]🔴 Lento[/red]"


def trace_route(domain):
    console.print(f"\n[bold cyan]📡 Haciendo traceroute a[/bold cyan] [yellow]{domain}[/yellow]...\n")
    try:
        result = subprocess.run(
            ["traceroute", "-m", "15", "-w", "2", domain],
            capture_output=True,
            text=True,
            timeout=30
        )
        if result.returncode == 0:
            console.print(f"[green]{result.stdout}[/green]")
        else:
            console.print(f"[red]Error en traceroute: {result.stderr}[/red]")
    except FileNotFoundError:
        console.print("[red]⚠️ traceroute no está instalado. Instálalo con sudo apt install traceroute[/red]")
    except subprocess.TimeoutExpired:
        console.print("[red]⏳ Traceroute excedió el tiempo de espera (30s).[/red]")
    except KeyboardInterrupt:
        console.print("[yellow]⏹️ Cancelado por el usuario (Ctrl+C).[/yellow]")


def main():
    if len(sys.argv) != 2:
        console.print("[red]Uso:[/red] python dns_inspector.py <dominio>")
        sys.exit(1)

    domain = sys.argv[1]
    resolve_dns(domain)
    trace_route(domain)


if __name__ == "__main__":
    main()
