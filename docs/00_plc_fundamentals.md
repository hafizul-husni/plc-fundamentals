# Lesson 0 — PLC Fundamentals

Read this first. Everything else in the repo is built on these ideas.

---

## 1. What is a PLC?

A **PLC (Programmable Logic Controller)** is an industrial computer that:

1. **Reads inputs** — push buttons, limit switches, proximity sensors, level sensors.
2. **Runs your program** — your logic decides what should happen.
3. **Writes outputs** — motors (through contactors), lamps, valves, buzzers.

It does these three steps again and again, forever, very fast (typically 1–20 ms).
This loop is called the **scan cycle**.

---

## 2. The scan cycle (most important concept)

```
      ┌──────────────────────────────────────────────┐
      │                                              │
      ▼                                              │
 ┌──────────┐    ┌───────────────────┐    ┌──────────┴──┐
 │ 1. READ  │ -> │ 2. EXECUTE PROGRAM │ -> │ 3. WRITE    │
 │  INPUTS  │    │  Net 1, Net 2, ... │    │   OUTPUTS   │
 │ (copy to │    │  top to bottom,    │    │ (copy image │
 │  input   │    │  left to right     │    │  to real    │
 │  image)  │    │                    │    │  terminals) │
 └──────────┘    └───────────────────┘    └─────────────┘
```

Key facts beginners usually miss:

* **Inputs are frozen during the scan.** The PLC copies all inputs into memory
  (the *input image*) at the start. If a button changes in the middle of the
  scan, the program only sees it on the *next* scan.
* **Networks run in order, top to bottom.** Net 2 can use the result Net 1 just
  calculated in the *same* scan. Net 1 sees Net 2's result only on the *next* scan.
  Order matters!
* **Outputs change at the end.** Writing `Q_Motor := TRUE` in Net 3 does not turn
  the motor on immediately — the real terminal changes after the whole program has run.
* **The last write wins.** If two networks write the same coil, only the last one
  counts. This is called a **double coil** — avoid it.

---

## 3. Reading a Ladder Diagram

Ladder looks like an electrical relay drawing turned on its side.

```
 Left power rail                                  Right power rail
 |                                                         |
 |----[ I_Start ]------[/ I_Stop ]--------------( Q_Motor )-|
 |                                                         |
     contact (condition)   contact (condition)     coil (result)
```

Think of **"power" flowing from left to right**. If there is a complete path,
the coil on the right becomes TRUE (energized).

### The 3 basic symbols

| Symbol | Name | It is TRUE (passes power) when... | ST equivalent |
|--------|------|-----------------------------------|---------------|
| `--[ A ]--` | **NO contact** (Normally Open, XIC) | bit `A` is **1** | `A` |
| `--[/ A ]--` | **NC contact** (Normally Closed, XIO) | bit `A` is **0** | `NOT A` |
| `--( Y )--` | **Coil** (OTE) | writes the rung result into `Y` | `Y := ...;` |
| `--(S Y)--` | **Set coil** (latch) | sets `Y` to 1 and leaves it there | `IF ... THEN Y := TRUE; END_IF;` |
| `--(R Y)--` | **Reset coil** (unlatch) | sets `Y` to 0 and leaves it there | `IF ... THEN Y := FALSE; END_IF;` |

### Series = AND, Parallel = OR

```
 Series (AND):                     Parallel (OR):
 |--[ A ]--[ B ]--( Y )--|         |--+--[ A ]--+--( Y )--|
                                   |  |         |
 Y := A AND B;                     |  +--[ B ]--+
                                   Y := A OR B;
```

---

## 4. The NO/NC trap (very important on site!)

There are **two different "NC"** ideas, and beginners mix them up:

1. **The physical button** — a Stop button is normally wired as an **NC contact**
   (closed when not pressed). So the PLC input `I_Stop` is **1 when NOT pressed**
   and **0 when pressed**. This is *fail-safe*: if the wire breaks, the input goes
   to 0 and the machine stops.
2. **The contact in the program** — `[ ]` or `[/ ]` is what *you* check in the logic.

So with a physically NC Stop button you write a **NO contact** `[ I_Stop ]` in the
program, because "input is 1" means "stop is OK / not pressed".

In this repo, to keep it simple for learning, inputs are described as **1 = pressed**
unless the lesson says otherwise. Always check the electrical drawing on site.

---

## 5. Ladder vs Structured Text — when to use which?

| | Ladder Diagram (LD) | Structured Text (ST) |
|---|---|---|
| Looks like | Electrical drawing | Programming language (like Pascal) |
| Good for | Bit logic, interlocks, simple sequences | Math, loops, arrays, data handling, complex states |
| Who reads it | Electricians & maintenance on site | Engineers |
| Debugging online | Very easy — you *see* power flow | Need to watch variables |

Real projects often mix them: interlocks and outputs in LD, calculations in ST.
**Learn both** — that is why every lesson here has both.

---

## 6. Data types you will use

| Type | Size | Values | Use |
|------|------|--------|-----|
| `BOOL` | 1 bit | TRUE / FALSE | Buttons, sensors, coils |
| `INT` | 16 bit | -32768 … 32767 | Counters, raw analog values |
| `DINT` | 32 bit | ±2 billion | Big counters |
| `REAL` | 32 bit | Decimal numbers | Scaled analog (e.g. 45.7 %) |
| `TIME` | — | `T#5s`, `T#200ms` | Timer presets |

Next: [Lesson 1 — Start/Stop motor](../lessons/01_start_stop_motor/)
