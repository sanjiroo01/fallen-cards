"""Estrae dalla "foresta di notte" (dasy444, CC BY 4.0) i modelli campione della vegetazione, li porta a
grandezza reale e li esporta come GLB singoli per gli scenari.
Gli originali restano in assets_src/sketchfab/foresta_notte, intatti.

Uso:
  blender --background --factory-startup --python-exit-code 1 --python tools/blender/foresta_vegetazione.py -- FBX DESTINAZIONE
"""
import os
import sys

import bpy

SCALA = 5.5        # nel file un pino alto è 2,6 unità: a grandezza reale circa 14 metri
# oggetto nel file -> nome nel gioco
PEZZI = {
    "Cylinder.001": "pino_alto",
    "Cylinder.019": "pino_basso",
    "Plane.005": "cespuglio_a",
    "Plane.006": "cespuglio_b",
    "Plane.001": "erba_a",
    "Plane.003": "erba_b",
}
PREFISSI = {   # oggetti con nomi lunghi: si riconoscono dall'inizio del nome
    "05ade0e7": "albero_foglie",
    "cc24eba7": "arbusto_a",
    "3f84aea6": "arbusto_b",
}

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]
os.makedirs(DST, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=SRC)

scelti = {}
for o in bpy.context.scene.objects:
    if o.type != "MESH" or o.matrix_world.translation.x > -5.5:
        continue
    nome = PEZZI.get(o.name)
    if nome is None:
        for pre, n in PREFISSI.items():
            if o.name.startswith(pre):
                nome = n
    if nome:
        scelti[nome] = o
print("TROVATI", sorted(scelti))

for nome, o in scelti.items():
    for x in bpy.context.scene.objects:
        x.select_set(False)
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    # appoggiato a terra al centro, a grandezza reale
    base = min((o.matrix_world @ v.co).z for v in o.data.vertices)
    o.location.x -= o.matrix_world.translation.x
    o.location.y -= o.matrix_world.translation.y
    o.location.z -= base
    o.scale = o.scale * SCALA
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    out = os.path.join(DST, nome + ".glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_image_format="AUTO",
                              export_yup=True, export_apply=True)
    print("ESPORTATO %-14s altezza %.1f m  %.1f MB" % (nome, o.dimensions.z, os.path.getsize(out) / 1e6))
