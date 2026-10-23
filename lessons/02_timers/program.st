(*
  Lesson 2 - Timers: TON (on-delay), TP (pulse), TOF (off-delay)
  Language : IEC 61131-3 Structured Text
*)
PROGRAM TimersDemo
VAR
    (* ---- Inputs ---- *)
    I_Start AT %IX0.0 : BOOL;   (* 1 = pressed *)
    I_Stop  AT %IX0.1 : BOOL;   (* 1 = pressed *)

    (* ---- Outputs ---- *)
    Q_Motor AT %QX0.0 : BOOL;
    Q_Horn  AT %QX0.1 : BOOL;
    Q_Fan   AT %QX0.2 : BOOL;

    (* ---- Internal ---- *)
    M_RunRequest : BOOL;

    (* ---- Timer instances (each one has its own memory) ---- *)
    T_StartDelay  : TON;        (* on-delay  *)
    T_Horn        : TP;         (* pulse     *)
    T_FanAfterRun : TOF;        (* off-delay *)
END_VAR

(* ===== Network 1 : Run request (seal-in) ===== *)
M_RunRequest := (I_Start OR M_RunRequest) AND NOT I_Stop;

(* ===== Network 2 : Motor starts 5 s after the request =====
   ET counts up while IN is TRUE. Q becomes TRUE when ET >= PT.
   IN = FALSE resets the timer at once. *)
T_StartDelay(IN := M_RunRequest, PT := T#5s);
Q_Motor := T_StartDelay.Q;

(* ===== Network 3 : Horn sounds 3 s on the rising edge of the request =====
   TP gives a fixed-length pulse, independent of how long IN stays TRUE. *)
T_Horn(IN := M_RunRequest, PT := T#3s);
Q_Horn := T_Horn.Q;

(* ===== Network 4 : Fan follows the motor and runs on for 10 s =====
   Q is TRUE as soon as IN is TRUE. After IN goes FALSE, Q stays TRUE for PT. *)
T_FanAfterRun(IN := Q_Motor, PT := T#10s);
Q_Fan := T_FanAfterRun.Q;

END_PROGRAM
