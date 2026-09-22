# PackMeasure native MVP

## Product target

PackMeasure measures one package, box, or carton at a time so its dimensions can
be recorded in a warehouse materials-management workflow. The measured object is
the deliverable.

The app was originally built to estimate a moving load and recommend a van or
truck. That is no longer the goal. The vehicle and load-planning features remain
in the app but are frozen: they receive no further work, and the unit preference
does not apply to them.

## Outcome

PackMeasure compares independent iPhone capture angles to estimate a packing
bounding box for a centered carton and saves it with the evidence behind the
estimate.

After a short settling interval, the capture processes one synchronized camera
and LiDAR depth frame. The user does not place a reference object, calibrate a
scale, or tap measurement endpoints.

## Primary journey

1. Frame a box or object at a three-quarter angle so its front, side, and top
   are visible.
2. Tap **Take photo** and hold still briefly while the app processes the capture.
3. Keep the item still, move around it, and capture a second verified viewpoint.
   If raw dimensions disagree, capture one final distinct angle.
4. Review the estimated long side, short side, and height plus the number of
   agreeing angles. Agreement is presented as repeatability evidence, not an
   accuracy claim.
5. Name the item, adjust quantity and stackability, then save it.
6. Review total floor footprint, cubic volume, largest-item constraints, and
   the smallest planning vehicle that fits.

## Measurement contract

- Dimensions describe the smallest conservative rectangular packing box, not
  the contours or usable internal volume of the object.
- LiDAR estimates are approximate. Low-confidence or incomplete scans must be
  labeled and offer a retake rather than silently reporting false precision.
- Save remains disabled until at least two independent viewpoints agree on all
  three raw dimensions. The second camera position must be at least 15 cm away
  horizontally and 20 degrees around the stationary object, as enforced by
  `MeasurementViewpointPolicy`. (This document previously said 25 degrees, which
  never matched the shipped value.)
- Pair agreement currently requires every raw axis to differ by no more than
  1.5 inches and 15%, with no more than a 20% rectangular-volume spread. These
  are provisional repeatability gates and require calibration on more objects.
- When two photos disagree, a third distinct angle adjudicates them. A larger
  discordant result is never silently thrown away; unresolved series must
  restart.
- High confidence requires independent-view agreement plus High point-cloud
  evidence from every contributing photo, not merely multiple depth frames
  from the same pose.
- A single capture action uses one synchronized camera-and-depth frame after a
  short settling interval; it is not a monocular AI guess from RGB pixels.
- The camera mask is the preferred object boundary. If it contains no
  foreground instance, the same frame may use the center-reticle LiDAR region
  as a shape-agnostic fallback while retaining floor and background rejection.
- Real-device calibration against known boxes is part of the definition of
  done. Simulator builds alone cannot verify LiDAR behavior.
- The stated per-axis tolerance is 5% and 20 mm. A measurement whose evidence
  cannot support it is labeled below tolerance and offers a retake. On a device
  with no calibration history, accuracy reads as not verified and is never
  presented as a pass.
- Lateral region bleed onto an adjacent pallet, shelf, wall, or neighbouring
  carton is contained by a cumulative depth-travel budget in the segmenter. The
  shipped budget is a containment default and still needs a device sweep.
- Every accepted measurement records the rule that produced it and the
  per-angle measurements behind it, so a suspect result stays auditable.

## Units contract

- Internal geometry stays in SI meters. Conversion happens at display and at
  manual-entry parse, nowhere else.
- The operator chooses millimeters, centimeters, meters, inches, or feet and
  inches. The choice applies to every measured dimension the app shows or
  accepts, persists across launches, and defaults from the device region.
- Changing the unit never rewrites a stored measurement. Switching away and back
  returns the original figures.
- Size limits are enforced in meters after conversion, so the same physical
  bounds apply whichever unit is typed in.
- Every displayed dimension names its axis. Length, width, and height mean the
  same physical axis in scan results, manual entry, calibration, and detail.

## Vehicle contract (frozen)

Retained for existing data and no longer a product goal. Not extended by
current work.


- Recommendation must satisfy adjusted capacity and largest-item clearance.
- Floor square feet and cubic feet are both reported because neither alone is
  sufficient.
- Vehicle profiles are planning estimates and must expose their assumed cargo
  dimensions and usable-volume factor.

## MVP acceptance criteria

- App builds against the iOS deployment target in `project.yml` (currently 18.6)
  with Xcode 27, and launches on a LiDAR-capable iPhone. (This document
  previously said "iOS 27", conflating the Xcode version with the OS target.)
- Camera permission and LiDAR support checks are handled.
- A known rectangular box can be scanned, reviewed, and saved.
- Inventory survives relaunch.
- Totals and a vehicle recommendation update after adding/removing items.
- Geometry and packing math unit tests pass.
- Known-box device checks record error on all three dimensions; results and
  project documentation are labeled honestly if the desired tolerance is not
  yet met.
