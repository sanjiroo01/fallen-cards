"""Render di anteprima veloci da Blender (per controllare i modelli)."""
import bpy
import math
from mathutils import Vector


def look_at(obj, target):
    d = Vector(target) - obj.location
    obj.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()


def render(path, cam_pos, target, lens=50, res=(900, 900), engine="CYCLES", samples=24,
           lights=True, world=0.05):
    scn = bpy.context.scene
    cam = bpy.data.objects.get("PrevCam")
    if cam is None:
        cam = bpy.data.objects.new("PrevCam", bpy.data.cameras.new("PrevCam"))
        scn.collection.objects.link(cam)
    cam.location = Vector(cam_pos)
    look_at(cam, target)
    cam.data.lens = lens
    cam.data.clip_start = 0.01
    scn.camera = cam
    if lights and bpy.data.objects.get("PrevKey") is None:
        for name, loc, e, size in [("PrevKey", (1.5, 2.5, 2.5), 220, 1.2), ("PrevFill", (-2.5, 1.5, 1.5), 60, 2.0),
                                   ("PrevRim", (0.5, -2.5, 2.5), 150, 1.0)]:
            ld = bpy.data.lights.new(name, "AREA")
            ld.energy = e
            ld.size = size
            lo = bpy.data.objects.new(name, ld)
            lo.location = loc
            scn.collection.objects.link(lo)
            look_at(lo, target)
    if scn.world is None:
        scn.world = bpy.data.worlds.new("W")
    scn.world.use_nodes = True
    bg = scn.world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (world, world, world, 1)
    scn.render.engine = engine
    if engine == "CYCLES":
        scn.cycles.samples = samples
        scn.cycles.use_denoising = True
        scn.cycles.device = "CPU"
    scn.render.resolution_x, scn.render.resolution_y = res
    scn.render.filepath = path
    scn.render.image_settings.file_format = "PNG"
    scn.view_settings.view_transform = "AgX" if "AgX" in [i.identifier for i in scn.view_settings.bl_rna.properties["view_transform"].enum_items] else "Filmic"
    bpy.ops.render.render(write_still=True)
