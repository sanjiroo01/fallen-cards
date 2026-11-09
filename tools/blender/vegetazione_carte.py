"""Fotografa gli alberelli di Poly Haven (CC0) per farne le "carte" degli aghi dei pini del gioco.

- ramo_disco.png: un abete giovane visto dall'alto (disco di aghi), da stendere sui palchi dei pini;
- abete_lato.png: lo stesso abete visto di fianco, per i pini lontani fatti di piani incrociati.
Si rende solo il colore (luce piatta) con lo sfondo trasparente: la luce la mette il gioco.

Uso:
  blender --background --factory-startup --python-exit-code 1 --python tools/blender/vegetazione_carte.py -- \
      ../assets_src/polyhaven/modelli ../assets_src/vegetazione_cc0
"""
import os
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = os.path.abspath(argv[0]), os.path.abspath(argv[1])
os.makedirs(DST, exist_ok=True)


def scene_with(model_dir, keep):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    gl = sorted(f for f in os.listdir(model_dir) if f.endswith(".gltf"))[-1]   # la più definita
    bpy.ops.import_scene.gltf(filepath=os.path.join(model_dir, gl))
    for o in list(bpy.context.scene.objects):
        if o.type == "MESH" and o.name != keep:
            bpy.data.objects.remove(o)
    ob = bpy.data.objects[keep]
    ob.location = (0, 0, 0)
    bpy.context.view_layer.update()
    pts = [ob.matrix_world @ Vector(c) for c in ob.bound_box]
    lo = Vector([min(p[i] for p in pts) for i in range(3)])
    hi = Vector([max(p[i] for p in pts) for i in range(3)])
    ob.location -= Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
    bpy.context.view_layer.update()
    return ob, hi - lo


def render(path, cam_loc, cam_rot, ortho, res_x, res_y):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sh = sc.display.shading
    sh.light = "FLAT"
    sh.color_type = "TEXTURE"
    sh.show_backface_culling = False
    sc.render.film_transparent = True
    sc.render.resolution_x = res_x
    sc.render.resolution_y = res_y
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.view_settings.view_transform = "Standard"
    sc.render.filter_size = 0.8
    cd = bpy.data.cameras.new("cam")
    cd.type = "ORTHO"
    cd.ortho_scale = ortho
    cam = bpy.data.objects.new("cam", cd)
    sc.collection.objects.link(cam)
    cam.location = cam_loc
    cam.rotation_euler = cam_rot
    sc.camera = cam
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("SCRITTO", path)


# disco di aghi: abete giovane dall'alto
ob, size = scene_with(os.path.join(SRC, "fir_sapling"), "fir_sapling_a")
side = max(size.x, size.y) * 1.02
render(os.path.join(DST, "ramo_disco.png"), (0, 0, 5), (0, 0, 0), side, 2048, 2048)

# abete di fianco (piani incrociati dei pini lontani)
ob, size = scene_with(os.path.join(SRC, "fir_sapling"), "fir_sapling_a")
h = size.z * 1.02
render(os.path.join(DST, "abete_lato.png"), (0, -5, size.z / 2), (1.5707963, 0, 0), h,
       int(2048 * size.x / size.z / 2) * 2 + 8, 2048)
print("DIMENSIONI", tuple(round(v, 3) for v in size))
