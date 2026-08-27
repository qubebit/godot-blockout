# CSGInstance3D

`CSGInstance3D` lets you build blockout and greybox geometry using Godot's CSG nodes. It uses a baked mesh at runtime while keeping the original CSG source available for future edits.

## Workflow

1. Add a `CSGInstance3D` with a `CSGShape3D` child, such as `CSGBox3D` or `CSGCombiner3D`.
2. Select the node and use the toolbar's **Edit Mode** button, or press `Ctrl+E`, to start editing.
3. Make your changes to the CSG source nodes. Exiting edit mode automatically updates the runtime mesh while retaining the source objects.
4. Turn on **Generate Collision** when you want the geometry to have collision in-game.

Meshes include UV2 coordinates for lightmapping. Use **Lightmap Texel Size** to control the lightmap detail.
