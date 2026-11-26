package body Snake.Auto is

   function Manhattan (A, B : Position) return Integer is
      DX : constant Integer := abs (Integer (A.X) - Integer (B.X));
      DY : constant Integer := abs (Integer (A.Y) - Integer (B.Y));
   begin
      return DX + DY;
   end Manhattan;

   function Free_Space
     (W : World; Start : Position; Ignore_Tail : Boolean) return Integer
   is
      Visited : array (Cell_Coord, Cell_Coord) of Boolean :=
        [others => [others => False]];
      Queue   : array (1 .. Grid_Size * Grid_Size) of Position;
      Head_Q  : Integer := 1;
      Tail_Q  : Integer := 1;
      Count   : Integer := 0;
      Cur     : Position;
      Nxt     : Position;
      Ok      : Boolean;
   begin
      if Occupies (W, Start, Ignore_Tail) then
         return 0;
      end if;
      Queue (1) := Start;
      Visited (Start.X, Start.Y) := True;
      Tail_Q := 2;
      Count := 1;
      while Head_Q < Tail_Q loop
         Cur := Queue (Head_Q);
         Head_Q := Head_Q + 1;
         for D in Direction loop
            Nxt := Ahead (Cur, D, Ok);
            if Ok
              and then not Visited (Nxt.X, Nxt.Y)
              and then not Occupies (W, Nxt, Ignore_Tail)
            then
               Visited (Nxt.X, Nxt.Y) := True;
               Queue (Tail_Q) := Nxt;
               Tail_Q := Tail_Q + 1;
               Count := Count + 1;
            end if;
         end loop;
      end loop;
      return Count;
   end Free_Space;

   function Move_Score
     (W : World; D : Direction; Legal : out Boolean) return Integer
   is
      Ok          : Boolean;
      Next_P      : Position;
      Eating      : Boolean;
      Ignore_Tail : Boolean;
      Space       : Integer;
      After_Len   : Integer;
      Dist        : Integer;
      Score       : Integer := 0;
   begin
      Legal := False;
      if D = Opposite (W.Dir) then
         return -1_000_000_000;
      end if;
      Next_P := Ahead (W.Segments (1), D, Ok);
      if not Ok then
         return -1_000_000_000;
      end if;
      Eating := Next_P.X = W.Food.X and then Next_P.Y = W.Food.Y;
      Ignore_Tail := not Eating;
      if Occupies (W, Next_P, Ignore_Tail) then
         return -1_000_000_000;
      end if;
      Legal := True;
      if Eating then
         Score := Score + 1_000_000;
         After_Len := W.Length + 1;
         Dist := 0;
      else
         After_Len := W.Length;
         Dist := Manhattan (Next_P, W.Food);
      end if;
      Space := Free_Space (W, Next_P, Ignore_Tail);
      if Space >= After_Len then
         Score := Score + 10_000;
      end if;
      if Space > 1_000 then
         Score := Score + 1_000;
      else
         Score := Score + Space;
      end if;
      Score := Score + 100 * (2 * Grid_Size - Dist);
      return Score;
   end Move_Score;

   procedure Choose (W : in out World) is
      Best_Score : Integer := Integer'First;
      Best_Dir   : Direction := W.Dir;
      Tied       : array (Direction) of Boolean := [others => False];
      Tie_Count  : Integer := 0;
      Score      : Integer;
      Legal      : Boolean;
      Any        : Boolean := False;
      Pick       : Integer;
      Seen       : Integer := 0;
   begin
      for D in Direction loop
         Score := Move_Score (W, D, Legal);
         if Legal then
            Any := True;
            if Score > Best_Score then
               Best_Score := Score;
               Best_Dir := D;
               Tied := [others => False];
               Tied (D) := True;
               Tie_Count := 1;
            elsif Score = Best_Score then
               Tied (D) := True;
               Tie_Count := Tie_Count + 1;
            end if;
         end if;
      end loop;
      if not Any then
         --  No safe heading; keep the current one and let Step record the death.
         W.Pending := W.Dir;
         return;
      end if;
      if Tie_Count <= 1 then
         W.Pending := Best_Dir;
         return;
      end if;
      Pick := Next_Random (W.Behaviour_Rng, Tie_Count);
      for D in Direction loop
         if Tied (D) then
            if Seen = Pick then
               W.Pending := D;
               return;
            end if;
            Seen := Seen + 1;
         end if;
      end loop;
      W.Pending := Best_Dir;
   end Choose;

end Snake.Auto;
