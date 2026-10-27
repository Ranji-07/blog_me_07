import bpy

scene = bpy.context.scene
scene.frame_set(scene.frame_start)
for obj in bpy.data.objects:
    for modifier in obj.modifiers:
        if modifier.type == 'CLOTH':
            cache = modifier.point_cache
            cache.frame_start = scene.frame_start
            cache.frame_end = scene.frame_end

try:
    bpy.ops.ptcache.free_bake_all()
except RuntimeError as exc:
    print('FREE_BAKE_NOTICE=' + str(exc))

scene.frame_set(scene.frame_start)
bpy.ops.ptcache.bake_all(bake=True)
bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
print('REBAKE_COMPLETE=' + bpy.data.filepath)