"""Scarica da Poly Haven (CC0) modelli (glTF 1k) e texture (2k: colore, rilievo, ruvidezza) in
assets_src/polyhaven, e aggiunge la riga in FONTI.txt. Quello che c'è già non viene riscaricato.

Uso (con un Python qualsiasi, anche quello di Blender):
  python -I tools/scarica_polyhaven.py modello:dutch_ship_medium texture:monastery_stone_floor ...
  modello:NOME@2k scarica le texture del modello a 2k (lo strumento di Blender sceglie la più definita).
"""
import datetime
import json
import os
import sys
import urllib.request

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "assets_src", "polyhaven"))
UA = {"User-Agent": "PROGETTO-asset-download"}


def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=120).read()


def save(url, path):
    if os.path.exists(path):
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = get(url)
    with open(path, "wb") as f:
        f.write(data)


def model(aid, res="1k"):
    files = json.loads(get("https://api.polyhaven.com/files/" + aid))
    g = files["gltf"][res]["gltf"]
    folder = os.path.join(ROOT, "modelli", aid)
    save(g["url"], os.path.join(folder, os.path.basename(g["url"])))
    for rel, inc in g.get("include", {}).items():
        save(inc["url"], os.path.join(folder, rel))


def texture(aid):
    files = json.loads(get("https://api.polyhaven.com/files/" + aid))
    folder = os.path.join(ROOT, "texture", aid)
    for key, name in [("Diffuse", "diff"), ("nor_gl", "nor_gl"), ("Rough", "rough")]:
        f = files[key]["2k"]["jpg"]
        save(f["url"], os.path.join(folder, "%s_%s_2k.jpg" % (aid, name)))


def main():
    fonti = os.path.join(ROOT, "FONTI.txt")
    have = open(fonti, encoding="utf-8").read() if os.path.exists(fonti) else ""
    for arg in sys.argv[1:]:
        kind, aid = arg.split(":", 1)
        res = "1k"
        if "@" in aid:                     # modello:NOME@2k = texture più definite
            aid, res = aid.split("@", 1)
        if kind == "modello":
            model(aid, res)
        else:
            texture(aid)
        line = "%s %s https://polyhaven.com/a/%s CC0" % (kind, aid, aid)
        if line not in have:
            with open(fonti, "a", encoding="utf-8") as f:
                f.write(line + "\n")
            have += line
        print("ok", kind, aid)
    print("fatto", datetime.date.today())


if __name__ == "__main__":
    main()
