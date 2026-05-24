# DFMEA and DVP Linkage

Use this file when the analysis identifies a design or process risk that should be reflected in prevention controls.

## Linkage Principle

Every confirmed or high-confidence root cause should produce at least one prevention update:

| Root cause type | DFMEA update | DVP/control update |
|---|---|---|
| Seal design margin insufficient | Add or revise leakage, extrusion, lip wear, low-temp leakage failure modes | Temperature leakage, pressure pulse, contamination, rod finish checks |
| Rod or structural fatigue | Add fracture, crack, permanent deformation, corrosion-assisted fatigue | Road load durability, bending fatigue, salt/corrosion exposure, fracture inspection |
| Valve flow restriction or drift | Add damping force low/high, FV drift, hysteresis, blocked orifice | Multi-speed FV, temperature sweep, cleanliness, PQ pressure split |
| Cavitation or foaming | Add force collapse, gas ingestion, poor deaeration, noise | High-speed durability, pressure trace, oil foam test, fill process audit |
| CDC electrical/control fault | Add no response, slow response, dead zone, saturation, connector fault | Current sweep FV, coil resistance, harness water ingress, step response |
| Manufacturing variation | Add dimension out-of-spec, wrong assembly, contamination, torque/press error | Process capability, end-of-line FV, cleanliness audit, poka-yoke check |

## DFMEA Output Fields

For each update, include:

| Function | Failure mode | Effect | Cause | Current prevention | Current detection | Recommended action |
|---|---|---|---|---|---|---|

Use S/O/D only when the user provides a rating method or asks for scoring. Otherwise provide qualitative severity, occurrence evidence, and detection gap.

## DVP Output Fields

For each verification item, include:

| Test item | Purpose | Condition | Sample | Acceptance criterion | Discriminating result |
|---|---|---|---|---|---|

The discriminating result must explain what outcome would confirm or reject the suspected mechanism.

## Typical Verification Matrix

| Failure theme | Minimum useful verification |
|---|---|
| Leakage | leak rate before/after cycling, rod surface measurement, seal teardown, pressure pulse, temperature soak |
| Noise | instrumented noise spectrum, stroke-position correlation, mounting isolation check, hot/cold comparison |
| Damping force drift | FV repeatability, oil temperature sweep, teardown valve inspection, comparison sample |
| Fracture | fracture surface, hardness/material check, stress concentration review, load spectrum correlation |
| Cavitation | pressure trace, high-speed FV, oil condition, reservoir/gas volume review |
| CDC response | command-current logging, coil resistance, current sweep FV, step response, valve displacement |

