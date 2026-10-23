"""
PLC scan-cycle simulator for learning.

It imitates what a real PLC does on every scan:
    1. READ INPUTS   -> copy the "real world" into the input image
    2. EXECUTE       -> run Network 1, Network 2, ... top to bottom
    3. WRITE OUTPUTS -> copy the output image to the "real world"

and prints the state of every network, so you can SEE the logic work.

Usage:
    python simulator/scan_sim.py        -> Lesson 1: start/stop seal-in
    python simulator/scan_sim.py 3      -> Lesson 3: edge detection (and the bug without it)
"""

import sys


def b(value):
    """Show a BOOL as 1/0 like a PLC online view."""
    return "1" if value else "0"


# ---------------------------------------------------------------------------
# Lesson 1 - Start/Stop motor with seal-in
# ---------------------------------------------------------------------------
def lesson1():
    # What the operator does on each scan (the "real world").
    scenario = [
        ("Idle",                    dict(start=0, stop=0, overload=0)),
        ("Press START",             dict(start=1, stop=0, overload=0)),
        ("Still holding START",     dict(start=1, stop=0, overload=0)),
        ("Release START",           dict(start=0, stop=0, overload=0)),
        ("Running...",              dict(start=0, stop=0, overload=0)),
        ("Press STOP",              dict(start=0, stop=1, overload=0)),
        ("Release STOP",            dict(start=0, stop=0, overload=0)),
        ("Press START again",       dict(start=1, stop=0, overload=0)),
        ("Release START",           dict(start=0, stop=0, overload=0)),
        ("Overload trips!",         dict(start=0, stop=0, overload=1)),
        ("Overload reset",          dict(start=0, stop=0, overload=0)),
        ("Press START + STOP",      dict(start=1, stop=1, overload=0)),
    ]

    # PLC memory. Outputs keep their value between scans - that is what
    # makes the seal-in possible.
    q_motor = False
    q_lamp_run = False
    q_lamp_fault = False

    print("Lesson 1 - Start/Stop motor with seal-in\n")
    print("Net 1: Q_Motor := (I_Start OR Q_Motor) AND NOT I_Stop AND NOT I_Overload")
    print("Net 2: Q_LampRun := Q_Motor")
    print("Net 3: Q_LampFault := I_Overload\n")

    header = (f"{'Scan':>4} | {'Event':<22} | Start Stop OvL | "
              f"BranchA BranchB(seal) | Motor LampRun LampFlt")
    print(header)
    print("-" * len(header))

    for scan, (event, world) in enumerate(scenario, start=1):
        # 1. READ INPUTS (frozen for the whole scan)
        i_start = bool(world["start"])
        i_stop = bool(world["stop"])
        i_overload = bool(world["overload"])

        # 2. EXECUTE PROGRAM
        # Network 1 - seal-in. Branch B reads Q_Motor from the PREVIOUS scan.
        branch_a = i_start
        branch_b = q_motor
        q_motor = (branch_a or branch_b) and not i_stop and not i_overload
        # Network 2
        q_lamp_run = q_motor
        # Network 3
        q_lamp_fault = i_overload

        # 3. WRITE OUTPUTS (here: print them)
        print(f"{scan:>4} | {event:<22} |   {b(i_start)}    {b(i_stop)}    {b(i_overload)}  |"
              f"    {b(branch_a)}         {b(branch_b)}        |   {b(q_motor)}      "
              f"{b(q_lamp_run)}       {b(q_lamp_fault)}")

    print("\nLook at scan 4: START is released (BranchA=0) but BranchB (the motor's")
    print("own contact) is still 1, so the motor keeps running. That is the seal-in.")
    print("Scan 12: START and STOP together -> motor OFF. STOP is dominant (safe).")


# ---------------------------------------------------------------------------
# Lesson 3 - Edge detection: why counting needs R_TRIG
# ---------------------------------------------------------------------------
class RTrig:
    """IEC 61131-3 R_TRIG: Q is TRUE for one scan on a FALSE -> TRUE change."""

    def __init__(self):
        self.mem = False
        self.q = False

    def __call__(self, clk):
        self.q = clk and not self.mem
        self.mem = clk
        return self.q


def lesson3():
    # Sensor signal, one value per scan. Two boxes pass; each one covers
    # the photo-eye for several scans (like a real 200 ms box at 5 ms scans).
    sensor = [0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0]

    trig = RTrig()
    count_with_edge = 0
    count_without_edge = 0

    print("Lesson 3 - Counting boxes WITH and WITHOUT edge detection\n")
    print("WITH edge   : Trig(CLK := Sensor); IF Trig.Q THEN Count := Count + 1;")
    print("WITHOUT edge: IF Sensor THEN Count := Count + 1;   <- beginner bug\n")

    header = f"{'Scan':>4} | Sensor | R_TRIG.Q | Count(with edge) | Count(NO edge)"
    print(header)
    print("-" * len(header))

    for scan, value in enumerate(sensor, start=1):
        i_sensor = bool(value)

        if trig(i_sensor):
            count_with_edge += 1
        if i_sensor:
            count_without_edge += 1

        print(f"{scan:>4} |   {b(i_sensor)}    |    {b(trig.q)}     |"
              f"        {count_with_edge:<9} |      {count_without_edge}")

    print(f"\n2 boxes passed. With edge: {count_with_edge}. Without edge: {count_without_edge}.")
    print("R_TRIG.Q is 1 only on the first scan the sensor sees the box.")


if __name__ == "__main__":
    lesson = sys.argv[1] if len(sys.argv) > 1 else "1"
    if lesson == "3":
        lesson3()
    else:
        lesson1()
