# CSGInstance3D

`CSGInstance3D` lets you build blockout and greybox geometry using Godot's CSG nodes. It uses a baked mesh at runtime while keeping the original CSG source nodes available for future edits.

## Workflow

1. Add a `CSGInstance3D` and a `CSGShape3D` based node as child (CSGBox3D, CSGCombiner3D, etc.)
2. Press `Ctrl+E` to enter edit mode. You can also use the **Blockout** button in the toolbar.
3. Make edits to your underlying CSG nodes. Exiting edit mode automatically bakes the geometry into an `ArrayMesh` and hides the CSG nodes. You can re-enter edit mode at any time to make further changes.
4. If you want your geometry to have static collisions, turn on **Generate Collision** on the `CSGInstance3D`.

`CSGInstance3D` generated meshes include UV2 coordinates so can be used in lightmapping. Use **Lightmap Texel Size** to control the lightmap detail.
