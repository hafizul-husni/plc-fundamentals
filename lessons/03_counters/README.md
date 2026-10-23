# Lesson 3 — Counters & Edge Detection (CTU, R_TRIG)

## Why edge detection matters

A box passes a photo-eye sensor. The sensor is TRUE for maybe **200 ms**.
The PLC scans every **5 ms**. So the sensor is TRUE for **~40 scans**.

If you write `IF I_BoxSensor THEN Count := Count + 1;` you count **40 boxes for 1 box!**

You must react only to the **rising edge** — the single scan where the signal
changes from FALSE to TRUE.

```
I_BoxSensor  ____┌────────────┐________┌────────────┐____
rising edge  ____┌┐___________________┌┐________________   (TRUE for 1 scan only)
                 ^ count +1             ^ count +1
```

| Block | Output is TRUE for one scan when... | Ladder symbol (common) |
|-------|-------------------------------------|------------------------|
| `R_TRIG` | input goes FALSE → TRUE (rising) | `--[ P ]--` |
| `F_TRIG` | input goes TRUE → FALSE (falling) | `--[ N ]--` |

The standard counter **CTU already has edge detection built in** on its `CU` input.
But you still need `R_TRIG` whenever you write counting logic yourself.

## CTU — Count Up

```
          +---------+
  CU   ---|CU  CTU Q|---  Q  = TRUE when CV >= PV
  RESET---|R        |
  PV   ---|PV     CV|---  CV = Current Value
          +---------+
```

* Every rising edge on `CU` → `CV := CV + 1`.
* `RESET` = TRUE → `CV := 0`.
* `Q` = TRUE when `CV >= PV`.

(There is also `CTD` count down and `CTUD` up/down — same idea.)

---

## The problem

A packing conveyor fills a carton with **10 boxes**:

1. START / STOP run the conveyor (seal-in again).
2. A photo-eye `I_BoxSensor` counts each box.
3. At **10 boxes** → conveyor **stops** and lamp "Batch done" turns ON.
4. Operator replaces the carton and presses **RESET** → count goes to 0, press START again.
5. A **total counter** counts all boxes of the shift (never reset by RESET).

## I/O list

| Tag | Address | Type | Description |
|-----|---------|------|-------------|
| `I_Start` | `%IX0.0` | BOOL | Start (1 = pressed) |
| `I_Stop` | `%IX0.1` | BOOL | Stop (1 = pressed) |
| `I_BoxSensor` | `%IX0.2` | BOOL | Photo-eye, 1 = box present |
| `I_Reset` | `%IX0.3` | BOOL | Batch reset (1 = pressed) |
| `Q_Conveyor` | `%QX0.0` | BOOL | Conveyor motor |
| `Q_LampDone` | `%QX0.1` | BOOL | "Batch done" lamp |
| `C_Batch` | — | CTU | Batch counter, PV = 10 |
| `M_BatchDone` | — | BOOL | Batch complete |
| `Trig_Box` | — | R_TRIG | Rising edge of box sensor |
| `TotalBoxes` | — | DINT | Shift total |

---

## Ladder Diagram

```
Network 1 — Conveyor run (seal-in) — stops when batch is done
 |----+----[ I_Start ]-----+----[/ I_Stop ]----[/ M_BatchDone ]-----( Q_Conveyor )--|
 |    +----[ Q_Conveyor ]--+                                                       |

Network 2 — Batch counter
 |                             C_Batch                                             |
 |                            +---------+                                          |
 |----[ I_BoxSensor ]---------|CU  CTU Q|-----------------------( M_BatchDone )----|
 |----[ I_Reset ]-------------|R        |                                          |
 |                       10 --|PV     CV|-- C_Batch.CV                             |
 |                            +---------+                                          |

Network 3 — Batch done lamp
 |----[ M_BatchDone ]-------------------------------------------( Q_LampDone )-----|

Network 4 — Shift total (manual counting with an edge)
 |                                         +-----------------+                     |
 |----[ I_BoxSensor ]----[ P ]-------------|EN   ADD      ENO|                     |
 |                                         |IN1 TotalBoxes   |                     |
 |                                         |IN2 1     OUT    |-- TotalBoxes        |
 |                                         +-----------------+                     |
```

---

## Net-by-net explanation

### Network 1 — Conveyor run
Same seal-in as Lesson 1, plus one more NC contact `[/ M_BatchDone ]`.
When the batch is complete, `M_BatchDone` = 1 → NC contact opens → conveyor stops
**and the seal is broken**, so it will not restart by itself after RESET.
The operator must press START again. That is intentional (safe restart).

> Scan order note: Net 1 uses `M_BatchDone` calculated by Net 2 in the **previous**
> scan. The conveyor stops one scan (a few ms) after the 10th box. Harmless here,
> but now you know why order matters.

### Network 2 — Batch counter (CTU)
* `CU` = `I_BoxSensor`. Each **rising edge** adds 1 to `CV`. Holding the sensor
  TRUE for 40 scans still counts only 1 — the CTU remembers the previous value of `CU`.
* `R` = `I_Reset`. Pressing RESET makes `CV` = 0 and `Q` = FALSE.
* `PV` = 10. When `CV` reaches 10, `Q` → TRUE → `M_BatchDone` = 1.
* If a box still slides through after the conveyor stops, `CV` becomes 11. `Q` stays TRUE
  (`CV >= PV`). That is fine.

### Network 3 — Lamp
Copies `M_BatchDone` to the real lamp output.

### Network 4 — Shift total with explicit edge
* `[ P ]` (positive transition / R_TRIG) passes power for **one scan only** when the sensor goes 0 → 1.
* The `ADD` block runs only when `EN` gets power: `TotalBoxes := TotalBoxes + 1`.
* Remove the `[ P ]` and watch `TotalBoxes` jump by dozens per box — try it in the simulator! That
  is the #1 beginner bug.
* `TotalBoxes` is `DINT` because an `INT` overflows at 32 767.
  In a real PLC you would make it **RETAIN** so it survives a power cycle.

---

## Structured Text

See [program.st](program.st).

```iecst
Trig_Box(CLK := I_BoxSensor);      (* Trig_Box.Q is TRUE for one scan *)
IF Trig_Box.Q THEN
    TotalBoxes := TotalBoxes + 1;
END_IF;
```

---

## Exercises

1. Show "boxes remaining": `Remaining := 10 - C_Batch.CV`.
2. Make the batch size adjustable from an HMI: replace `10` with a variable `BatchSize : INT := 10;`.
3. Count **rejected** boxes with a second sensor and a **CTD** that counts down from 5 — stop the line if it reaches 0.
4. Write your own counter **without** CTU, using only `R_TRIG` and `+ 1`.

Next: [Lesson 4 — Traffic light](../04_traffic_light/)
