# Real-device calibration

Use a tape measure and three rectangular cartons with clearly different sizes.
Keep each carton stationary while capturing the requested independent angles.

Run the **Calibration check** in the app rather than working these figures out
by hand: enter the carton's tape-measured dimensions, scan it, and the app
reports absolute and percent error for each axis and keeps the run in its
history. Transcribe those numbers into the table below.

Place the carton on an open floor for the baseline runs — not on a pallet, not
against a wall, and not beside another carton. Adjacent surfaces at a similar
depth are the suspected source of the recorded overestimation, so they belong in
the separate check further down rather than in the baseline.

**Status: no runs recorded yet.** The table is empty because these figures
require a LiDAR device, and the depth-segmentation containment added in
`0.3.0` has not been measured on hardware. Until a run appears here, the app
reports its accuracy as *not verified* rather than claiming a pass.

| Object | Actual L × W × H | Angle 1 | Angle 2 | Angle 3 | Final estimate | Best absolute error | Confidence |
|---|---|---|---|---|---|---|---|
| Small box |  |  |  |  |  |  |  |
| Medium box |  |  |  |  |  |  |  |
| Large box or tote |  |  |  |  |  |  |  |

For each dimension:

```text
absolute error = |measured - actual|
percent error = absolute error / actual × 100
```

## Physical-device acceptance check

- Camera permission appears once and the live preview opens.
- Each known box returns all three dimensions after the multi-angle workflow.
- A same-position second photo is rejected as too similar.
- Two captures never resolve by themselves, even when their dimensions agree.
- The third capture must come from a distinct side and change camera height by
  roughly 8 inches (20 cm); a flat third view is rejected without clearing the
  first two angles.
- A materially larger discordant third result blocks saving instead of being
  silently discarded.
- The accepted result keeps all contributing angle measurements visible.
- Missing LiDAR support near an isolated silhouette endpoint asks for a retake
  instead of accepting a shortened dimension.
- A poor angle or weak point cloud is labeled low-confidence or asks for a
  retake instead of silently saving a false measurement.
- Saving, force-quitting, and reopening preserves the inventory.
- Quantity and stack controls change floor square feet.
- The recommendation rules out a vehicle when an item cannot clear its door.

The stated tolerance is **5% and 20 mm per axis**, and both bounds must hold.
A run passes only when every axis passes; two good axes never rescue a third,
which is exactly the failure this check exists to catch.

Treat a box result within roughly 5% per dimension as a strong MVP result.
Larger error, repeated underestimation, or unstable results means the depth
segmentation thresholds need tuning before relying on the estimate for a tight
vehicle fit.
