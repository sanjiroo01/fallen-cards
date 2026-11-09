"""Costruisce la vegetazione del gioco solo da materiale CC0 di Poly Haven (al posto del pacchetto di dasy444).

Pini: tronco con la corteccia di pine_sapling_small, palchi di aghi fatti con ramo_disco.png (abete giovane
fir_sapling visto dall'alto, reso da vegetazione_carte.py); il pino lontano è fatto di piani incrociati con
abete_lato.png. Cespugli ed erba: modelli Poly Haven (shrub_02, grass_medium_01/02, nettle_plant), uniti in
un solo oggetto e alleggeriti.

Uso (prima vegetazione_carte.py):
  blender --background --factory-startup --python-exit-code 1 --python tools/blender/vegetazione_alberi.py -- \
      ../assets_src/polyhaven/modelli ../assets_src/vegetazione_cc0 assets/scenari/vegetazione_cc0
"""
import math
import os
import random
import shutil
import sys

import bmesh
import numpy as np
import bpy
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, CARDS, DST = (os.path.abspath(a) for a in argv[:3])
BARK = os.path.join(SRC, "pine_sapling_small", "textures", "pine_sapling_small_bark_%s_2k.jpg")


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def image_mat(name, color_path, alpha=False, normal_path=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(color_path)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.9
    if alpha:
        nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
        m.blend_method = "CLIP" if hasattr(m, "blend_method") else m.blend_method
    if normal_path:
        nt_img = nt.nodes.new("ShaderNodeTexImage")
        nt_img.image = bpy.data.images.load(normal_path)
        nt_img.image.colorspace_settings.name = "Non-Color"
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nt.links.new(nt_img.outputs["Color"], nm.inputs["Color"])
        nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    return m


def export(name, objs):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    ob.name = name
    path = os.path.join(DST, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, use_selection=True, export_format="GLB",
                              export_image_format="AUTO", export_yup=True)
    tri = sum(len(p.vertices) - 2 for p in ob.data.polygons)
    dims = tuple(round(v, 2) for v in ob.dimensions)
    print("ESPORTATO", name, "triangoli", tri, "misure", dims)


# ------------------------------------------------------------------ pini

def trunk(bm, uv, h, r0, r1, sides=10, rng=None):
    rings = 7
    verts = []
    for k in range(rings + 1):
        t = k / rings
        z = h * t
        r = r0 + (r1 - r0) * t
        if k == 0:
            r *= 1.35            # piede del tronco che si allarga nel terreno
        ring = []
        for i in range(sides + 1):
            a = math.tau * i / sides
            wob = 1.0 + (rng.uniform(-0.06, 0.06) if rng and i < sides else 0.0)
            ring.append(bm.verts.new((math.cos(a) * r * wob, math.sin(a) * r * wob, z - 0.3 * (k == 0))))
        verts.append(ring)
    bm.verts.ensure_lookup_table()
    for k in range(rings):
        for i in range(sides):
            f = bm.faces.new((verts[k][i], verts[k][i + 1], verts[k + 1][i + 1], verts[k + 1][i]))
            f.material_index = 0
            for lp, (iu, kv) in zip(f.loops, ((i, k), (i + 1, k), (i + 1, k + 1), (i, k + 1))):
                lp[uv].uv = (2.0 * iu / sides, h * kv / rings / 1.2)


def stub(bm, uv, base, direction, length, r):
    """Moncone di ramo secco sul tronco nudo."""
    sides = 5
    d = direction.normalized()
    side = d.cross(Vector((0, 0, 1))).normalized()
    up = side.cross(d).normalized()
    rings = []
    for k, (p, rr) in enumerate(((base, r), (base + d * length, r * 0.25))):
        ring = []
        for i in range(sides + 1):
            a = math.tau * i / sides
            ring.append(bm.verts.new(p + (side * math.cos(a) + up * math.sin(a)) * rr))
        rings.append(ring)
    for i in range(sides):
        f = bm.faces.new((rings[0][i], rings[0][i + 1], rings[1][i + 1], rings[1][i]))
        f.material_index = 0
        for lp, (u, v) in zip(f.loops, ((i / sides, 0), ((i + 1) / sides, 0), ((i + 1) / sides, 1), (i / sides, 1))):
            lp[uv].uv = (u * 0.5, v * length)


def whorl(bm, uv, z, radius, droop, rot, rng, segs=14):
    """Un palco di rami: un ombrello di aghi spiovente, col disco di aghi steso sopra."""
    radii = (0.06, radius * 0.45, radius)
    drops = (0.0, droop * 0.25, droop)
    jitter = [rng.uniform(0.82, 1.12) for _ in range(segs)]
    rings = []
    for k, (r, dz) in enumerate(zip(radii, drops)):
        ring = []
        for i in range(segs):
            a = math.tau * i / segs
            rr = r * (jitter[i] if k == 2 else 1.0)
            ring.append(bm.verts.new((math.cos(a) * rr, math.sin(a) * rr, z - dz * (jitter[i] if k == 2 else 1.0))))
        rings.append(ring)
    c, s = math.cos(rot), math.sin(rot)
    for k in range(2):
        for i in range(segs):
            j = (i + 1) % segs
            f = bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
            f.material_index = 1
            for lp in f.loops:
                x, y = lp.vert.co.x / (radius * 2.1), lp.vert.co.y / (radius * 2.1)
                lp[uv].uv = (0.5 + x * c - y * s, 0.5 + x * s + y * c)


def spire(bm, uv, z, h, w):
    """Cima: due piani incrociati con l'abete di fianco."""
    for a in (0.0, math.pi / 2):
        dx, dy = math.cos(a) * w / 2, math.sin(a) * w / 2
        vs = [bm.verts.new(p) for p in ((-dx, -dy, z), (dx, dy, z), (dx, dy, z + h), (-dx, -dy, z + h))]
        f = bm.faces.new(vs)
        f.material_index = 2
        for lp, u in zip(f.loops, ((0, 0), (1, 0), (1, 1), (0, 1))):
            lp[uv].uv = u


def pine(name, h, crown_from, rmax, seed, n_whorls):
    reset()
    rng = random.Random(seed)
    me = bpy.data.meshes.new(name)
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    trunk(bm, uv, h - 0.8, 0.06 + h * 0.009, 0.03, rng=rng)
    # monconi secchi sul tronco nudo
    for k in range(int(crown_from / 0.9)):
        z = rng.uniform(0.9, crown_from)
        a = rng.uniform(0, math.tau)
        d = Vector((math.cos(a), math.sin(a), rng.uniform(-0.5, 0.1)))
        stub(bm, uv, Vector((0, 0, z)), d, rng.uniform(0.25, 0.7), 0.025)
    # palchi: dal basso (larghi e spioventi) alla cima (piccoli)
    for k in range(n_whorls):
        t = k / (n_whorls - 1)
        z = crown_from + (h - 1.0 - crown_from) * (t ** 0.92) + rng.uniform(-0.1, 0.1)
        r = rmax * (1.0 - t) ** 0.85 * rng.uniform(0.85, 1.1) + 0.28
        whorl(bm, uv, z, r, r * rng.uniform(0.38, 0.55), rng.uniform(0, math.tau), rng)
        if r > 1.1 and k % 2 == 0:      # secondo strato più stretto: chioma più piena
            whorl(bm, uv, z + 0.18, r * 0.7, r * 0.3, rng.uniform(0, math.tau), rng, segs=10)
    spire(bm, uv, h - 1.6, 1.8, 0.95)
    bm.to_mesh(me)
    bm.free()
    for m in (image_mat(name + "_corteccia", BARK % "diff", normal_path=BARK % "nor_gl"),
              image_mat(name + "_aghi", os.path.join(CARDS, "ramo_disco.png"), alpha=True),
              image_mat(name + "_cima", os.path.join(CARDS, "abete_lato.png"), alpha=True)):
        me.materials.append(m)
    export(name, [ob])


def far_pine(name, h):
    """Pino lontano: tre piani incrociati con l'abete di fianco e poche facce."""
    reset()
    me = bpy.data.meshes.new(name)
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    w = h * 0.5
    for k in range(3):
        a = math.pi * k / 3
        dx, dy = math.cos(a) * w / 2, math.sin(a) * w / 2
        vs = [bm.verts.new(p) for p in ((-dx, -dy, -0.3), (dx, dy, -0.3), (dx, dy, h), (-dx, -dy, h))]
        f = bm.faces.new(vs)
        for lp, u in zip(f.loops, ((0, 0), (1, 0), (1, 1), (0, 1))):
            lp[uv].uv = u
    bm.to_mesh(me)
    bm.free()
    me.materials.append(image_mat(name + "_aghi", os.path.join(CARDS, "abete_lato.png"), alpha=True))
    export(name, [ob])


# ------------------------------------------------------------------ cespugli ed erba (modelli Poly Haven)

def plant(name, model, parts, budget):
    reset()
    folder = os.path.join(SRC, model)
    gl = [f for f in os.listdir(folder) if f.endswith(".gltf")][0]
    bpy.ops.import_scene.gltf(filepath=os.path.join(folder, gl))
    keep = []
    for o in list(bpy.context.scene.objects):
        if o.type == "MESH" and o.name in parts:
            keep.append(o)
        elif o.type == "MESH":
            bpy.data.objects.remove(o)
    # ogni pezzo con la base sull'origine, poi uniti
    for i, o in enumerate(keep):
        bpy.context.view_layer.update()
        pts = [o.matrix_world @ Vector(c) for c in o.bound_box]
        cx = sum(p.x for p in pts) / 8
        cy = sum(p.y for p in pts) / 8
        lo = min(p.z for p in pts)
        off = Vector(((i % 2) * 0.35 - 0.17, (i // 2) * 0.3 - 0.15, 0)) if len(keep) > 1 else Vector()
        o.location += Vector((-cx, -cy, -lo)) + off
    bpy.ops.object.select_all(action="DESELECT")
    for o in keep:
        o.select_set(True)
    bpy.context.view_layer.objects.active = keep[0]
    if len(keep) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    # Poly Haven dà la trasparenza delle foglie a parte: la si mette nel colore (immagine con trasparenza)
    alpha_path = os.path.join(folder, "textures", model + "_alpha_1k.png")
    for m in ob.data.materials:
        nt = m.node_tree
        bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
        link = bsdf.inputs["Base Color"].links[0]
        src = link.from_node.image
        al = bpy.data.images.load(alpha_path)
        w, h = src.size
        if tuple(al.size) != (w, h):
            al.scale(w, h)
        px = np.array(src.pixels[:], dtype=np.float32).reshape(-1, 4)
        pa = np.array(al.pixels[:], dtype=np.float32).reshape(-1, 4)
        px[:, 3] = pa[:, 0]
        out = bpy.data.images.new(name + "_foglie", w, h, alpha=True)
        out.pixels[:] = px.ravel()
        out.filepath_raw = os.path.join(CARDS, name + "_foglie.png")
        out.file_format = "PNG"
        out.save()
        link.from_node.image = out
        nt.links.new(link.from_node.outputs["Alpha"], bsdf.inputs["Alpha"])
    tri = sum(len(p.vertices) - 2 for p in ob.data.polygons)
    if tri > budget:
        mod = ob.modifiers.new("riduci", "DECIMATE")
        mod.ratio = budget / tri
        bpy.ops.object.modifier_apply(modifier=mod.name)
    export(name, [ob])


os.makedirs(DST, exist_ok=True)
pine("pino_alto", 14.0, 6.0, 1.8, 11, 13)
pine("pino_medio", 10.5, 3.6, 1.7, 23, 11)
pine("pino_basso", 7.0, 1.4, 1.5, 37, 9)
far_pine("pino_lontano", 13.0)
plant("cespuglio_a", "shrub_02", ["shrub_02_b"], 3000)
plant("cespuglio_b", "shrub_02", ["shrub_02_d"], 3000)
plant("arbusto_a", "nettle_plant", ["nettle_plant_tall_a_LOD0", "nettle_plant_tall_b_LOD0",
                                    "nettle_plant_medium_a_LOD0", "nettle_plant_medium_b_LOD0"], 6000)
plant("arbusto_b", "shrub_03", ["shrub_03_a", "shrub_03_b", "shrub_03_c", "shrub_03_d"], 5000)
plant("erba_a", "grass_medium_01", ["grass_medium_01_large_a_LOD0"], 2500)
plant("erba_b", "grass_medium_02", ["grass_medium_02_e", "grass_medium_02_d"], 2500)
