"""Client di PROGETTO Live: manda un comando ammesso alla finestra di Blender collegata.

Uso (con il Python incluso in Blender, nessuna installazione):
  python client.py stato
  python client.py messaggio '{"testo": "Sistemo l'orlo"}'
  python client.py apri_copia '{"originale": "<nome del file>"}'
  python client.py azione '{"nome": "prova_live", "args": {"colore": "blu"}}'
  python client.py anteprima '{"nome": "orlo", "tipo": "vista"}'
  python client.py inquadra '{"oggetti": ["Mantellina"]}'
  python client.py annulla | salva
"""
import json
import os
import socket
import sys

CONN = os.path.join(os.environ.get("LOCALAPPDATA", os.path.expanduser("~")), "PROGETTO_live", "connessione.json")


def manda(cmd, args=None, timeout=1800):
    if not os.path.isfile(CONN):
        raise SystemExit("PROGETTO Live non è collegato: in Blender premi 'Collega Claude' (barra laterale N > PROGETTO)")
    with open(CONN, encoding="utf8") as f:
        c = json.load(f)
    with socket.create_connection(("127.0.0.1", c["port"]), timeout=10) as s:
        s.settimeout(timeout)
        s.sendall((json.dumps({"token": c["token"], "cmd": cmd, "args": args or {}}) + "\n").encode("utf8"))
        dati = b""
        while not dati.endswith(b"\n"):
            pezzo = s.recv(65536)
            if not pezzo:
                break
            dati += pezzo
    return json.loads(dati.decode("utf8"))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    r = manda(sys.argv[1], json.loads(sys.argv[2]) if len(sys.argv) > 2 else None)
    print(json.dumps(r, ensure_ascii=False, indent=1))
    sys.exit(0 if r.get("ok") else 1)
