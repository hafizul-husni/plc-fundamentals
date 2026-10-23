(*
  Lesson 4 - Traffic light: sequence / state machine with CASE
  Language : IEC 61131-3 Structured Text
*)
PROGRAM TrafficLight
VAR
    (* ---- Inputs ---- *)
    I_Start  AT %IX0.0 : BOOL;
    I_Stop   AT %IX0.1 : BOOL;

    (* ---- Outputs ---- *)
    Q_Red    AT %QX0.0 : BOOL;
    Q_Yellow AT %QX0.1 : BOOL;
    Q_Green  AT %QX0.2 : BOOL;

    (* ---- Internal ---- *)
    M_Enable : BOOL;
    Step     : INT := 0;            (* 0 = RED, 1 = GREEN, 2 = YELLOW *)
    T_Red    : TON;
    T_Green  : TON;
    T_Yellow : TON;
END_VAR

(* ===== Network 1 : Enable (seal-in) ===== *)
M_Enable := (I_Start OR M_Enable) AND NOT I_Stop;

(* ===== Network 2 : Not enabled -> safe state (RED) ===== *)
IF NOT M_Enable THEN
    Step := 0;
END_IF;

(* ===== Networks 3-5 : Step timers =====
   Called EVERY scan, outside the CASE, so that each timer sees
   IN = FALSE when its step is left and resets itself. *)
T_Red   (IN := M_Enable AND (Step = 0), PT := T#5s);
T_Green (IN := M_Enable AND (Step = 1), PT := T#4s);
T_Yellow(IN := M_Enable AND (Step = 2), PT := T#2s);

(* ===== Networks 6-8 : Transitions ===== *)
CASE Step OF
    0:  (* RED *)
        IF T_Red.Q THEN
            Step := 1;
        END_IF;

    1:  (* GREEN *)
        IF T_Green.Q THEN
            Step := 2;
        END_IF;

    2:  (* YELLOW *)
        IF T_Yellow.Q THEN
            Step := 0;
        END_IF;

ELSE
    Step := 0;                      (* unknown step -> safe state *)
END_CASE;

(* ===== Network 9 : Outputs depend ONLY on the step ===== *)
Q_Red    := (Step = 0);
Q_Green  := (Step = 1);
Q_Yellow := (Step = 2);

END_PROGRAM
