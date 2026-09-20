# LiDAR room measurements

Choose **Measure a room** on the home screen, then **Scan a room**. On a supported
LiDAR iPhone, allow the camera and follow RoomPlan's coaching. Walk slowly around
one room, including every corner, doorway, and floor-to-wall edge. Tap **Finish**,
review the outline and wall dimensions, name the room, and tap **Save**.
Saved rooms are separate from the moving inventory. Share measurements from the
saved room detail. All storage is local; no scan is uploaded by the app.

The overview reports spans aligned with the longest captured wall and the maximum
captured wall height. It is an approximate bounding extent, not floor area,
ceiling clearance, or proof of a complete room. Each wall also has its own length,
height, and RoomPlan confidence. An L-shaped room preserves its separate walls.
Missing walls can understate the extent. Low confidence walls remain visible.

## Physical acceptance (pending)

1. Rectangular room: independently measure two perpendicular walls and wall height.
   Scan three times, starting in different corners; record each wall, overall spans,
   confidence, absolute error, and repeatability in meters and feet.
2. Furnished room: repeat with a chair, sofa, and cabinet against walls. Check that
   furniture does not become a wall or truncate the measured room.
3. L-shaped room: check every segment against tape. The overview must remain an
   extent; it must not claim the bounding rectangle is usable floor area.
4. Partial scan: deliberately omit a wall. Verify the outline exposes the gap and
   the approximate-extent explanation stays visible.
5. Lifecycle: deny permission, close mid-scan, background mid-scan, reopen, finish
   immediately, finish normally, then save and relaunch. No frozen camera or
   duplicate result. Verify room scans do not change the item inventory.
6. Share a saved result and verify units, name, wall numbering, and confidence.

Simulator geometry/persistence tests do not validate Apple's capture callbacks,
LiDAR accuracy, completeness, or real-world usability. Report measured errors
before setting a product accuracy claim or releasing this as calibrated.

Reference: https://developer.apple.com/documentation/roomplan

## Partial-scan recovery (Build 44)

Build 43 rejected all measurements if fewer than three walls were returned, any
wall was invalid, or the footprint was degenerate. Build 44 preserves every
valid wall and reports the count of excluded invalid walls. Partial scans can be
saved, but do not show an overall room span. All-invalid/empty results still fail
with the detected count, a new-scan button, and user-initiated diagnostic sharing.

The capture view shows a live detected-wall count. Results offer Scan again and
Diagnostics; diagnostics include the build, duration, live/final wall counts,
raw wall dimensions, and error, but no photos or point clouds. Share before
retrying or closing, because diagnostics are session-local.

Retest: intentionally finish after two highlighted walls, verify a partial
result with two wall measurements and no overall span, then scan again and
capture the rest of the room. Save/reopen both partial and fuller results.
Screenshots IMG_5573/5574 and the user's live-wall-highlights report establish
that Build 43's post-processing validation failed, but do not identify which
validation condition fired or prove a particular RoomPlan fault.

## Interactive floorplan

Open a saved room (or a new scan result) and tap **Explore floorplan**. Pinch to
zoom up to 8x and drag to pan. Double-tap to zoom in; double-tap beyond 3x to
return to the overview. **Fit** restores the whole outline.

Tap a wall or its number to highlight it and read its saved length, height,
and capture confidence. The wall menu and previous/next buttons also provide
access to every segment. Badges remain readable as you zoom; overlapping badges
are hidden until space is available, with the selected wall taking priority.
Low-confidence walls are orange, and the selected wall is violet. **Done** returns
to the saved result. Viewing does not modify the scan or its measurements.

Viewer validation: select walls at fit and zoomed scale, pan and select again,
restore Fit, choose a crowded segment from the menu, and reopen the saved room.
Repeat on a one-wall partial scan. Capture accuracy remains a separate check.

## Build 46 visual refresh

Measure, Rooms, and Load tabs separate capture, saved floorplans, and moving
inventory. The Measure dashboard also links directly to rooms and the load.
Graphite surfaces, cyan actions, rounded measurement typography, and consistent
cards carry across room results, manual entry, scanner controls, and load planning.
The app uses a dark appearance. Low-confidence walls stay orange; selection is
violet. Unselected wall badges no longer have opaque backgrounds that obscure
lines. The floorplan has one Fit control and a compact measurement inspector.

This release does not change capture geometry, validation, saved data formats,
packing calculations, or accuracy claims. Existing room and inventory files remain
compatible. Check navigation, capture, save/reopen, and inventory edits on iPhone.

## Build 47 wall labels

The interactive floorplan defaults to **Lengths**, displaying each visible wall's
saved length in feet to one decimal place, matching the detail panel. Switch to
**Wall IDs** to cross-reference the wall list. Selection still identifies the wall
in the inspector and shows both metric and imperial dimensions.

Label rectangles use the rendered text size for collision suppression and taps.
Labels sit clear of their own wall; crowded labels are hidden until zoom creates
room. Switching label modes preserves the selected wall and viewport. Small
library previews remain unlabeled. Measurements and saved room files are unchanged.

## 3D wall outline

In **Explore floorplan**, switch between **2D Plan** and **3D Room**. The 3D view
draws each saved wall's floor edge, top edge, and vertical ends. Drag to rotate
and tilt, pinch or use the zoom buttons, and choose **Fit room** (or double-tap)
to restore the initial view. The two views retain their own camera/zoom state;
wall selection and the **Lengths / Wall IDs** choice carry between them.

Length badges include the wall number and saved length in feet. In Build 53 they
anchor to the floor perimeter, with collision-aware sideways placement for narrow
closets. The height badge sits at the top of its unchanged vertical ruler. A vertical **H**
ruler shows the maximum captured wall height until a wall is selected, then that
wall's own height. Tap any wall edge, its length badge, or the height badge to
select it. The inspector shows the selected length and height in meters and feet,
with capture confidence. The menu and previous/next controls reach crowded or
hidden wall labels; VoiceOver also provides rotate and fit actions.

With no selected wall, the inspector shows the long span, short span, and maximum
captured height when the saved scan has an extent. These are the same approximate
extent values as the result screen, not verified interior clearance or floor area.
Partial scans keep their missing segments open. Individual heights and concave
outlines are preserved; the viewer adds no enclosing box, floor, ceiling, or walls.

Saved scans store a 2D footprint and wall heights but no elevation, openings, or
ceiling geometry. The outline therefore aligns walls at a common floor level.
This is a dimensional visualization, not a replay of RoomPlan's full model.
Existing saved scans work without rescanning or changing their storage format.

### September 19 screenshot context and acceptance

- `IMG_5722` through `IMG_5725` show the user's successful walk-in closet scan:
  four walls, approximately 1.42 × 1.16 m and 2.74 m maximum wall height.
- `IMG_5721` shows a separate tight closet and RoomPlan's “Move farther away”
  coaching. It does not depict the successful scan. Tight-space capture remains
  an independent issue; this viewer does not change RoomPlan capture or coaching.
- Viewer check: open that saved walk-in closet, switch to 3D, inspect all four
  walls, rotate/zoom, select a wall, and switch back to 2D. Length, height, wall
  numbering, and selection must agree. Verify Fit and save/reopen on device.
- Also inspect an L-shaped room, unequal wall heights, and a partial scan. Gaps
  must remain visible, and low-confidence walls remain orange (violet if selected).

## Tight-closet guidance (Build 53)

Choose **Tight closet** in Rooms before scanning. Start at the open doorway with
the light on, aim across the closet, and cover visible wall sections and corners
above and below shelves. Keep the hallway outside the scan. This is a practical
positioning strategy to test on device, not a guaranteed recovery of hidden walls.

The live guidance card responds to RoomPlan's lighting, speed, low-texture and
distance instructions. The native RoomPlan coaching stays enabled. In ordinary
Room mode, a continuous “move away” instruction lasting eight seconds also shows
the closet advice. Duplicate instruction callbacks do not reset that timer.

When a close-range warning persists, or an outline has not meaningfully changed
for 15 seconds after at least 20 seconds of scanning, **Review captured walls**
is offered if any valid wall exists. It uses the normal Finish processing path.
It never stops the scan automatically, certifies coverage, or closes missing gaps.
Geometry progress considers IDs, endpoints, height and confidence, rather than
wall count alone. Five-centimeter changes are only a coaching refresh threshold,
not a measurement accuracy tolerance or a RoomPlan setting.

Diagnostics now include time spent under each RoomPlan instruction, usable/low-
confidence wall counts, tracking state, geometry progress and a bounded event
history. They are session-local and shared only by the user; no photos or point
clouds are included. Retry creates a new session and rejects queued old callbacks.

Apple's current public RoomPlan configuration exposes coaching enablement, not a
minimum wall distance control. Build 53 does not alter that sensor/model limit or
the saved geometry. Screenshot IMG_5721 alone cannot establish the cause of its
tight-closet failure. Shelving/occlusion and viewpoint remain hypotheses to test.

Physical check: scan the tight closet once in Tight closet guidance, starting at
the doorway. If “Move farther away” persists, verify the advice appears and that
Review captured walls opens the result normally. Check real wall positions and
lengths against the closet; shelving must not become a substitute wall. Share
Diagnostics before retrying, then confirm the next scan starts fresh. Compare
with the successful saved walk-in closet, which should retain its dimensions.

Sources checked September 19, 2026:
- [Apple: moveAwayFromWall](https://developer.apple.com/documentation/roomplan/roomcapturesession/instruction/moveawayfromwall)
- [Apple: Create parametric 3D room scans with RoomPlan](https://developer.apple.com/videos/play/wwdc2022/10127/)
- [Apple: lowTexture](https://developer.apple.com/documentation/roomplan/roomcapturesession/instruction/lowtexture)
- [Apple: RoomCaptureSession.Configuration](https://developer.apple.com/documentation/roomplan/roomcapturesession/configuration)
- Xcode 27.0 / 27A266a RoomPlan SDK interface, configuration and instruction delegate.

## Wall selection and snapshot coaching (Build 54)

After Finish, choose **Choose walls to save** on the review screen. All captured
walls start included. Inspect the numbered 2D or 3D outline, then switch **Keep
Wall N** off for walls outside the closet. Excluded walls remain gray and dashed
for orientation. The wall list exposes every segment, including short, crowded
ones, and can locate a wall in the outline. Selection offers Keep all and Clear.

**Preview kept walls** shows the exact subset that will be saved, including its
recalculated spans and maximum wall height. The preview and saved result renumber
remaining walls in capture order. Review editing keeps the original wall numbers
stable until Save. Save writes only the kept walls; Close abandons the new scan.
No selection disables Save. One or two retained walls save as a partial scan.
No gap is closed and no missing wall, ceiling or height is inferred.

The name, capture date, room ID, retained wall IDs, lengths, heights and confidence
are preserved. Optional omitted-wall metadata records intentional exclusions
separately from unusable scan data. Old saved rooms remain readable. The source
scan remains intact during editing so any exclusion can be undone before Save.

Mixed heights differing by more than 0.20 m now prompt inspection of the inside
upper corners and outside-wall selection. This is a review cue, not a ceiling
detection threshold. Closet guidance explicitly describes a slow upward sweep
along inside wall-to-ceiling edges and lowering the phone when more distance is
needed. Apple's native distance coaching remains enabled. The current captured-
room API provides wall geometry and heights, not a verified ceiling surface.

### September 20 device evidence

The three Build 53 diagnostic files show normally tracked sessions of 50.6, 62.1
and 40.4 seconds. Two were shared during live capture; their “No RoomPlan result
received yet” text is not a failure. The completed third scan reports six valid
walls, with four heights of 2.76 m and two of 3.69 m. No endpoint coordinates were
recorded in Build 53, so those logs cannot reconstruct the actual footprint or
identify which numbered wall belongs to the closet. Build 54 final diagnostics
include wall IDs, footprint endpoints and confidence for future reconstruction.

All three logs repeatedly alternate zero walls with four/five walls at the same
timestamp. Source review found that didAdd/didChange/didRemove were incorrectly
forwarded as complete room snapshots. Apple's documented contract reserves the
complete snapshot for didUpdate; the other callbacks contain only their changes.
Build 54 uses only didUpdate for live counts, geometry-progress timing and coaching.
This fixes false progress resets; it does not prove the underlying scan geometry
or ceiling capture is accurate. Final processed-result conversion is unchanged.

References checked September 20, 2026:
- [Apple didUpdate: complete snapshot](https://developer.apple.com/documentation/roomplan/roomcapturesessiondelegate/capturesession(_:didupdate:))
- [Apple didAdd: new surfaces and objects](https://developer.apple.com/documentation/roomplan/roomcapturesessiondelegate/capturesession(_:didadd:))
- [Apple CapturedRoom geometry](https://developer.apple.com/documentation/roomplan/capturedroom)

Physical check: Finish a closet scan that includes outside walls, deselect those
walls, inspect Preview kept walls, and save. Reopen it and verify only those walls
and their unchanged measurements remain. Inspect the inside upper corners on
repeat capture; compare wall heights with a tape/laser measurement. Share final
Diagnostics if the ceiling or remaining footprint is still wrong.
