# Lesson 5 — Tank Level Control (Analog, Compare, Hysteresis, Alarms, Interlocks)

> This lesson looks like a real process-plant job: an analog sensor, scaling,
> setpoints, alarms, Auto/Manual mode and a safety interlock.

## The problem

A water tank is filled by a pump. A level transmitter sends **4–20 mA** for 0–100 %.

1. **Scale** the raw analog value to **0–100 %**.
2. **AUTO mode:** pump starts when level ≤ **20 %**, stops when level ≥ **80 %**.
3. **MANUAL mode:** operator runs the pump with a button.
4. **High-High alarm** at ≥ **95 %**: pump is **blocked in every mode** (interlock).
   The alarm stays latched until the operator presses RESET **and** the level is below 95 %.
5. **Low-Low alarm** at ≤ **5 %**, only after it is true for 2 s (filter out waves/noise).

## Analog basics

The analog input card converts 4–20 mA to an integer. The range depends on the brand:

| Brand | 4 mA (0 %) | 20 mA (100 %) |
|-------|-----------:|--------------:|
| Siemens S7-1200/1500 | 0 | 27 648 |
| Allen-Bradley (typical) | configurable, e.g. 0 | 32 767 or engineering units |
| OpenPLC | 0 | 65 535 |

We use the Siemens range (0 … 27 648). Scaling formula:

```
Level_% = Raw / 27648.0 * 100.0
```

Why 4 mA and not 0 mA for 0 %? Because **0 mA means a broken wire**. 4–20 mA lets
the PLC tell "empty tank" (4 mA) apart from "cable cut" (0 mA).

## Why hysteresis?

If the pump started below 50 % and stopped above 50 %, it would switch ON/OFF
hundreds of times as the water surface moves → destroys the contactor and pump.
With **two** setpoints (20 % and 80 %) there is a dead band in between where the pump
**keeps its current state**. That "keep state" is — again — a **seal-in**!

```
Level  100% ┤
        80% ┤- - - - -/\- - - - - - -/\- - -  stop
            ┤        /  \           /  \
        20% ┤- - - -/- - \- - - - -/- - \- -  start
            ┤      /      \       /      \
Pump        ┤ ─────┐       └──────┐       └─
            ON     OFF            ...
```

## I/O list

| Tag | Address | Type | Description |
|-----|---------|------|-------------|
| `I_LevelRaw` | `%IW0` | INT | Level transmitter raw value 0 … 27 648 |
| `I_AutoMode` | `%IX0.0` | BOOL | Selector switch: 1 = AUTO, 0 = MANUAL |
| `I_ManualPump` | `%IX0.1` | BOOL | Manual pump button (hold to run) |
| `I_AlarmReset` | `%IX0.2` | BOOL | Alarm reset button |
| `Q_Pump` | `%QX0.0` | BOOL | Pump contactor |
| `Q_AlarmHigh` | `%QX0.1` | BOOL | High-high alarm lamp |
| `Q_AlarmLow` | `%QX0.2` | BOOL | Low-low alarm lamp |
| `Level` | — | REAL | Scaled level in % |
| `M_AutoFill` | — | BOOL | Auto fill demand (with hysteresis) |
| `M_AlarmHH` | — | BOOL | Latched high-high alarm |
| `T_LowFilter` | — | TON | 2 s filter for low-low alarm |

---

## Ladder Diagram

```
Network 1 — Scale raw value to %
 |        +-------------+     +-------------+     +-------------+            |
 |--------|INT_TO_REAL  |-----|DIV          |-----|MUL          |            |
 |        |IN  I_LevelRaw|    |IN2 27648.0  |     |IN2 100.0    |-- Level    |
 |        +-------------+     +-------------+     +-------------+            |

Network 2 — Auto fill demand with hysteresis (seal-in between 20 % and 80 %)
 |----+----[ Level <= 20.0 ]----+----[/ Level >= 80.0 ]-------( M_AutoFill )--|
 |    +----[ M_AutoFill ]-------+                                            |

Network 3 — High-high alarm SET
 |----[ Level >= 95.0 ]-------------------------------------( S  M_AlarmHH )--|

Network 4 — High-high alarm RESET (operator + level must be OK)
 |----[ I_AlarmReset ]----[ Level < 95.0 ]------------------( R  M_AlarmHH )--|

Network 5 — Low-low alarm with 2 s filter
 |                                 T_LowFilter                               |
 |----[ Level <= 5.0 ]------------[ TON PT=T#2s ]-----------( Q_AlarmLow )---|

Network 6 — Pump output: mode selection + interlock
 |----+----[ I_AutoMode ]----[ M_AutoFill ]----+----[/ M_AlarmHH ]---( Q_Pump )---|
 |    +----[/ I_AutoMode ]---[ I_ManualPump ]--+                                |

Network 7 — High-high alarm lamp
 |----[ M_AlarmHH ]-----------------------------------------( Q_AlarmHigh )--|
```

---

## Net-by-net explanation

### Network 1 — Scaling
* `INT_TO_REAL` converts the integer to a decimal number. **Do this first!**
  If you divide integers, `13824 / 27648 = 0` (integer division drops the decimals) → level is always 0 %.
* Divide by full scale (27 648) → 0.0 … 1.0, multiply by 100 → 0 … 100 %.
* Example: raw = 13 824 → 13824.0 / 27648.0 × 100.0 = **50.0 %**.

### Network 2 — Hysteresis (auto fill demand)
Same shape as the motor seal-in in Lesson 1:

| Lesson 1 | Lesson 5 |
|----------|----------|
| `[ I_Start ]` | `[ Level <= 20.0 ]` — tank is low → start filling |
| `[ Q_Motor ]` seal-in | `[ M_AutoFill ]` seal-in — keep filling in the dead band |
| `[/ I_Stop ]` | `[/ Level >= 80.0 ]` — tank is full → stop |

Walk through: level 50 % falling → 20 % → `M_AutoFill` = 1 → pump fills → level 21…79 %:
the compare contact is open but the seal-in holds → 80 % → NC compare opens → `M_AutoFill` = 0
→ level drops through 79…21 %: nothing starts it again until 20 %.

### Networks 3 & 4 — Latched alarm with Set/Reset coils
* `(S M_AlarmHH)` sets the bit to 1 **and leaves it** even after the rung goes false.
* `(R M_AlarmHH)` clears it, but only when **both** RESET is pressed **and** level is safe.
  Pressing RESET while the tank is still at 97 % does nothing — good design.
* S/R coils are the alternative to a seal-in. Rule: the **later** network wins if both are true
  in the same scan. Here Reset is after Set, but they can never both be true (≥ 95 and < 95).

### Network 5 — Filtered low-low alarm
The TON only gives `Q` when `Level <= 5 %` is **continuously** true for 2 s. A wave that
dips the level for 0.5 s resets the timer → no false alarm. This is the standard way to
**debounce** any noisy signal (also used for float switches, pressure switches...).

### Network 6 — Pump output, modes and interlock
Read it as:

> **Pump = ( (AUTO and auto demand) OR (MANUAL and button pressed) ) AND NOT high-high alarm**

* The two parallel branches are the **mode selection** — `[ I_AutoMode ]` and `[/ I_AutoMode ]`
  are opposites, so only one branch can ever be active.
* `[/ M_AlarmHH ]` is in **series after** the OR → it blocks the pump in **both** modes.
  This is an **interlock**: a condition that overrides the operator. Interlocks must
  always be placed **last, in series, right before the output**.
* Only **one** network writes `Q_Pump`. Never write an output in two places (double coil).

### Network 7 — Alarm lamp
Copies the latched alarm to the lamp.

---

## Structured Text

See [program.st](program.st). Note the `REAL` literals `27648.0`, `100.0` — with the `.0`
they are REAL, not INT.

---

## Exercises

1. **Wire break detection:** if `I_LevelRaw < -500` or `> 29000`, set `M_SensorFault`, stop the pump, and turn on both alarm lamps.
2. Make the setpoints (20 / 80 / 95 / 5) **variables** so an HMI can change them. Add a check that `Low < High`.
3. Add a **dry-run protection**: if the pump runs for 60 s and the level did not rise by at least 2 %, stop it and alarm.
4. Add a **pump run-hours counter** (REAL hours, RETAIN) for maintenance.

---

**Congratulations!** You have now used every basic building block of PLC programming:
contacts, coils, seal-in, set/reset, timers, counters, edges, compare, math,
sequences, modes, alarms and interlocks. Real machines are mostly these pieces combined.
