# Compositing Workflow

## Before editing
- Prefer portal footage with an alpha channel (often ProRes 4444 or a PNG sequence).
- If the overlay has a black background, try Screen/Add blending; inspect for black fringing.
- Retain the licence/attribution notes for every asset.

## DaVinci Resolve / Fusion
1. Import the room shot, clean plate, portal overlay, environment plate, and sound effects.
2. Put the portal environment behind the portal ring.
3. Use a mask/Polygon node to confine the environment to the inside of the ring.
4. Put the ring/energy overlay above the environment and use Screen/Add where suitable.
5. Rotoscope or mask the actor so they remain in front of the portal.
6. Add subtle blue glow/light wrap to the actor's edge and nearby surfaces.
7. Add a small exposure flicker, distortion, particles, and a brief impact shake.
8. Mix sound: low hum → rising charge → whoosh/impact → sustained ambience.
9. Check edges at full resolution, then export a short test.

## After Effects
1. Put the room plate at the bottom of the timeline.
2. Place the portal interior and ring above it; use masks and blending modes as appropriate.
3. Roto Brush or mask the actor to restore foreground depth.
4. Add Glow, subtle displacement, particles, and light-wrap treatment.
5. Add sound and grade the shot so the portal's blue light matches the room.

## Blender
- Use Blender for a 3D portal plane/ring and environment render.
- Match the camera perspective and lighting.
- Render with transparency if compositing the 3D effect over live footage.

## Realism tips
- Keep the portal fixed to the room perspective.
- Add blue illumination to the actor and floor; a bright portal with no spill looks pasted on.
- Avoid overusing glow. Preserve detail in the portal's centre.
- Match motion blur, grain, contrast, and sharpness between all layers.
