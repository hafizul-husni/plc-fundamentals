# Glossary — words you will hear on site

| Term | Meaning |
|------|---------|
| **PLC** | Programmable Logic Controller — the industrial computer. |
| **Scan / scan cycle** | One loop of: read inputs → run program → write outputs. |
| **Scan time** | How long one scan takes (typically 1–20 ms). |
| **I/O** | Inputs / Outputs. **DI/DO** = digital, **AI/AO** = analog. |
| **Rung / Network** | One line of ladder logic (Siemens says *network*, Rockwell says *rung*). |
| **NO / NC** | Normally Open / Normally Closed contact. |
| **XIC / XIO / OTE** | Allen-Bradley names: eXamine If Closed `[ ]`, eXamine If Open `[/ ]`, OuTput Energize `( )`. |
| **Coil** | The output element at the right of a rung. |
| **Seal-in / Latch / Holding contact** | Output contact in parallel with START so it keeps itself ON. |
| **Set / Reset (S/R, OTL/OTU)** | Coils that latch / unlatch a bit. |
| **Interlock** | A condition that blocks an output for safety or to protect equipment. |
| **Permissive** | A condition that must be TRUE before something may start (e.g. "lube pressure OK"). |
| **Edge / one-shot (R_TRIG, ONS, P)** | TRUE for exactly one scan when a signal changes. |
| **TON / TOF / TP** | On-delay / Off-delay / Pulse timer. |
| **CTU / CTD / CTUD** | Count up / down / up-down counter. |
| **Preset (PV / PT)** | The target value of a counter / timer. |
| **Retentive (RETAIN)** | Memory that keeps its value through a power cycle. |
| **Double coil** | Same output written in two places — bug, the last one wins. |
| **Tag** | A named variable (Rockwell / modern PLCs). Older PLCs use only addresses like `I0.0`. |
| **POU** | Program Organization Unit: a PROGRAM, FUNCTION_BLOCK or FUNCTION. |
| **FB / FC** | Function Block (has memory, needs an instance) / Function (no memory). |
| **HMI / SCADA** | Operator screen / plant-wide monitoring system. |
| **4–20 mA** | Standard analog signal. 4 mA = 0 %, 20 mA = 100 %, 0 mA = wire broken. |
| **Scaling** | Converting the raw analog integer into engineering units (%, bar, °C). |
| **Hysteresis / dead band** | Two different switch points (ON at 20 %, OFF at 80 %) to stop rapid toggling. |
| **Debounce / filter** | Ignoring a signal until it is stable for some time. |
| **E-Stop** | Emergency stop — must be hard-wired through a safety relay, not only PLC software. |
| **Commissioning** | Testing and starting up the machine on site. |
| **Online / Monitor mode** | Watching the running PLC logic live from the laptop. |
| **Force** | Overriding an I/O value from the laptop. Dangerous — always remove forces after testing! |
| **Download / Upload** | Laptop → PLC / PLC → laptop. |
| **IEC 61131-3** | The international standard that defines LD, ST, FBD, SFC and IL. |
