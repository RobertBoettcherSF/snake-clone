--  Native batch: 100 seed pairs (k, k) for k = 1 .. 100.
--  Reports mean/median score, length and turns, plus the win count.
with Ada.Text_IO;
with Snake;
with Snake.Auto;

procedure Batch is
   use Snake;
   use Ada.Text_IO;

   type Counts is array (1 .. 100) of Integer;
   Max_Ticks : constant := 200_000;
   N         : constant Integer := 100;

   Scores, Lengths, Turns : Counts := [others => 0];
   Wins, Caps             : Integer := 0;
   Wall_N, Self_N, Trap_N : Integer := 0;
   K, Guard               : Integer;
   W                      : World;
   Sum_S, Sum_L, Sum_T    : Long_Integer := 0;

   procedure Sort (A : in out Counts) is
      J     : Integer;
      Value : Integer;
   begin
      for I in 2 .. N loop
         Value := A (I);
         J := I - 1;
         while J >= 1 and then A (J) > Value loop
            A (J + 1) := A (J);
            J := J - 1;
         end loop;
         A (J + 1) := Value;
      end loop;
   end Sort;

   function Median (A : Counts) return String is
      --  Even N: mean of the two central values, printed to one tenth.
      Left  : constant Integer := A (N / 2);
      Right : constant Integer := A (N / 2 + 1);
      Tenths : constant Integer := Left + Right;
      Whole  : constant Integer := Tenths / 2;
      Frac   : constant Integer := (Tenths rem 2) * 5;
      Img    : constant String := Integer'Image (Whole);
      Trim   : constant String := Img (Img'First + 1 .. Img'Last);
   begin
      return Trim & "." & Character'Val (Character'Pos ('0') + Frac);
   end Median;

   function Mean (Sum : Long_Integer) return String is
      --  One decimal place.
      Tenths : constant Long_Integer := (Sum * 10) / Long_Integer (N);
      Whole  : constant Integer := Integer (Tenths / 10);
      Frac   : constant Integer := Integer (Tenths rem 10);
      Img    : constant String := Integer'Image (Whole);
      Trim   : constant String := Img (Img'First + 1 .. Img'Last);
      Sign   : constant String := (if Whole < 0 then "-" else "");
      Body_S : constant String :=
        (if Trim'Length = 0 then "0"
         elsif Trim (Trim'First) = '-' then Trim (Trim'First + 1 .. Trim'Last)
         else Trim);
   begin
      return Sign & Body_S & "." & Character'Val (Character'Pos ('0') + Frac);
   end Mean;
begin
   for I in 1 .. N loop
      K := I;
      Init (W, Seed_Value (K), Seed_Value (K), 0, 0, 0);
      Set_Auto (W, True);
      Guard := 0;
      while W.Alive and then not W.Won and then Guard < Max_Ticks loop
         Snake.Auto.Choose (W);
         Note_Action (W, W.Pending, True);
         Step (W);
         Guard := Guard + 1;
      end loop;
      Scores (I) := Integer (W.Score);
      Lengths (I) := Integer (W.Length);
      Turns (I) := Integer (W.Turns);
      Sum_S := Sum_S + Long_Integer (W.Score);
      Sum_L := Sum_L + Long_Integer (W.Length);
      Sum_T := Sum_T + Long_Integer (W.Turns);
      if W.Won then
         Wins := Wins + 1;
      elsif Guard >= Max_Ticks then
         Caps := Caps + 1;
      else
         case W.Death_Reason is
            when Wall    => Wall_N := Wall_N + 1;
            when Self    => Self_N := Self_N + 1;
            when Trapped => Trap_N := Trap_N + 1;
            when None    => null;
         end case;
      end if;
      if I = 1 or else I = 100 or else I mod 20 = 0 then
         Put_Line
           ("seed" & Integer'Image (K)
            & " score" & Integer'Image (W.Score)
            & " length" & Integer'Image (W.Length)
            & " turns" & Integer'Image (W.Turns)
            & " won=" & Boolean'Image (W.Won)
            & " reason=" & Death_Cause'Image (W.Death_Reason)
            & " area" & Integer'Image (W.Enclosed_Area));
         Flush;
      end if;
   end loop;

   Sort (Scores);
   Sort (Lengths);
   Sort (Turns);

   Put_Line ("BATCH n=" & Integer'Image (N) & " pairs (k,k) k=1..100");
   Put_Line ("mean_score " & Mean (Sum_S) & " median_score " & Median (Scores));
   Put_Line
     ("mean_length " & Mean (Sum_L) & " median_length " & Median (Lengths));
   Put_Line ("mean_turns " & Mean (Sum_T) & " median_turns " & Median (Turns));
   Put_Line ("wins" & Integer'Image (Wins) & "/" & Integer'Image (N));
   Put_Line
     ("deaths wall=" & Integer'Image (Wall_N)
      & " self=" & Integer'Image (Self_N)
      & " trapped=" & Integer'Image (Trap_N)
      & " capped=" & Integer'Image (Caps));
end Batch;
