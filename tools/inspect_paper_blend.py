import bpy

scene = bpy.context.scene
print('SCENE', scene.name)
print('FRAME_RANGE', scene.frame_start, scene.frame_end, 'CURRENT', scene.frame_current)
print('FPS', scene.render.fps, 'BASE', scene.render.fps_base)
print('RESOLUTION', scene.render.resolution_x, scene.render.resolution_y, 'PERCENT', scene.render.resolution_percentage)
print('FILM_TRANSPARENT', scene.render.film_transparent)
print('ENGINE', scene.render.engine)
print('CAMERA', scene.camera.name if scene.camera else 'NONE')
if scene.camera:
    camera = scene.camera
    print('CAMERA_LOCATION', tuple(round(value, 4) for value in camera.location))
    print('CAMERA_ROTATION', tuple(round(value, 4) for value in camera.rotation_euler))
    print('CAMERA_TYPE', camera.data.type, 'LENS', camera.data.lens)
for obj in bpy.data.objects:
    if obj.type in {'MESH', 'CAMERA', 'LIGHT'}:
        action = obj.animation_data.action.name if obj.animation_data and obj.animation_data.action else 'NONE'
        print('OBJECT', obj.name, obj.type, 'HIDE_RENDER', obj.hide_render, 'ACTION', action)
for action in bpy.data.actions:
    print('ACTION', action.name, 'RANGE', tuple(round(value, 3) for value in action.frame_range))
print('WORLD', scene.world.name if scene.world else 'NONE')
