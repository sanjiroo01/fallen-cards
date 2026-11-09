"""Prova di PROGETTO Live: colora per un momento la mantellina della COPIA nella vista 3D
(colore di visualizzazione dell'oggetto: non tocca materiali né geometria), inquadra,
salva un'anteprima, poi rimette tutto com'era."""
import time

import bpy

COLORI = {"blu": (0.1, 0.25, 0.9, 1.0), "verde": (0.1, 0.7, 0.2, 1.0), "oro": (0.9, 0.65, 0.1, 1.0)}


def run(live, colore="blu", attesa=2.0, oggetto="Mantellina"):
    ob = bpy.data.objects.get(str(oggetto))
    if ob is None:
        return "oggetto %s non trovato nel file aperto" % oggetto
    live.passo("Inquadro: " + ob.name)
    live.inquadra([ob.name])
    viste = []
    for win in bpy.context.window_manager.windows:
        for area in win.screen.areas:
            if area.type == "VIEW_3D":
                sh = area.spaces.active.shading
                viste.append((sh, sh.type, sh.color_type))
                sh.type = "SOLID"
                sh.color_type = "OBJECT"
    prima = tuple(ob.color)
    live.passo("Coloro %s di %s (solo prova, solo nella vista)" % (ob.name, colore))
    ob.color = COLORI.get(colore, COLORI["blu"])
    live.ridisegna()
    foto = live.anteprima("prova_" + colore)
    time.sleep(max(0.0, min(float(attesa), 10.0)))
    live.passo("Rimetto tutto com'era")
    ob.color = prima
    for sh, t, ct in viste:
        sh.type, sh.color_type = t, ct
    live.ridisegna()
    return {"anteprima": foto}
