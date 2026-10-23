# PLC Fundamentals — Ladder Diagram (LD) & Structured Text (ST)

A beginner-friendly learning repository for PLC programming.
Every program is written **twice** — once in **Ladder Diagram** and once in
**Structured Text** — and **every network (rung) is explained** line by line,
so you understand *what the PLC actually does* on each scan.

Both languages are part of the **IEC 61131-3** standard, so the ideas here work
on Siemens (TIA Portal), Allen-Bradley (Studio 5000), Schneider, Omron,
Mitsubishi, CODESYS, OpenPLC and others. Only the address names and the editor
look different.

---

## Learning path

Do the lessons in order. Each one adds one new idea.

| # | Lesson | New idea you learn |
|---|--------|--------------------|
| 0 | [PLC fundamentals](docs/00_plc_fundamentals.md) | Scan cycle, I/O, NO/NC contacts, coils, how to read a rung |
| 1 | [Start/Stop motor](lessons/01_start_stop_motor/) | Seal-in (latching) circuit — the most important rung in industry |
| 2 | [Timers](lessons/02_timers/) | TON, TOF, TP — delay on, delay off, pulse |
| 3 | [Counters](lessons/03_counters/) | CTU, edge detection (R_TRIG), reset |
| 4 | [Traffic light](lessons/04_traffic_light/) | Sequences / state machine with timers |
| 5 | [Tank level control](lessons/05_tank_level_control/) | Analog value, compare, alarms, interlocks |
| — | [Glossary](docs/glossary.md) | Words you will hear on site |

Each lesson folder contains:

```
README.md     -> the problem, the I/O list, the ladder diagram, and a NET-BY-NET explanation
program.st    -> the same logic in Structured Text, with comments
```

---

## Watch the scan cycle yourself (simulator)

`simulator/scan_sim.py` runs Lesson 1 (Start/Stop motor) scan by scan and prints
the state of every network so you can **see** the seal-in happen.

```bash
python simulator/scan_sim.py
```

Run `python simulator/scan_sim.py 3` to see Lesson 3: why counting without edge
detection counts one box many times.

No PLC or extra library needed — only Python 3.

---

## Run the programs on a real (free) PLC environment

| Tool | Cost | Notes |
|------|------|-------|
| **OpenPLC Editor** (autonomylogic.com) | Free | Supports LD and ST, has a built-in simulator. Best for starting. |
| **CODESYS** (codesys.com) | Free | Professional IDE, `CODESYS Control Win` soft-PLC for simulation. |
| **Siemens TIA Portal + PLCSIM** | Trial | Use if your company uses Siemens. ST is called **SCL** there. |
| **Rockwell Studio 5000 + Emulate** | Paid | Use if your company uses Allen-Bradley. |

**How to use the `.st` files:** create a new project, add a POU (Program) in
Structured Text, and paste the code between `PROGRAM` and `END_PROGRAM`.
For Ladder, draw the rungs from the lesson README in the LD editor.

### CODESYS step by step (no hardware needed)

A ready project for Lesson 1 is in [codesys/Lesson01_StartStopMotor.project](codesys/).
To build your own for the other lessons:

1. **File → New Project → Standard project**, then pick the device `CODESYS Control Win V3 x64` and set `PLC_PRG` to *Structured Text* (or *Ladder Logic Diagram* to draw rungs).
2. Open `PLC_PRG`. Paste the `VAR ... END_VAR` part into the **top** (declaration) pane and the logic into the **bottom** (body) pane. Rename `PROGRAM xyz` to `PROGRAM PLC_PRG`.
3. **Build** (F11). Warnings like *"address %IX0.0 is not defined in any device"* are normal, because there is no real I/O card.
4. **Online → Simulation** (tick it), then **Online → Login** → answer *Yes* to download → **Start** (F5).
5. To "press a button": click the **Prepared value** cell of an input until it shows `TRUE`, then **Ctrl+F7** (Write values).
   Watch the live values next to every variable in the code. That is your "online view" of every network.
6. **Online → Logout** when finished.

> Tip: ask your company which PLC brand they use and install that software early.
> The logic you learn here transfers 1:1.

---

## Naming convention used in this repo

| Prefix | Meaning | Example |
|--------|---------|---------|
| `I_` / `%IX` | Physical input (sensor, button) | `I_Start` |
| `Q_` / `%QX` | Physical output (motor, lamp, valve) | `Q_Motor` |
| `M_` | Internal memory bit (no wire) | `M_Running` |
| `T_` | Timer instance | `T_Delay` |
| `C_` | Counter instance | `C_Boxes` |

## Safety note

Code in this repo is for **learning**. On a real machine, emergency stops and
safety guards must be wired in **hardware** (safety relays / safety PLC),
never only in normal PLC software.

## License

MIT — see [LICENSE](LICENSE).
