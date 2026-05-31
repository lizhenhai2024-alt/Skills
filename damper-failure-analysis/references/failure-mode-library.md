# Failure Mode Library

Use this library to match symptoms to mechanisms. Treat thresholds as engineering heuristics unless the user provides program-specific limits.

## Leakage and Sealing

| Symptom | Likely mechanisms | Evidence to request | Design/process checks |
|---|---|---|---|
| Oil film at rod seal | lip wear, rod roughness, contamination, guide wear, eccentric load | oil quantity, rod Ra, rod scratch photos, guide clearance, seal lip photos | lip material, interference, dust seal, rod coating, cleanliness |
| Sudden heavy leakage | seal cut, seal inversion, O-ring extrusion, pressure spike, assembly damage | teardown photos, pressure history, seal groove dimensions, backup ring status | groove fill, extrusion gap, pressure pulse, assembly tooling |
| Low-temperature leakage | seal hardening, loss of lip contact, rod contraction, oil viscosity increase | temperature, material spec, cold soak test, leakage after warm-up | low-temp material, lip preload, rod finish |
| High-temperature leakage | seal softening, extrusion, oil compatibility, pressure rise | temperature, material hardness, oil compatibility, pressure data | compound selection, backup ring, thermal expansion |

## Damping Force and FV/PQ Abnormality

| Symptom | Likely mechanisms | Evidence to request | Design/process checks |
|---|---|---|---|
| Damping force low | oil loss, gas ingestion, valve leakage, shim fatigue, bypass leakage, wrong oil | FV curves, oil volume, gas pressure, valve stack inspection | valve stack, piston band, base valve, oil viscosity |
| Damping force high | blocked orifice, wrong valve stack, high friction, oil viscosity high, tube deformation | FV curve by temperature, teardown, friction test | orifice cleanliness, shim order, guide friction, tube roundness |
| Force drift with temperature | oil viscosity sensitivity, seal friction change, gas pressure change | FV at multiple temperatures, oil spec | oil selection, gas charge, seal material |
| Hysteresis abnormal | friction, cavitation, valve delay, fixture compliance | low-speed FV, pressure trace, mounting check | guide/bushing friction, valve preload, gas volume |

## Noise, Vibration, and Harshness

| Symptom | Likely mechanisms | Evidence to request | Design/process checks |
|---|---|---|---|
| High-frequency hiss or squeal | high-velocity orifice flow, turbulence, vortex shedding | noise spectrum, flow path dimensions, PQ data | orifice size, edge shape, annular gap, pressure drop split |
| Knock or click | valve plate impact, topping/bottoming, bushing clearance, mounting looseness | time-domain noise, stroke position, teardown marks | valve lift stop, rebound stop, bracket/bushing tolerance |
| Gurgle or empty stroke feel | foaming, gas ingestion, oil starvation, poor deaeration | oil condition, high-speed durability data, reservoir fill | oil volume, gas/oil separation, reservoir capacity |
| Noise only after heat | viscosity drop, leakage path increase, gas expansion | hot FV/noise test, oil temp, gas pressure | high-temp valve stability, seal friction, gas volume |

## Cavitation and Foaming

| Symptom | Likely mechanisms | Evidence to request | Design/process checks |
|---|---|---|---|
| Force collapse at high speed | local pressure below vapor pressure, oil starvation, insufficient replenishment | pressure trace, high-speed FV, oil condition | rebound chamber pressure, base valve capacity, reservoir volume |
| Persistent foam | air ingestion, poor deaeration, excessive agitation, wrong oil | oil sample, fill process, gas charge, durability condition | filling vacuum, oil anti-foam property, gas/oil separator |

## Structure, Fatigue, and Corrosion

| Symptom | Likely mechanisms | Evidence to request | Design/process checks |
|---|---|---|---|
| Rod fracture | fatigue at thread/step, bending overload, hydrogen embrittlement, corrosion pit | fracture surface, load history, hardness, plating record | stress concentration, material, heat treatment, coating |
| Tube deformation | side load, clamp load, internal pressure, transport damage | roundness, installation condition, pressure data | tube thickness, bracket stiffness, packaging |
| Weld or bracket crack | fatigue, weld defect, poor penetration, overload | weld macro, crack origin, road load data | weld spec, fixture, fatigue validation |
| Corrosion | coating damage, salt exposure, material incompatibility | corrosion photos, salt spray history, coating thickness | plating, paint, drain path, galvanic pairing |

## CDC and Semi-Active Dampers

| Symptom | Likely mechanisms | Evidence to request | Design/process checks |
|---|---|---|---|
| Low-current dead zone | magnetic force insufficient, pilot area too large, spring preload high, valve stiction | current-force curve, valve displacement, PQ/FV by current | pilot orifice, spring, armature friction, magnetic circuit |
| High-current saturation | flow path fully open, main valve bottleneck, hydraulic limit | FV by current, valve lift, pressure split | main flow area, serial restrictions, control range |
| No response to current | open/short coil, connector issue, ECU command issue, valve stuck | command current, coil resistance, harness check, valve teardown | connector sealing, coil spec, contamination control |
| Slow response or hysteresis | magnetic delay, friction, oil viscosity, contamination, control filtering | step response, temperature sweep, contamination check | armature clearance, surface finish, control strategy |

