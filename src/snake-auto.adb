package body Snake.Auto is

   type Occupied_Grid is array (Cell_X, Cell_Y) of Boolean;
   type Dir_Flags is array (Direction) of Boolean;

   function On_Cycle (P : Position) return Boolean is
   begin
      return P.X /= Omitted_Cell.X or else P.Y /= Omitted_Cell.Y;
   end On_Cycle;

   function Cycle_Index (P : Position) return Integer is
      Pair, Base : Integer;
   begin
      --  252-cycle on the 23x11 board, omitting (23,1). Row 1 runs
      --  (1,1)->(22,1); columns 22-23 then ladder through rows 2..11;
      --  columns 21..1 snake up and down rows 2..11 and close at (1,1).
      --  See docs/ALGORITHM.md.
      if P.Y = 1 then
         return P.X - 1;
      end if;
      if P.X >= 22 then
         Pair := (P.Y - 2) / 2;
         Base := 22 + 4 * Pair;
         if P.Y mod 2 = 0 then
            if P.X = 22 then
               return Base;
            else
               return Base + 1;
            end if;
         else
            if P.X = 23 then
               return Base + 2;
            else
               return Base + 3;
            end if;
         end if;
      end if;
      Base := 42 + (21 - P.X) * 10;
      if P.X mod 2 = 1 then
         return Base + (11 - P.Y);
      else
         return Base + (P.Y - 2);
      end if;
   end Cycle_Index;

   function Cycle_Next (P : Position) return Direction is
   begin
      if P.Y = 1 then
         if P.X < 22 then
            return Right;
         else
            return Down;
         end if;
      end if;
      if P.X >= 22 then
         if P.Y mod 2 = 0 then
            if P.X = 22 then
               return Right;
            else
               return Down;
            end if;
         else
            if P.X = 23 then
               return Left;
            elsif P.Y = Grid_Height then
               return Left;
            else
               return Down;
            end if;
         end if;
      end if;
      if P.X mod 2 = 1 then
         if P.Y > 2 then
            return Up;
         elsif P.X = 1 then
            return Up;
         else
            return Left;
         end if;
      else
         if P.Y < Grid_Height then
            return Down;
         else
            return Left;
         end if;
      end if;
   end Cycle_Next;

   function Forward_Dist (From, To : Position) return Integer is
      D : Integer := Cycle_Index (To) - Cycle_Index (From);
   begin
      if D < 0 then
         D := D + Cycle_Cells;
      end if;
      return D;
   end Forward_Dist;

   function In_Forward_Gap
     (Head_P, C, Tail_P : Position; Eating : Boolean) return Boolean
   is
      To_C : constant Integer := Forward_Dist (Head_P, C);
      To_T : constant Integer := Forward_Dist (Head_P, Tail_P);
   begin
      if To_C = 0 then
         return False;
      end if;
      if Eating then
         return To_C < To_T;
      else
         return To_C <= To_T;
      end if;
   end In_Forward_Gap;

   function Body_Hits
     (Segs : Body_Array;
      Last : Length_Count;
      P    : Position) return Boolean
   is
   begin
      for I in 1 .. Last loop
         if Segs (I).X = P.X and then Segs (I).Y = P.Y then
            return True;
         end if;
      end loop;
      return False;
   end Body_Hits;

   function Can_Reach_Tail
     (Segs : Body_Array; Len : Length_Count) return Boolean
   is
      Visited : Occupied_Grid := [others => [others => False]];
      Queue   : array (1 .. Grid_Cells) of Position;
      Head_Q  : Integer := 1;
      Tail_Q  : Integer := 1;
      Cur, Nxt, Start, Goal : Position;
      Ok      : Boolean;
      Block_To : Length_Count;
   begin
      if Len < 1 then
         return False;
      end if;
      if Len = Grid_Cells then
         --  The board is full: a just-eaten last pellet, which is a win.
         return True;
      end if;
      Start := Segs (1);
      Goal := Segs (Len);
      if Start.X = Goal.X and then Start.Y = Goal.Y then
         return True;
      end if;
      if Len = 1 then
         Block_To := 0;
      else
         Block_To := Len - 1;
      end if;
      Queue (1) := Start;
      Visited (Start.X, Start.Y) := True;
      Tail_Q := 2;
      while Head_Q < Tail_Q loop
         Cur := Queue (Head_Q);
         Head_Q := Head_Q + 1;
         for D in Direction loop
            Nxt := Ahead (Cur, D, Ok);
            if Ok and then not Visited (Nxt.X, Nxt.Y) then
               if Nxt.X = Goal.X and then Nxt.Y = Goal.Y then
                  return True;
               end if;
               if not Body_Hits (Segs, Block_To, Nxt) then
                  Visited (Nxt.X, Nxt.Y) := True;
                  Queue (Tail_Q) := Nxt;
                  Tail_Q := Tail_Q + 1;
               end if;
            end if;
         end loop;
      end loop;
      return False;
   end Can_Reach_Tail;

   procedure Imagine
     (W         : World;
      D         : Direction;
      New_Body  : out Body_Array;
      New_Len   : out Length_Count;
      Eating    : out Boolean;
      Legal     : out Boolean)
   is
      Ok     : Boolean;
      Next_P : Position;
   begin
      Legal := False;
      Eating := False;
      New_Len := W.Length;
      New_Body := [others => (1, 1)];
      if D = Opposite (W.Dir) then
         return;
      end if;
      Next_P := Ahead (W.Segments (1), D, Ok);
      if not Ok then
         return;
      end if;
      Eating := Next_P.X = W.Food.X and then Next_P.Y = W.Food.Y;
      if Occupies (W, Next_P, Ignore_Tail => not Eating) then
         return;
      end if;
      for I in 1 .. W.Length loop
         New_Body (I) := W.Segments (I);
      end loop;
      if not Eating then
         for I in reverse 2 .. W.Length loop
            New_Body (I) := New_Body (I - 1);
         end loop;
         New_Body (1) := Next_P;
         New_Len := W.Length;
      else
         for I in reverse 1 .. W.Length loop
            New_Body (I + 1) := New_Body (I);
         end loop;
         New_Body (1) := Next_P;
         New_Len := W.Length + 1;
      end if;
      Legal := True;
   end Imagine;

   function Is_Tail_Safe (W : World; D : Direction) return Boolean is
      Segs   : Body_Array;
      Len    : Length_Count;
      Eating : Boolean;
      Legal  : Boolean;
   begin
      Imagine (W, D, Segs, Len, Eating, Legal);
      if not Legal then
         return False;
      end if;
      return Can_Reach_Tail (Segs, Len);
   end Is_Tail_Safe;

   procedure Pick_Tied
     (W         : in out World;
      Tied      : Dir_Flags;
      Tie_Count : Integer;
      Fallback  : Direction)
   is
      Pick, Seen : Integer := 0;
   begin
      if Tie_Count <= 1 then
         W.Pending := Fallback;
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
      W.Pending := Fallback;
   end Pick_Tied;

   function Is_Omitted (P : Position) return Boolean is
   begin
      return P.X = Omitted_Cell.X and then P.Y = Omitted_Cell.Y;
   end Is_Omitted;

   procedure Choose (W : in out World) is
      Safe       : Dir_Flags := [others => False];
      Safe_Count : Integer := 0;
      Cycle_D    : Direction;
      Best_D     : Direction := W.Dir;
      Best_S     : Integer := 0;
      Score      : Integer;
      Tied       : Dir_Flags := [others => False];
      Tie_Count  : Integer := 0;
      Head_P     : Position;
      Next_P     : Position;
      Ok         : Boolean;
      Eating     : Boolean;
      To_Food    : Integer;
      To_Tail    : Integer;
      Food_On    : Boolean;
   begin
      for D in Direction loop
         if Is_Tail_Safe (W, D) then
            Safe (D) := True;
            Safe_Count := Safe_Count + 1;
         end if;
      end loop;

      Head_P := W.Segments (1);

      --  1. One-off onto the omitted cell when the head is adjacent
      --     and the step is tail-safe (always, when it is the last
      --     empty cell and the eat fills the board).
      if Is_Omitted (W.Food) then
         for D in Direction loop
            if Safe (D) then
               Next_P := Ahead (Head_P, D, Ok);
               if Ok
                 and then Next_P.X = Omitted_Cell.X
                 and then Next_P.Y = Omitted_Cell.Y
               then
                  --  Prefer arriving from (22,1) so the exit is (23,2),
                  --  forward on the cycle. If this is the last cell,
                  --  either neighbour is a win.
                  W.Pending := D;
                  return;
               end if;
            end if;
         end loop;
      end if;

      --  2. Head is off the cycle (just ate the omitted cell mid-game):
      --     step back onto a tail-safe cycle neighbour.
      if not On_Cycle (Head_P) then
         for D in Direction loop
            if Safe (D) then
               Next_P := Ahead (Head_P, D, Ok);
               if Ok and then On_Cycle (Next_P) then
                  W.Pending := D;
                  return;
               end if;
            end if;
         end loop;
      end if;

      --  3. Forward-gap shortcuts on the 252-cycle. When the pellet is
      --     in the gap, take the longest jump that does not skip it
      --     (fewer turns). When it is behind the tail, or is the
      --     omitted cell, follow the cycle itself until a safe approach
      --     exists. Score still beats turns.
      if On_Cycle (Head_P)
        and then On_Cycle (W.Segments (W.Length))
        and then W.Length >= 1
      then
         Food_On := On_Cycle (W.Food);
         if Food_On then
            To_Food := Forward_Dist (Head_P, W.Food);
         else
            To_Food := Cycle_Cells;
         end if;
         To_Tail := Forward_Dist (Head_P, W.Segments (W.Length));
         Best_S := 0;
         Best_D := Cycle_Next (Head_P);
         Tied := [others => False];
         Tie_Count := 0;
         for D in Direction loop
            if Safe (D) then
               Next_P := Ahead (Head_P, D, Ok);
               if Ok and then On_Cycle (Next_P) then
                  Eating := Next_P.X = W.Food.X
                    and then Next_P.Y = W.Food.Y;
                  if In_Forward_Gap
                    (Head_P, Next_P, W.Segments (W.Length), Eating)
                  then
                     Score := Forward_Dist (Head_P, Next_P);
                     if Food_On and then To_Food < To_Tail then
                        --  Strongest safe in-gap shortcut toward food.
                        if Score <= To_Food then
                           Score := 10_000 * Score;
                        else
                           Score := 0;
                        end if;
                     else
                        --  Food is behind or off-cycle: stay on the
                        --  cycle (smallest jump) so skipped cells
                        --  re-enter cleanly. Approaching a neighbour
                        --  of the omitted pellet is a small bonus.
                        if Score = 1 then
                           Score := 10_000;
                        else
                           Score := 0;
                        end if;
                        if not Food_On
                          and then ((Next_P.X = 22 and then Next_P.Y = 1)
                            or else (Next_P.X = 23 and then Next_P.Y = 2))
                        then
                           Score := Score + 50;
                        end if;
                     end if;
                     if Score > Best_S then
                        Best_S := Score;
                        Best_D := D;
                        Tied := [others => False];
                        Tied (D) := True;
                        Tie_Count := 1;
                     elsif Score = Best_S and then Score > 0 then
                        Tied (D) := True;
                        Tie_Count := Tie_Count + 1;
                     end if;
                  end if;
               end if;
            end if;
         end loop;
         if Best_S > 0 then
            Pick_Tied (W, Tied, Tie_Count, Best_D);
            return;
         end if;
      end if;

      --  4. Minimal fallback if no gap move was tail-safe.
      if On_Cycle (Head_P) then
         Cycle_D := Cycle_Next (Head_P);
         if Safe (Cycle_D) then
            W.Pending := Cycle_D;
            return;
         end if;
      end if;
      if Safe_Count > 0 then
         for D in Direction loop
            if Safe (D) then
               W.Pending := D;
               return;
            end if;
         end loop;
      end if;
      for D in Direction loop
         if not Immediate_Fatal (W, D) then
            W.Pending := D;
            return;
         end if;
      end loop;
      W.Pending := W.Dir;
   end Choose;

end Snake.Auto;
