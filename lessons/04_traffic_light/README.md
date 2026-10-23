# Lesson 4 — Traffic Light (Sequence / State Machine)

> Most machines run in **steps**: "clamp → drill → unclamp → eject".
> A traffic light is the simplest example of a **sequence**. Learn this pattern and you
> can program almost any machine sequence.

## The idea: a step number

We keep one integer `Step` that tells us **where we are**:

```
          T_Red done (5 s)          T_Green done (4 s)
 ┌─────────┐ ─────────────> ┌─────────┐ ─────────────> ┌──────────┐
 │ Step 0  │                │ Step 1  │                │ Step 2   │
 │  RED    │                │  GREEN  │                │  YELLOW  │
 └─────────┘ <───────────────────────────────────────── └──────────┘
                         T_Yellow done (2 s)
```

Rules of a good sequence:

1. **Only one step is active at a time.**
2. Each step has a **transition condition** (here: its timer is done).
3. **Outputs are decided by the step**, in a separate place (not mixed into the transitions).
4. There is a **safe state** (here: Step 0 = RED).

## The problem

* `I_Start` starts the traffic light cycle, `I_Stop` stops it.
* Cycle: RED 5 s → GREEN 4 s → YELLOW 2 s → RED …
* When stopped → back to Step 0 → **RED stays ON** (safe state).

## I/O list

| Tag | Address | Type | Description |
|-----|---------|------|-------------|
| `I_Start` | `%IX0.0` | BOOL | Start cycle |
| `I_Stop` | `%IX0.1` | BOOL | Stop cycle |
| `Q_Red` | `%QX0.0` | BOOL | Red lamp |
| `Q_Yellow` | `%QX0.1` | BOOL | Yellow lamp |
| `Q_Green` | `%QX0.2` | BOOL | Green lamp |
| `M_Enable` | — | BOOL | Cycle running |
| `Step` | — | INT | Current step 0 / 1 / 2 |
| `T_Red`, `T_Green`, `T_Yellow` | — | TON | One timer per step |

---

## Ladder Diagram

`[ Step = 0 ]` is a **compare contact** — it passes power when the comparison is true.
(Siemens: `CMP ==I`, Allen-Bradley: `EQU`, CODESYS/OpenPLC: `EQ` block.)
`MOVE` copies a value into a variable when its rung is powered.

```
Network 1 — Enable (seal-in)
 |----+----[ I_Start ]---+----[/ I_Stop ]---------------------------( M_Enable )---|
 |    +----[ M_Enable ]--+                                                         |

Network 2 — Not enabled -> go to safe step 0
 |----[/ M_Enable ]-----------------------------------------[ MOVE 0 -> Step ]-----|

Network 3 — Step 0 timer (RED 5 s)
 |----[ M_Enable ]----[ Step = 0 ]------------------[ T_Red    TON  PT=T#5s ]------|

Network 4 — Step 1 timer (GREEN 4 s)
 |----[ M_Enable ]----[ Step = 1 ]------------------[ T_Green  TON  PT=T#4s ]------|

Network 5 — Step 2 timer (YELLOW 2 s)
 |----[ M_Enable ]----[ Step = 2 ]------------------[ T_Yellow TON  PT=T#2s ]------|

Network 6 — Transition 0 -> 1
 |----[ T_Red.Q ]-------------------------------------------[ MOVE 1 -> Step ]-----|

Network 7 — Transition 1 -> 2
 |----[ T_Green.Q ]-----------------------------------------[ MOVE 2 -> Step ]-----|

Network 8 — Transition 2 -> 0
 |----[ T_Yellow.Q ]----------------------------------------[ MOVE 0 -> Step ]-----|

Network 9 — Outputs (decided only by the step)
 |----[ Step = 0 ]--------------------------------------------------( Q_Red )------|
 |----[ Step = 1 ]--------------------------------------------------( Q_Green )----|
 |----[ Step = 2 ]--------------------------------------------------( Q_Yellow )---|
```

---

## Net-by-net explanation

### Network 1 — Enable
Seal-in again (you will see it everywhere). `M_Enable` = "the cycle is allowed to run".

### Network 2 — Safe state
When **not** enabled, force `Step := 0`. So after STOP, or after power-up, the
light is RED. Always design where your sequence goes when it stops!

### Networks 3–5 — One timer per step
Each timer only runs while **its** step is active (`Step = n`) and the cycle is enabled.
* While in Step 0, `T_Red` counts 0 → 5 s. `T_Green` and `T_Yellow` have `IN` = FALSE, so they stay reset (ET = 0).
* When the step changes, the old timer's `IN` goes FALSE on the next scan → it resets
  itself and is ready for the next cycle. No manual reset needed.

### Networks 6–8 — Transitions
Each transition says: "when this step's timer is done, go to the next step".
Example, end of RED:

| Scan | Net 3 sees | T_Red.Q | Net 6 does | Step after scan |
|------|------------|---------|------------|-----------------|
| k | Step = 0, ET = 4.998 s | 0 | nothing | 0 |
| k+1 | Step = 0, ET = 5.000 s | **1** | `MOVE 1 -> Step` | **1** |
| k+2 | Step = 1 → `IN` FALSE → T_Red reset | 0 | nothing | 1 (Net 4 starts T_Green) |

Because only one timer can be done at a time, only one transition fires per scan.

### Network 9 — Outputs
Outputs are a pure function of `Step`. This separation is gold for debugging:
if the wrong lamp is on, you only need to check **what step you are in**.
When stopped, Step = 0 → RED is ON.

---

## Structured Text

See [program.st](program.st). ST uses `CASE` — the natural way to write a state machine:

```iecst
CASE Step OF
    0: IF T_Red.Q    THEN Step := 1; END_IF;
    1: IF T_Green.Q  THEN Step := 2; END_IF;
    2: IF T_Yellow.Q THEN Step := 0; END_IF;
END_CASE;
```

Notice the timers are called **before and outside** the `CASE`, so they run every scan.
If you put `T_Red(...)` inside `0:`, the timer would never see `IN` = FALSE when you leave
the step, so it would **not reset** — classic bug.

---

## Exercises

1. Add a **pedestrian button**: when pressed during GREEN, shorten GREEN to 1 s.
2. Add a **night mode** input: yellow flashes 1 Hz, all others OFF.
3. Use step numbers 10, 20, 30 instead of 0, 1, 2. Why do real engineers do this?
   *(Answer: you can insert step 15 later without renumbering everything.)*
4. Make a 2-way intersection (North-South and East-West) — 6 lamps, never both GREEN.

Next: [Lesson 5 — Tank level control](../05_tank_level_control/)
