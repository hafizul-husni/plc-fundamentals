(*
  Lesson 3 - Counters (CTU) and edge detection (R_TRIG)
  Language : IEC 61131-3 Structured Text
*)
PROGRAM CountersDemo
VAR
    (* ---- Inputs ---- *)
    I_Start     AT %IX0.0 : BOOL;
    I_Stop      AT %IX0.1 : BOOL;
    I_BoxSensor AT %IX0.2 : BOOL;   (* photo-eye, 1 = box present *)
    I_Reset     AT %IX0.3 : BOOL;

    (* ---- Outputs ---- *)
    Q_Conveyor  AT %QX0.0 : BOOL;
    Q_LampDone  AT %QX0.1 : BOOL;

    (* ---- Internal ---- *)
    M_BatchDone : BOOL;
    C_Batch     : CTU;              (* counter instance        *)
    Trig_Box    : R_TRIG;           (* rising-edge detector    *)
    BatchSize   : INT  := 10;
    TotalBoxes  : DINT := 0;        (* make RETAIN on a real PLC *)
END_VAR

(* ===== Network 1 : Conveyor run, stops when the batch is done ===== *)
Q_Conveyor := (I_Start OR Q_Conveyor) AND NOT I_Stop AND NOT M_BatchDone;

(* ===== Network 2 : Batch counter =====
   CU is edge-triggered inside CTU: one box = +1, even if the
   sensor stays TRUE for many scans. R resets CV to 0. *)
C_Batch(CU := I_BoxSensor, R := I_Reset, PV := BatchSize);
M_BatchDone := C_Batch.Q;           (* TRUE when CV >= PV *)

(* ===== Network 3 : Batch done lamp ===== *)
Q_LampDone := M_BatchDone;

(* ===== Network 4 : Shift total with an explicit rising edge =====
   Trig_Box.Q is TRUE for exactly ONE scan when I_BoxSensor goes 0 -> 1.
   Without the edge, TotalBoxes would increase on every scan
   while the box is in front of the sensor (beginner bug #1). *)
Trig_Box(CLK := I_BoxSensor);
IF Trig_Box.Q THEN
    TotalBoxes := TotalBoxes + 1;
END_IF;

END_PROGRAM
