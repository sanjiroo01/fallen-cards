"""Prepara per il gioco i modelli Poly Haven (CC0) degli scenari: importa, misura, riduce i triangoli dove
serve (Decimate solo sopra il budget, silhouette e UV conservate), esporta GLB con le texture dentro.
Gli originali restano in assets_src/polyhaven/modelli, intatti.

Uso:
  blender --background --factory-startup --python-exit-code 1 --python tools/blender/scenari_props.py -- SORGENTI DESTINAZIONE
"""
import os
import sys

import bpy

# budget di triangoli per modello: dipende da quanto è grande e vicino alla telecamera
BUDGET = {
    "dead_tree_trunk_02": 14000, "dead_tree_trunk": 9000, "tree_stump_01": 9000, "tree_stump_02": 9000,
    "root_cluster_01": 14000, "rock_moss_set_01": 16000, "rock_moss_set_02": 14000, "fern_02": 6500,
    "dry_branches_medium_01": 8000, "boulder_01": 12000, "large_castle_door": 13000, "large_iron_gate": 20000,
    "gothic_statue": 16000, "lantern_chandelier_01": 6000, "wooden_candlestick": 3500, "treasure_chest": 14000,
    "lion_head": 10000, "GothicCabinet_01": 12500,
    "stone_fire_pit": 4000, "brass_candleholders": 9000,
    "wooden_lantern_01": 4000, "mountainside": 24000, "rock_face_01": 12000, "dead_quiver_trunk": 6000,
    # lago ghiacciato e cripta (16/10/2026)
    "dutch_ship_medium": 30000, "rock_face_02": 12000, "coastal_cliff_04": 30000,
    "antique_ceramic_vase_01": 4000, "marble_bust_01": 8000, "brass_goblets": 5000, "kite_shield": 5000,
}

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]
ONLY = set(argv[2:])          # facoltativo: elabora solo questi modelli
os.makedirs(DST, exist_ok=True)


def tris(objs):
    dg = bpy.context.evaluated_depsgraph_get()
    n = 0
    for o in objs:
        if o.type != "MESH":
            continue
        m = o.evaluated_get(dg).to_mesh()
        n += sum(len(p.vertices) - 2 for p in m.polygons)
        o.evaluated_get(dg).to_mesh_clear()
    return n


rows = []
for mid, budget in BUDGET.items():
    if ONLY and mid not in ONLY:
        continue
    folder = os.path.join(SRC, mid)
    gl = [f for f in os.listdir(folder) if f.endswith(".gltf")]
    if not gl:
        print("MANCA", mid)
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    gl.sort(key=lambda f: ("_4k" in f, "_2k" in f))    # la versione con le texture più definite
    bpy.ops.import_scene.gltf(filepath=os.path.join(folder, gl[-1]))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    before = tris(meshes)
    for o in meshes:
        if before > budget:
            mod = o.modifiers.new("riduci", "DECIMATE")
            mod.decimate_type = "COLLAPSE"
            mod.ratio = max(budget / before, 0.02)
            mod.use_collapse_triangulate = True
    after = tris(meshes)
    for o in meshes:
        bpy.context.view_layer.objects.active = o
        for m in list(o.modifiers):
            bpy.ops.object.modifier_apply(modifier=m.name)
    out = os.path.join(DST, mid + ".glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_image_format="AUTO",
                              export_apply=True, export_yup=True)
    rows.append((mid, before, after, os.path.getsize(out) / 1e6))
print("\nMODELLO                      PRIMA     DOPO   GLB MB")
for r in rows:
    print("%-26s %8d %8d %7.1f" % r)
