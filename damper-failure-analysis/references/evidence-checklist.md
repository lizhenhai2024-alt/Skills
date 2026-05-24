# Evidence Checklist

## Minimum Input Fields

Capture what is available before judging root cause:

| Category | Required evidence | Why it matters |
|---|---|---|
| Vehicle and program | vehicle model, axle, corner, damper type, supplier, build phase | Defines design boundary and comparison baseline |
| Symptom | complaint wording, noise/leak/force issue, occurrence rate, reproducibility | Prevents analysis from drifting away from the real failure |
| Operating condition | mileage, temperature, road profile, load, speed, stroke direction | Identifies trigger condition and duty severity |
| Test data | FV curve, PQ curve, hysteresis, response time, leakage quantity, friction force | Links symptom to damper function |
| Visual evidence | external photos, teardown photos, wear marks, fracture surface, oil condition | Supports mechanism and excludes alternatives |
| Dimensional evidence | rod runout, surface roughness, seal groove, guide clearance, valve dimensions | Separates design, process, and assembly causes |
| Process evidence | batch, torque, press-in force, welding record, cleanliness, traceability | Identifies manufacturing escape or lot issue |
| Comparison evidence | OK sample, benchmark, before/after, left/right, same batch | Establishes abnormality and variation |
| History | DFMEA, DVP, control plan, warranty trend, previous 8D | Links failure to prevention system |

## Evidence Grades

Use these labels in the report:

| Grade | Meaning | Allowed conclusion wording |
|---|---|---|
| Confirmed | Supported by direct measurement, teardown, reproducible test, or controlled comparison | "Root cause is..." |
| High-confidence hypothesis | Mechanism fits the evidence, but one decisive check is missing | "Most likely root cause is..." |
| Pending verification | Plausible but not yet supported by decisive evidence | "Potential cause to verify..." |
| Unsupported | No evidence or mechanism is available | Do not use as conclusion |

## Mandatory No-Go Rules

- Do not assign responsibility to design, supplier, manufacturing, customer use, or assembly without supporting evidence.
- Do not call leakage a seal design issue until rod surface, contamination, guide wear, pressure overload, seal damage, and assembly damage are considered.
- Do not call noise a valve issue until mounting condition, bushing, installation preload, gas/oil condition, cavitation, and test setup are considered.
- Do not call CDC force abnormality an electrical issue until current command, coil resistance, valve displacement, hydraulic restriction, oil temperature, and dyno setup are separated.
- Do not use a single photo as definitive proof unless the failure feature is direct and unmistakable.

## Missing Evidence Output

When evidence is insufficient, output:

| Missing item | Why needed | How to collect | Decision it enables |
|---|---|---|---|

Then provide hypotheses ranked by confidence, not a final root cause.

