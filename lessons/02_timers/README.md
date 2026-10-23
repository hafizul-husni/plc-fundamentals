# Lesson 2 — Timers (TON, TOF, TP)

> Timers are function blocks. Unlike a contact or coil, a timer has **memory and
> an internal clock**, so you must create an **instance** of it (like `T_StartDelay`).

## The three standard IEC timers

```
        IN ─┐          ┌──── Q            PT = Preset Time (e.g. T#5s)
            │  TON     │                  ET = Elapsed Time (counts up)
        PT ─┤          ├──── ET
            └──────────┘
```

### TON — On-delay ("wait before turning ON")

```
IN  ___┌─────────────────┐_______        ┌──┐_________
       │                 │               │  │   (IN shorter than PT
Q   ___│_____┌───────────┐_______  Q ____│__│_____    -> Q never turns on)
       |<-PT->|
```
Q turns ON **PT after IN turns ON**. Q turns OFF **immediately** when IN goes OFF.
If IN goes off before PT, the timer resets and Q never turns on.

### TOF — Off-delay ("stay ON a while after")

```
IN  ___┌──────────┐______________
Q   ___┌──────────────────┐______
                  |<--PT-->|
```
Q turns ON **immediately** with IN. Q turns OFF **PT after IN turns OFF**.

### TP — Pulse ("fixed length pulse")

```
IN  ___┌─┐______________   ┌──────────────────────┐___
Q   ___┌─────────┐_______  ┌─────────┐_______________
       |<--PT--->|         |<--PT--->|
```
A rising edge on IN gives a pulse of **exactly PT**, no matter how long IN stays on.

---

## The problem (uses all three)

A machine with a fan, a warning horn and a motor:

1. Operator presses **START** (`I_Start`) → a **horn** sounds for **3 s** (TP) to warn people.
2. The **motor starts 5 s after** START (TON) — "pre-start warning" time.
3. When the motor stops, the **cooling fan keeps running 10 s** (TOF).
4. **STOP** (`I_Stop`) stops everything.

## I/O list

| Tag | Address | Type | Description |
|-----|---------|------|-------------|
| `I_Start` | `%IX0.0` | BOOL | Start button (1 = pressed) |
| `I_Stop` | `%IX0.1` | BOOL | Stop button (1 = pressed) |
| `Q_Motor` | `%QX0.0` | BOOL | Main motor |
| `Q_Horn` | `%QX0.1` | BOOL | Warning horn |
| `Q_Fan` | `%QX0.2` | BOOL | Cooling fan |
| `M_RunRequest` | — | BOOL | Internal: operator asked to run |
| `T_StartDelay` | — | TON | 5 s start delay |
| `T_Horn` | — | TP | 3 s horn pulse |
| `T_FanAfterRun` | — | TOF | 10 s fan run-on |

---

## Ladder Diagram

```
Network 1 — Run request (seal-in, same as Lesson 1)
 |----+----[ I_Start ]------+----[/ I_Stop ]----------------( M_RunRequest )--|
 |    +----[ M_RunRequest ]-+                                                 |

Network 2 — Start delay 5 s
 |                         T_StartDelay                                       |
 |                         +---------+                                        |
 |----[ M_RunRequest ]-----|IN  TON Q|------------------------( Q_Motor )-----|
 |                  T#5s --|PT     ET|                                        |
 |                         +---------+                                        |

Network 3 — Warning horn 3 s pulse
 |                         T_Horn                                             |
 |                         +---------+                                        |
 |----[ M_RunRequest ]-----|IN  TP  Q|------------------------( Q_Horn )------|
 |                  T#3s --|PT     ET|                                        |
 |                         +---------+                                        |

Network 4 — Cooling fan, runs on 10 s after motor stops
 |                         T_FanAfterRun                                      |
 |                         +---------+                                        |
 |----[ Q_Motor ]----------|IN  TOF Q|------------------------( Q_Fan )-------|
 |                 T#10s --|PT     ET|                                        |
 |                         +---------+                                        |
```

---

## Net-by-net explanation

### Network 1 — Run request
Same seal-in as Lesson 1, but the result goes to an **internal memory bit**
`M_RunRequest` instead of a real output. Using internal bits for "intentions"
and keeping outputs separate is good practice — the motor is not allowed to
start yet, we only *remember the request*.

### Network 2 — Start delay (TON)
* `IN` = `M_RunRequest`. When the request becomes TRUE, the timer starts counting.
* `ET` grows: 0 s … 1 s … 5 s. While `ET < PT`, `Q` = FALSE → motor still OFF.
* When `ET` reaches 5 s, `Q` = TRUE → `Q_Motor` ON.
* Press STOP → `M_RunRequest` = FALSE → `IN` = FALSE → TON **resets** immediately
  (`ET` = 0, `Q` = FALSE) → motor OFF at once.
* If STOP is pressed at 3 s, the motor never starts and the next START begins again from 0.

### Network 3 — Horn pulse (TP)
* On the **rising edge** of `M_RunRequest` (FALSE → TRUE) the TP starts.
* `Q_Horn` is TRUE for exactly 3 s, then OFF — even though `M_RunRequest` stays TRUE.
* Horn sounds 0–3 s, motor starts at 5 s → people get a warning before movement.
* Note: a TP pulse cannot be interrupted; if STOP is pressed at 1 s the horn still
  finishes its 3 s. (Try to change that in the exercises.)

### Network 4 — Fan run-on (TOF)
* `IN` = `Q_Motor`. The moment the motor turns ON, `Q_Fan` turns ON (no delay).
* When the motor turns OFF, the TOF starts counting. The fan keeps running.
* After 10 s, `Q_Fan` goes OFF. If the motor restarts during those 10 s, the timer
  resets and the fan just keeps running.

### Timeline for the whole program

```
time (s)    0    1    2    3    4    5   ...  20   21  ...  30   31
I_Start     ┌─┐
I_Stop                                        ┌─┐
M_RunReq    ┌─────────────────────────────────┐
Q_Horn      ┌──────────────┐
Q_Motor                         ┌─────────────┐
Q_Fan                           ┌──────────────────────────────┐
                                             |<----- 10 s ---->|
```

---

## Structured Text

See [program.st](program.st). In ST a timer is **called** like a function, then
you read its outputs:

```iecst
T_StartDelay(IN := M_RunRequest, PT := T#5s);
Q_Motor := T_StartDelay.Q;
```

**Important:** the timer must be called **every scan** (not inside an `IF` that is
sometimes skipped). If you stop calling it, it stops updating.

---

## Exercises

1. Show remaining time: make `INT` `RemainingSec` = `(PT - ET)` in seconds. *Hint: `TIME_TO_INT(...) / 1000`.*
2. Make the horn stop immediately when STOP is pressed. *Hint: put `AND M_RunRequest` after the TP output.*
3. Build a **flasher** (lamp 0.5 s ON / 0.5 s OFF) with two TONs that reset each other. This is a classic interview question!

Next: [Lesson 3 — Counters](../03_counters/)
