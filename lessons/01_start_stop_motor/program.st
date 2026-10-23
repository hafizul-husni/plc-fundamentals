(*
  Lesson 1 - Start/Stop Motor with seal-in (latching)
  Language : IEC 61131-3 Structured Text
  Tested on: OpenPLC / CODESYS syntax
*)
PROGRAM StartStopMotor
VAR
    (* ---- Inputs ---- *)
    I_Start     AT %IX0.0 : BOOL;   (* Start push button, 1 = pressed      *)
    I_Stop      AT %IX0.1 : BOOL;   (* Stop push button,  1 = pressed      *)
    I_Overload  AT %IX0.2 : BOOL;   (* Thermal overload,  1 = tripped      *)

    (* ---- Outputs ---- *)
    Q_Motor     AT %QX0.0 : BOOL;   (* Motor contactor                     *)
    Q_LampRun   AT %QX0.1 : BOOL;   (* Green running lamp                  *)
    Q_LampFault AT %QX0.2 : BOOL;   (* Red fault lamp                      *)
END_VAR

(* ===== Network 1 : Motor start/stop with seal-in =====
   (I_Start OR Q_Motor)  -> parallel branch: start OR already running (seal-in)
   AND NOT I_Stop        -> series NC contact: stop breaks the path
   AND NOT I_Overload    -> series NC contact: overload breaks the path
   Q_Motor on the right side reads its OWN value from the previous scan.  *)
Q_Motor := (I_Start OR Q_Motor) AND NOT I_Stop AND NOT I_Overload;

(* ===== Network 2 : Run lamp =====
   Runs after Network 1, so it sees the motor value of THIS scan. *)
Q_LampRun := Q_Motor;

(* ===== Network 3 : Fault lamp ===== *)
Q_LampFault := I_Overload;

(* ---------------------------------------------------------------
   Alternative way with IF (same behaviour, easier to read for some):

   IF I_Stop OR I_Overload THEN
       Q_Motor := FALSE;          <- stop has priority
   ELSIF I_Start THEN
       Q_Motor := TRUE;           <- latch ON
   END_IF;
   If nothing is pressed, Q_Motor keeps its value = memory.
   (Note: comments cannot be nested, so this block has no inner comments.)
   --------------------------------------------------------------- *)

END_PROGRAM
