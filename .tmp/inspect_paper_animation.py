import bpy
import json

scene = bpy.context.scene
report = {
    'blender': bpy.app.version_string,
    'scene': scene.name,
    'frame_start': scene.frame_start,
    'frame_end': scene.frame_end,
    'fps': scene.render.fps,
    'objects': [],
    'actions': [],
}
for obj in bpy.data.objects:
    modifiers = []
    for mod in obj.modifiers:
        modifiers.append({
            'name': mod.name,
            'type': mod.type,
            'point_cache': getattr(getattr(mod, 'point_cache', None), 'is_baked', None),
        })
    report['objects'].append({
        'name': obj.name,
        'type': obj.type,
        'visible_render': not obj.hide_render,
        'modifiers': modifiers,
    })
for action in bpy.data.actions:
    report['actions'].append({
        'name': action.name,
        'frame_range': list(action.frame_range),
        'fcurves': len(getattr(action, 'fcurves', [])),
    })
print('RESUME_PAPER_REPORT=' + json.dumps(report, indent=2))