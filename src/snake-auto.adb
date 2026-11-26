package body Snake.Auto is

   subtype Path_Len is Integer range 0 .. Grid_Size * Grid_Size;
   type Occupied_Grid is array (Cell_Coord, Cell_Coord) of Boolean;
   type Dir_Flags is array (Direction) of Boolean;
   type Body_Store is array (1 .. Grid_Size * Grid_Size) of Position;
   type Dir_Path is array (1 .. Grid_Size * Grid_Size) of Direction;

   function Manhattan (A, B : Position) return Integer is
   begin
      return abs (Integer (A.X) - Integer (B.X))
        + abs (Integer (A.Y) - Integer (B.Y));
   end Manhattan;

   function Cycle_Index (P : Position) return Integer is
      Row_Base : Integer;
   begin
      --  Hamiltonian cycle on the even 20x20 grid that contains the
      --  opening arc (8,10)->(9,10)->(10,10) heading Right. Rows snake
      --  through columns 1..19; column 20 closes the loop upwards.
      --  400 cells is even, so a true cycle exists (a 252-cycle is not
      --  required). The auto-player stays on this cycle from turn one
      --  so the body remains a single arc into the endgame.
      if P.X = Grid_Size then
         return Grid_Size * Grid_Size - P.Y;
      end if;
      Row_Base := (P.Y - 1) * (Grid_Size - 1);
      if P.Y mod 2 = 1 then
         return Row_Base + (Grid_Size - 1 - P.X);
      else
         return Row_Base + (P.X - 1);
      end if;
   end Cycle_Index;

   function Cycle_Next (P : Position) return Direction is
   begin
      if P.X = Grid_Size then
         if P.Y = 1 then
            return Left;
         else
            return Up;
         end if;
      end if;
      if P.Y mod 2 = 1 then
         if P.X > 1 then
            return Left;
         else
            return Down;
         end if;
      else
         if P.X < Grid_Size - 1 then
            return Right;
         elsif P.Y = Grid_Size then
            return Right;
         else
            return Down;
         end if;
      end if;
   end Cycle_Next;

   function Forward_Dist (From, To : Position) return Integer is
      A : constant Integer := Cycle_Index (From);
      B : constant Integer := Cycle_Index (To);
      D : Integer := B - A;
   begin
      if D < 0 then
         D := D + Grid_Size * Grid_Size;
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
     (Segs : Body_Store;
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
     (Segs : Body_Store; Len : Length_Count) return Boolean
   is
      Visited : Occupied_Grid := [others => [others => False]];
      Queue   : array (1 .. Grid_Size * Grid_Size) of Position;
      Head_Q  : Integer := 1;
      Tail_Q  : Integer := 1;
      Cur, Nxt, Start, Goal : Position;
      Ok      : Boolean;
      Block_To : Length_Count;
   begin
      if Len < 1 then
         return False;
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
      New_Body  : out Body_Store;
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
      Segs   : Body_Store;
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

   procedure Apply_Step
     (Segs   : in out Body_Store;
      Len    : in out Length_Count;
      D      : Direction;
      Food   : Position;
      Ate    : out Boolean;
      Legal  : out Boolean)
   is
      Ok     : Boolean;
      Next_P : Position;
      Ignore : Boolean;
      Block  : Length_Count;
   begin
      Ate := False;
      Legal := False;
      Next_P := Ahead (Segs (1), D, Ok);
      if not Ok then
         return;
      end if;
      Ate := Next_P.X = Food.X and then Next_P.Y = Food.Y;
      if Ate then
         Block := Len;
      else
         Block := Len - 1;
      end if;
      if Body_Hits (Segs, Block, Next_P) then
         return;
      end if;
      if not Ate then
         for I in reverse 2 .. Len loop
            Segs (I) := Segs (I - 1);
         end loop;
         Segs (1) := Next_P;
      else
         for I in reverse 1 .. Len loop
            Segs (I + 1) := Segs (I);
         end loop;
         Segs (1) := Next_P;
         Len := Len + 1;
      end if;
      Legal := True;
   end Apply_Step;

   function Hole_Size
     (Segs : Body_Store; Len : Length_Count) return Integer
   is
      Visited : Occupied_Grid := [others => [others => False]];
      Queue   : array (1 .. Grid_Size * Grid_Size) of Position;
      Head_Q, Tail_Q, Reached, Total_Free : Integer := 0;
      Cur, Nxt : Position;
      Ok : Boolean;
      Block : Length_Count;
   begin
      if Len < 1 then
         return 0;
      end if;
      if Len = 1 then
         Block := 0;
      else
         Block := Len - 1;
      end if;
      Total_Free := Grid_Size * Grid_Size - Len;
      Head_Q := 1;
      Tail_Q := 2;
      Queue (1) := Segs (1);
      Visited (Segs (1).X, Segs (1).Y) := True;
      Reached := 0;
      while Head_Q < Tail_Q loop
         Cur := Queue (Head_Q);
         Head_Q := Head_Q + 1;
         for D in Direction loop
            Nxt := Ahead (Cur, D, Ok);
            if Ok and then not Visited (Nxt.X, Nxt.Y)
              and then not Body_Hits (Segs, Block, Nxt)
            then
               Visited (Nxt.X, Nxt.Y) := True;
               Queue (Tail_Q) := Nxt;
               Tail_Q := Tail_Q + 1;
               Reached := Reached + 1;
            end if;
         end loop;
      end loop;
      if Reached >= Total_Free then
         return 0;
      end if;
      return Total_Free - Reached;
   end Hole_Size;

   function Hug_Count
     (Segs : Body_Store; Len : Length_Count) return Integer
   is
      H   : constant Position := Segs (1);
      Nxt : Position;
      Ok  : Boolean;
      C   : Integer := 0;
      Block : Length_Count;
   begin
      if Len = 1 then
         Block := 0;
      else
         Block := Len - 1;
      end if;
      for D in Direction loop
         Nxt := Ahead (H, D, Ok);
         if not Ok or else Body_Hits (Segs, Block, Nxt) then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Hug_Count;

   function Shortest_To_Food
     (W : World; Path : out Dir_Path; Steps : out Path_Len) return Boolean
   is
      Visited : Occupied_Grid := [others => [others => False]];
      Queue   : array (1 .. Grid_Size * Grid_Size) of Position;
      Came    : array (Cell_Coord, Cell_Coord) of Direction :=
        [others => [others => Right]];
      Head_Q, Tail_Q : Integer := 1;
      Cur, Nxt, Start : Position;
      Ok : Boolean := False;
      I : Path_Len;

      Rev : Dir_Path;
   begin
      Steps := 0;
      Path := [others => Right];
      Start := W.Segments (1);
      if Start.X = W.Food.X and then Start.Y = W.Food.Y then
         return False;
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
               --  The current tail is walkable (it vacates unless this
               --  step is an eat, in which case the food cell is empty
               --  of body anyway). Occupies with Ignore_Tail True lets
               --  the first-step BFS through the vacating tail.
               if not Occupies (W, Nxt, Ignore_Tail => True) then
                  Visited (Nxt.X, Nxt.Y) := True;
                  Came (Nxt.X, Nxt.Y) := D;
                  if Nxt.X = W.Food.X and then Nxt.Y = W.Food.Y then
                     I := 0;
                     Cur := Nxt;
                     while Cur.X /= Start.X or else Cur.Y /= Start.Y loop
                        I := I + 1;
                        Rev (I) := Came (Cur.X, Cur.Y);
                        declare
                           Back : constant Direction := Opposite (Rev (I));
                           P    : Position;
                           V    : Boolean;
                        begin
                           P := Ahead (Cur, Back, V);
                           Cur := P;
                        end;
                     end loop;
                     Steps := I;
                     for K in 1 .. Steps loop
                        Path (K) := Rev (Steps - K + 1);
                     end loop;
                     return True;
                  end if;
                  Queue (Tail_Q) := Nxt;
                  Tail_Q := Tail_Q + 1;
               end if;
            end if;
         end loop;
      end loop;
      return False;
   end Shortest_To_Food;

   function Food_Path_Safe
     (W : World; First : out Direction) return Boolean
   is
      Path  : Dir_Path;
      Steps : Path_Len;
      Segs  : Body_Store;
      Len   : Length_Count;
      Ate, Legal : Boolean;
   begin
      First := W.Dir;
      if not Shortest_To_Food (W, Path, Steps) or else Steps < 1 then
         return False;
      end if;
      First := Path (1);
      if First = Opposite (W.Dir) then
         return False;
      end if;
      if not Is_Tail_Safe (W, First) then
         return False;
      end if;
      Segs := [others => (1, 1)];
      for I in 1 .. W.Length loop
         Segs (I) := W.Segments (I);
      end loop;
      Len := W.Length;
      for S in 1 .. Steps loop
         Apply_Step (Segs, Len, Path (S), W.Food, Ate, Legal);
         if not Legal then
            return False;
         end if;
         if Ate then
            return Can_Reach_Tail (Segs, Len);
         end if;
      end loop;
      return False;
   end Food_Path_Safe;

   function Stall_Score
     (W : World; D : Direction; Toward_Tail : Boolean) return Integer
   is
      Segs   : Body_Store;
      Len    : Length_Count;
      Eating : Boolean;
      Legal  : Boolean;
      Score  : Integer := 0;
      Next_P : Position;
   begin
      Imagine (W, D, Segs, Len, Eating, Legal);
      if not Legal then
         return Integer'First / 2;
      end if;
      Next_P := Segs (1);
      Score := Score + 4 * (Grid_Size * 2 - Manhattan (Next_P, Segs (Len)));
      if W.Length >= Cycle_Length then
         --  Stay on, or rejoin, the cycle. Tail-follow must not outrank
         --  this, or the snake loops in a pocket with the pellet off-arc.
         Score := Score + 1_000_000
           - 100 * Forward_Dist (W.Segments (1), Next_P);
         Score := Score + 20 * Hug_Count (Segs, Len);
         Score := Score - 200 * Hole_Size (Segs, Len);
      else
         if Toward_Tail then
            Score := Score + 8_000;
         end if;
         if W.Length >= Compact_Length then
            Score := Score + 200 * Hug_Count (Segs, Len);
            Score := Score - 500 * Hole_Size (Segs, Len);
         else
            Score := Score - 50 * Hole_Size (Segs, Len);
         end if;
      end if;
      --  A tiny stay-alive term; score/turns are decided by eating, not here.
      return Score;
   end Stall_Score;

   function First_Toward
     (W : World; Goal : Position; Found : out Boolean) return Direction
   is
      Visited : Occupied_Grid := [others => [others => False]];
      Queue   : array (1 .. Grid_Size * Grid_Size) of Position;
      Came    : array (Cell_Coord, Cell_Coord) of Direction :=
        [others => [others => Right]];
      Head_Q, Tail_Q : Integer := 1;
      Cur, Nxt, Start : Position;
      Ok : Boolean;
      Step_D, Back : Direction;
   begin
      Found := False;
      Start := W.Segments (1);
      if Start.X = Goal.X and then Start.Y = Goal.Y then
         return W.Dir;
      end if;
      Queue (1) := Start;
      Visited (Start.X, Start.Y) := True;
      Tail_Q := 2;
      while Head_Q < Tail_Q loop
         Cur := Queue (Head_Q);
         Head_Q := Head_Q + 1;
         for D in Direction loop
            Nxt := Ahead (Cur, D, Ok);
            if Ok and then not Visited (Nxt.X, Nxt.Y)
              and then (Nxt.X = Goal.X and then Nxt.Y = Goal.Y)
            then
               Came (Nxt.X, Nxt.Y) := D;
               Cur := Nxt;
               loop
                  Step_D := Came (Cur.X, Cur.Y);
                  Back := Opposite (Step_D);
                  declare
                     Prev : Position;
                     V    : Boolean;
                  begin
                     Prev := Ahead (Cur, Back, V);
                     if Prev.X = Start.X and then Prev.Y = Start.Y then
                        Found := True;
                        return Step_D;
                     end if;
                     Cur := Prev;
                  end;
               end loop;
            elsif Ok and then not Visited (Nxt.X, Nxt.Y)
              and then not Occupies (W, Nxt, Ignore_Tail => True)
            then
               Visited (Nxt.X, Nxt.Y) := True;
               Came (Nxt.X, Nxt.Y) := D;
               Queue (Tail_Q) := Nxt;
               Tail_Q := Tail_Q + 1;
            end if;
         end loop;
      end loop;
      return W.Dir;
   end First_Toward;

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

   procedure Choose (W : in out World) is
      Safe       : Dir_Flags := [others => False];
      Safe_Count : Integer := 0;
      Food_Dir   : Direction;
      Tail_Dir   : Direction;
      Toward     : Boolean := False;
      Cycle_D    : Direction;
      Best_D     : Direction := W.Dir;
      Best_S     : Integer := Integer'First;
      Score      : Integer;
      Tied       : Dir_Flags := [others => False];
      Tie_Count  : Integer := 0;
      Found      : Boolean;
      Head_P     : Position;
      Next_P     : Position;
      Ok         : Boolean;
      Eating     : Boolean;
      To_Food    : Integer;
      To_C       : Integer;
   begin
      for D in Direction loop
         if Is_Tail_Safe (W, D) then
            Safe (D) := True;
            Safe_Count := Safe_Count + 1;
         end if;
      end loop;

      --  1. Stay in the forward cycle gap from turn one. A shortcut is
      --     allowed only toward a pellet that itself sits in the gap
      --     (virtual safety: after the eat the tail is still ahead on
      --     the cycle). If the pellet is behind the tail, follow the
      --     cycle until a safe approach exists. Score still beats turns
      --     because a safe shortcut is taken when it is available.
      if W.Length >= 1 then
         Head_P := W.Segments (1);
         To_Food := Forward_Dist (Head_P, W.Food);
         To_C := Forward_Dist (Head_P, W.Segments (W.Length));
         --  To_C reused as To_Tail for the in-gap test of the pellet.
         Best_S := 0;
         Best_D := Cycle_Next (Head_P);
         Tied := [others => False];
         Tie_Count := 0;
         for D in Direction loop
            if Safe (D) then
               Next_P := Ahead (Head_P, D, Ok);
               if Ok then
                  Eating := Next_P.X = W.Food.X
                    and then Next_P.Y = W.Food.Y;
                  if In_Forward_Gap
                    (Head_P, Next_P, W.Segments (W.Length), Eating)
                  then
                     Score := Forward_Dist (Head_P, Next_P);
                     --  When the pellet is in the gap, prefer the
                     --  longest jump that does not skip it. When it is
                     --  not, take the smallest jump (the cycle itself)
                     --  so skipped cells behind the tail can re-enter.
                     if To_Food < To_C then
                        if Score <= To_Food then
                           Score := 10_000 * Score;
                        else
                           Score := 0;
                        end if;
                     else
                        Score := 10_000 - Score;
                     end if;
                     if W.Length >= Compact_Length and then Score > 0 then
                        --  Prefer tighter play once the board is a third
                        --  full; the 10_000 term still dominates.
                        if Eating then
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

      --  2. Recovery only: a virtual shortest path, and only when the
      --     tail is still reachable after the eat.
      if Food_Path_Safe (W, Food_Dir) and then Safe (Food_Dir) then
         W.Pending := Food_Dir;
         return;
      end if;

      if Safe_Count = 0 then
         --  No tail-safe heading. Step into a non-fatal cell and let
         --  the core record Trapped / Wall / Self.
         Best_S := Integer'First;
         Best_D := W.Dir;
         for D in Direction loop
            if not Immediate_Fatal (W, D) then
               Best_S := 1;
               Best_D := D;
            end if;
         end loop;
         W.Pending := Best_D;
         return;
      end if;

      --  3. Rejoin the zig-zag cycle when the next cell is tail-safe.
      Cycle_D := Cycle_Next (W.Segments (1));
      if Safe (Cycle_D) then
         W.Pending := Cycle_D;
         return;
      end if;

      --  4. Stall: follow the tail (and, from Compact_Length, hug walls
      --     or body and keep free space in one region). Prefer the cell
      --     soonest on the cycle so the body can become an arc again.
      Tail_Dir := First_Toward (W, W.Segments (W.Length), Found);
      Best_D := W.Dir;
      Best_S := Integer'First;
      Tied := [others => False];
      Tie_Count := 0;
      for D in Direction loop
         if Safe (D) then
            Toward := Found and then D = Tail_Dir;
            Score := Stall_Score (W, D, Toward);
            if Score > Best_S then
               Best_S := Score;
               Best_D := D;
               Tied := [others => False];
               Tied (D) := True;
               Tie_Count := 1;
            elsif Score = Best_S then
               Tied (D) := True;
               Tie_Count := Tie_Count + 1;
            end if;
         end if;
      end loop;
      Pick_Tied (W, Tied, Tie_Count, Best_D);
   end Choose;

end Snake.Auto;
