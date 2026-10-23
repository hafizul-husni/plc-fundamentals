(*
  Lesson 5 - Tank level control: analog scaling, hysteresis,
             latched alarm, filtered alarm, Auto/Manual, interlock
  Language : IEC 61131-3 Structured Text
*)
PROGRAM TankLevelControl
VAR
    (* ---- Inputs ---- *)
    I_LevelRaw   AT %IW0   : INT;   (* 0 .. 27648 = 0 .. 100 % (Siemens range) *)
    I_AutoMode   AT %IX0.0 : BOOL;  (* 1 = AUTO, 0 = MANUAL *)
    I_ManualPump AT %IX0.1 : BOOL;  (* hold to run in MANUAL *)
    I_AlarmReset AT %IX0.2 : BOOL;

    (* ---- Outputs ---- *)
    Q_Pump       AT %QX0.0 : BOOL;
    Q_AlarmHigh  AT %QX0.1 : BOOL;
    Q_AlarmLow   AT %QX0.2 : BOOL;

    (* ---- Internal ---- *)
    Level        : REAL;            (* scaled level in % *)
    M_AutoFill   : BOOL;            (* auto fill demand  *)
    M_AlarmHH    : BOOL;            (* latched high-high *)
    T_LowFilter  : TON;

    (* ---- Setpoints ---- *)
    SP_Start     : REAL := 20.0;
    SP_Stop      : REAL := 80.0;
    SP_HighHigh  : REAL := 95.0;
    SP_LowLow    : REAL := 5.0;
END_VAR

(* ===== Network 1 : Scale raw value to 0..100 %
   Convert to REAL FIRST, otherwise integer division gives 0. *)
Level := INT_TO_REAL(I_LevelRaw) / 27648.0 * 100.0;

(* ===== Network 2 : Auto fill demand with hysteresis
   Same shape as the motor seal-in:
   start = level low, seal-in = keep filling, stop = level high. *)
M_AutoFill := ((Level <= SP_Start) OR M_AutoFill) AND NOT (Level >= SP_Stop);

(* ===== Network 3 : High-high alarm SET (latch) ===== *)
IF Level >= SP_HighHigh THEN
    M_AlarmHH := TRUE;
END_IF;

(* ===== Network 4 : High-high alarm RESET
   Only when the operator presses reset AND the level is safe again. *)
IF I_AlarmReset AND (Level < SP_HighHigh) THEN
    M_AlarmHH := FALSE;
END_IF;

(* ===== Network 5 : Low-low alarm, must be true for 2 s (filter) ===== *)
T_LowFilter(IN := Level <= SP_LowLow, PT := T#2s);
Q_AlarmLow := T_LowFilter.Q;

(* ===== Network 6 : Pump output
   (AUTO branch OR MANUAL branch) AND NOT interlock.
   The interlock is last and in series: it overrides every mode. *)
Q_Pump := ((I_AutoMode AND M_AutoFill) OR (NOT I_AutoMode AND I_ManualPump))
          AND NOT M_AlarmHH;

(* ===== Network 7 : High-high alarm lamp ===== *)
Q_AlarmHigh := M_AlarmHH;

END_PROGRAM
