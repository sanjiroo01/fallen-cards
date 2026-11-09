"""Ispeziona un modello di scenario (FBX/glTF): elenca oggetti, triangoli, materiali e immagini, misura
l'ingombro e salva due anteprime (dall'alto e di tre quarti).

Uso:
  blender --background --factory-startup --python-exit-code 1 --python tools/blender/ispeziona_scenario.py -- FILE CARTELLA_ANTEPRIME
"""
import math
import os
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, OUT = argv[0], argv[1]
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
if SRC.lower().endswith(".fbx"):
    bpy.ops.import_scene.fbx(filepath=SRC)
else:
    bpy.ops.import_scene.gltf(filepath=SRC)

dg = bpy.context.evaluated_depsgraph_get()
lo = Vector((1e9, 1e9, 1e9))
hi = Vector((-1e9, -1e9, -1e9))
total = 0
rows = []
for o in bpy.context.scene.objects:
    if o.type != "MESH":
        continue
    m = o.evaluated_get(dg).to_mesh()
    t = sum(len(p.vertices) - 2 for p in m.polygons)
    o.evaluated_get(dg).to_mesh_clear()
    total += t
    for c in o.bound_box:
        w = o.matrix_world @ Vector(c)
        lo = Vector(map(min, lo, w))
        hi = Vector(map(max, hi, w))
    mats = ",".join(s.material.name for s in o.material_slots if s.material)
    rows.append((t, o.name, o.data.name, mats, tuple(round(v, 2) for v in o.dimensions)))
rows.sort(reverse=True)
print("OGGETTI %d, TRIANGOLI %d" % (len(rows), total))
print("INGOMBRO da %s a %s (dimensioni %s)" % (tuple(round(v, 2) for v in lo), tuple(round(v, 2) for v in hi),
                                               tuple(round(v, 2) for v in (hi - lo))))
for r in rows[:60]:
    print("%8d  %-40s mesh=%-30s mat=%s dim=%s" % r)
print("MATERIALI:")
for m in bpy.data.materials:
    imgs = []
    if m.use_nodes:
        for n in m.node_tree.nodes:
            if n.type == "TEX_IMAGE" and n.image:
                imgs.append(os.path.basename(n.image.filepath))
    print("  %s -> %s" % (m.name, imgs))

# anteprime
center = (lo + hi) / 2
size = max((hi - lo).x, (hi - lo).y, 1.0)
sun = bpy.data.objects.new("sole", bpy.data.lights.new("sole", "SUN"))
sun.data.energy = 3.0
sun.rotation_euler = (math.radians(50), 0, math.radians(30))
bpy.context.scene.collection.objects.link(sun)
bpy.context.scene.world = bpy.data.worlds.new("cielo")
bpy.context.scene.world.color = (0.3, 0.33, 0.4)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
bpy.context.scene.collection.objects.link(cam)
bpy.context.scene.camera = cam
sc = bpy.context.scene
sc.render.engine = "BLENDER_EEVEE"
sc.render.resolution_x = 1400
sc.render.resolution_y = 900
for name, pos in [("alto", center + Vector((0, 0, size * 1.1))),
                  ("tre_quarti", center + Vector((size * 0.6, -size * 0.6, size * 0.45)))]:
    cam.location = pos
    d = center - pos
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    cam.data.clip_end = size * 5
    sc.render.filepath = os.path.join(OUT, name + ".png")
    bpy.ops.render.render(write_still=True)
print("ANTEPRIME in", OUT)
