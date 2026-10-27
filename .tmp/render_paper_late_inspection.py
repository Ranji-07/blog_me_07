import bpy
import os
scene = bpy.context.scene
scene.render.film_transparent = True
scene.render.resolution_x = 256
scene.render.resolution_y = 256
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
if 'Backdrop' in bpy.data.objects:
    bpy.data.objects['Backdrop'].hide_render = True
out = os.path.abspath('blender/resume_paper/inspection')
for frame in [260, 270, 280, 290, 300, 310, 320, 330]:
    scene.frame_set(frame)
    scene.render.filepath = os.path.join(out, 'frame_%03d.png' % frame)
    bpy.ops.render.render(write_still=True)