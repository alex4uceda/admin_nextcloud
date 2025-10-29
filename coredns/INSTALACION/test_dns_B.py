import time
import dns.resolver
import dns.exception
from concurrent.futures import ThreadPoolExecutor, as_completed

# Parámetros configurables
DOMINIOS = [
    "google.com", "github.com", "facebook.com", "microsoft.com", "ubuntu.com",
    "youtube.com", "play.googleapis.com", "windowsupdate.microsoft.com",
    "repo.linuxmint.com", "clients4.google.com",
    "twitter.com", "apple.com", "amazon.com", "cloudflare.com", "reddit.com",
    "stackoverflow.com", "wikipedia.org", "yahoo.com", "bing.com", "duckduckgo.com",
    "office.com", "zoom.us", "dropbox.com", "adobe.com", "salesforce.com",
    "netflix.com", "spotify.com", "whatsapp.com", "telegram.org", "tiktok.com",
    "pinterest.com", "ebay.com", "paypal.com", "imdb.com", "bbc.com",
    "cnn.com", "nytimes.com", "forbes.com", "espn.com", "booking.com",
    "airbnb.com", "wordpress.com", "live.com", "icloud.com", "slack.com",
    "github.io", "medium.com", "quora.com", "mercadolibre.com", "aliexpress.com",
    "config.edge.skype.com", "teams.microsoft.com", "ad.doubleclick.net", "jsapi.login.yahoo.com",
    "teams.events.data.microsoft.com", "statics.teams.cdn.office.net", "alpha-gpt.mail.yahoo.net",
    "api.taboola.com", "data.mail.yahoo.com", "odc.officeapps.live.com", "wnsrvbjmeprtfrnfx.ay.delivery",
    "prebid.media.net", "tlx.3lift.com", "htlb.casalemedia.com", "us-api.taboola.com",
    "bidder.criteo.com", "hbopenbid.pubmatic.com", "fastlane.rubiconproject.com",
    "c2shb-oao.ssp.yahoo.com", "ups.analytics.yahoo.com", "display.bidder.taboola.com",
    "image6.pubmatic.com", "go.trouter.teams.microsoft.com", "api.assertcom.de",
    "08fa9d47e7859ac17dfee1c9053ca7ed.safeframe.googlesyndication.com",
    "api.dtes.mh.gob.sv", "dtes.almacenesbomba.com", "static.criteo.net", "geo.yahoo.com",
    "pub-ent-uswe-06-t.trouter.teams.microsoft.com", "us-prod.asyncgw.teams.microsoft.com",
    "us-api.asm.skype.com", "tags.bluekai.com", "ecp.yusercontent.com",
    "pub-ent-uswe-10-t.trouter.teams.microsoft.com", "exo.nel.measure.office.net",
    "www.googleadservices.com", "epns.eset.com",
    "bookingholdings.com", "expedia.com", "tripadvisor.com", "agoda.com", "trivago.com",
    "kayak.com", "hotels.com", "orbitz.com", "priceline.com", "cheaptickets.com",
    "skyscanner.net", "momondo.com", "hostelworld.com", "vrbo.com", "homeaway.com",
    "opentable.com", "eventbrite.com", "ticketmaster.com", "stubhub.com", "viagogo.com",
    "office365.com", "outlook.office.com", "login.microsoftonline.com", "sharepoint.com",
    "onedrive.live.com", "graph.microsoft.com", "azure.com", "microsoftonline.com",
    "windows.com", "windowsupdate.com", "msn.com", "support.microsoft.com",
    "store.office.com", "store.microsoft.com", "powerbi.com", "teams.live.com",
    "sway.office.com", "forms.office.com", "yammer.com", "exchange.microsoft.com",
    "intune.microsoft.com", "defender.microsoft.com", "security.microsoft.com"
] * 10  # Multiplicamos para más carga

DNS_SERVIDOR = "192.168.11.10"
PETICIONES_CONCURRENTES = 100  # Número de hilos

def resolver_dominio(domain, dns_server):
    resolver = dns.resolver.Resolver()
    resolver.nameservers = [dns_server]
    resolver.cache = None
    resolver.lifetime = 5
    try:
        start = time.time()
        respuesta = resolver.resolve(domain, lifetime=5)
        duration = (time.time() - start) * 1000  # ms
        return (domain, True, duration)
    except Exception as e:
        return (domain, False, str(e))

def stress_test():
    resultados = []
    start_global = time.time()
    with ThreadPoolExecutor(max_workers=PETICIONES_CONCURRENTES) as executor:
        futures = [executor.submit(resolver_dominio, domain, DNS_SERVIDOR) for domain in DOMINIOS]
        for future in as_completed(futures):
            resultados.append(future.result())
    duracion_total = time.time() - start_global
    return resultados, duracion_total

def imprimir_resumen(resultados, duracion_total):
    exitos = [r for r in resultados if r[1]]
    fallos = [r for r in resultados if not r[1]]
    tiempos = [r[2] for r in exitos if isinstance(r[2], float)]

    print(f"\n--- Resultados del Test de Estrés DNS ---")
    print(f"Total de peticiones: {len(resultados)}")
    print(f"Éxitos: {len(exitos)}")
    print(f"Fallos: {len(fallos)}")
    print(f"Duración total: {duracion_total:.2f} segundos")
    if tiempos:
        print(f"Tiempo promedio: {sum(tiempos)/len(tiempos):.2f} ms")
        print(f"Tiempo máximo: {max(tiempos):.2f} ms")
        print(f"Tiempo mínimo: {min(tiempos):.2f} ms")
    if fallos:
        print("\nFallos:")
        for f in fallos[:10]:  # Muestra solo los primeros 10 errores
            print(f" - {f[0]}: {f[2]}")

if __name__ == "__main__":
    resultados, duracion = stress_test()
    imprimir_resumen(resultados, duracion)
