# Drawer and cabinet scanning — Build 58

The interior workflow captures a level footprint with optional obstacle cutouts
and one usable height for a fitted insert. Build 58 prioritizes obtaining an
outline and placing/correcting corners without repeatedly aiming a live reticle.
It preserves concavity, millimeter editing, clearance and 1:1 SVG export.

## Flow

Home → **Measure a drawer or cabinet → Scan drawer or cabinet** opens three stages:
Outline, Height and Review. Empty and secure the compartment before capture.

- **Find outline** starts the existing seeded LiDAR floor detector. It still
  requires observed raised boundaries, fresh depth and three consistent previews.
  **Use this outline** pins the result and moves directly to height. **Edit outline**
  returns to corrections without discarding it. **Retry from cross** picks a new
  floor seed when detection struggles. After seeding, previews no longer depend
  on obtaining a separate reliable reading at the current center cross.
- **Place corners myself** offers **Freeze & zoom**. Freeze a visible section,
  pinch/pan, and tap the inside floor corners in perimeter order. Each tap places
  one point. Numbered dots and connecting lines identify the captured points.
  **Resume camera** retains them, allowing another angle and another frozen view
  in the same uninterrupted AR session. This is manual point accumulation, not
  automatic fusion of partial boundaries or hidden-corner inference.
- Choose a numbered corner and tap its corrected location, or move it with the
  live cross. A valid correction updates only that corner. **Undo** removes the
  most recently added point or cancels the selected correction. **Add obstacle**
  preserves the outer outline, including one produced automatically. Trace each
  cutout around its base, then continue to height. **Start over** explicitly clears
  the unfinished scan after confirmation.
- Capture or tap a visible top edge above the footprint. It no longer has to be
  directly above the orange first corner. The top point must lie above the outer
  footprint or within 30 mm of its boundary and outside obstacle interiors.
  Choose the lowest usable height, accounting for drawer closure and obstructions.
  Alternatively, **Enter measured height** accepts inches or millimeters. Guided
  heights are 10–3,000 mm. Entered heights retain a distinct source; editing a
  captured height in review changes it to entered. Old saved records still decode.
- Review the footprint and height, adjust clearance, use the always-visible **Save**
  button, and optionally export
  an SVG. Side clearance applies at every wall and obstacle. This remains a 2D
  footprint plus height, not a complete tapered/overhung 3D cavity.

## Capture and lifecycle

`InteriorPhoto` retains the full camera image, depth/confidence grid, intrinsics,
image resolution and camera pose from the same fresh, normally tracked AR frame.
The raw image is rotated clockwise for portrait. Taps in the zoomable image map
back to normalized original-image coordinates, then sensor coordinates. The
existing exact-pixel depth sampler unprojects that pixel using the frozen frame's
calibration and pose. Low-confidence, missing and out-of-range depth fail at that
point; no nearby pixel, image center or inferred plane is substituted. A point
must still pass level-floor and outline geometry checks.

Photo overlays project the existing world points back through that same pose and
intrinsics. Zoom changes display only. Unknown/behind-camera points break overlay
lines instead of creating spurious connections. Images/depth snapshots are
transient and are not saved to the interior store. New photographs and the live
reticle share a coordinate system only while the tracking session remains intact.

Backgrounding, AR interruption, relocalization and explicit reset invalidate
unfinished photos and points. Old-generation snapshots cannot place points in a
new scan. Completed review results survive. Ordinary help/height sheets no longer
clear geometry just because the scene briefly becomes inactive. Interior markers
now have an owned SceneKit node; refreshing them does not remove ARSCNView's
camera node.

The shared photo picker also serves the Build 57 wire-shelf flow. Outline overlays
are optional, so wire matching keeps its existing single crosshair behavior.

## Verification and limits

New tests cover photo/world round-trip mapping, exact-pixel confidence rejection,
viewpoint continuation, stale snapshots, pinned-outline obstacle insertion,
single-corner correction, direct transition to height, stale preview rejection,
height footprint containment, entered-height boundaries and legacy persistence.
UI fixtures exercise frozen placement/correction/save/reopen, obstacle addition,
automatic-outline navigation and depth rejection after zoom. Wire flow UI checks
are repeated because the photo picker is shared.

These are software and synthetic-image checks. Real-device corner registration,
LiDAR dimensions, repeatability and insert fit remain to be tested. Automatic
outline detection still needs the whole floor boundary in one view; a cabinet
lip/roof or missing depth may require manual placement from several viewpoints.

Minimal physical check: freeze one drawer view, zoom and tap its corners, then
resume and move the phone. Confirm the markers stay on the actual corners. Try
one correction and an obstacle, enter or capture height, and save/reopen. Compare
with a ruler/caliper. For a cabinet, keep the compartment still and continue from
a second angle. If tracking resets, start a fresh scan. Print a thin test outline
before a full fitted insert.
