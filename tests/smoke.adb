with Ada.Text_IO;
with Snake;
with Snake.Auto;

procedure Smoke is
   use Snake;
   use Ada.Text_IO;
   Failed : Integer := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if Cond then
         Put_Line ("ok  " & Name);
      else
         Failed := Failed + 1;
         Put_Line ("FAIL " & Name);
      end if;
   end Check;

   W, A, B : World;
   Valid   : Boolean;
   P       : Position;
begin
   Init (W, 1, 2, 0, 0, 0);
   Check (W.Length = Start_Length, "init length");
   Check (W.Score = 0, "init score");
   Check (W.Turns = 0, "init turns");
   Check (W.Alive, "init alive");
   Check (Head (W).X = 10 and then Head (W).Y = 10, "init head");

   --  Wall death: drive into the right wall from mid-row.
   Init (W, 1, 2, 0, 0, 0);
   Set_Pending (W, Right);
   for I in 1 .. Grid_Size loop
      exit when not W.Alive;
      Step (W);
   end loop;
   Check (not W.Alive, "wall death");
   Check (W.Last_Event = Died, "wall event");
   Check (W.Turns > 0, "wall costs a turn");

   --  Eat: place the snake so the cell ahead is the food, then step.
   Init (W, 1, 2, 0, 0, 0);
   W.Food := Ahead (Head (W), W.Dir, Valid);
   Check (Valid, "food ahead is on the grid");
   declare
      Old_Len : constant Length_Count := W.Length;
   begin
      Step (W);
      Check (W.Alive, "eat keeps the snake alive");
      Check (W.Length = Old_Len + 1, "eat grows length by 1");
      Check (W.Score = Points_Per_Food, "eat scores 10");
      Check (W.Pellets = 1, "one pellet counted");
      Check (W.Last_Event = Ate or else W.Last_Event = Won, "eat event");
      Check (W.Best_Score = Points_Per_Food, "best score follows");
      Check (W.Best_Turns = W.Turns, "best turns set for that score");
      Check (W.Best_Length = W.Length, "best length follows");
   end;

   --  Same score in fewer turns improves best turns.
   Init (W, 3, 4, Points_Per_Food, 20, Start_Length + 1);
   W.Food := Ahead (Head (W), W.Dir, Valid);
   Step (W);
   Check (W.Score = Points_Per_Food, "tied score");
   Check (W.Turns < 20, "this run used fewer turns");
   Check (W.Best_Turns = W.Turns, "fewer turns improve the best");

   --  A lower score must not overwrite a higher best.
   Init (W, 3, 4, 50, 10, 8);
   W.Food := Ahead (Head (W), W.Dir, Valid);
   Step (W);
   Check (W.Best_Score = 50, "lower score keeps the best score");
   Check (W.Best_Turns = 10, "lower score keeps the best turns");

   --  Self-collision: go right, down, left, then up into the body.
   Init (W, 1, 2, 0, 0, 0);
   W.Length := 5;
   W.Segments (1) := (10, 10);
   W.Segments (2) := (9, 10);
   W.Segments (3) := (8, 10);
   W.Segments (4) := (7, 10);
   W.Segments (5) := (6, 10);
   W.Dir := Right;
   W.Pending := Right;
   Set_Pending (W, Down);
   Step (W);
   Check (W.Alive, "first fold still alive");
   Set_Pending (W, Left);
   Step (W);
   Check (W.Alive, "second fold still alive");
   Set_Pending (W, Up);
   Step (W);
   Check (not W.Alive, "self collision");
   Check (W.Last_Event = Died, "self event");

   --  Fitness formula.
   Check (Fitness_Of (20, 7) = 20 * Fitness_Scale - 7, "fitness formula");

   --  Determinism: same seeds, same auto run, same hash.
   Init (A, 11, 22, 0, 0, 0);
   Init (B, 11, 22, 0, 0, 0);
   Set_Auto (A, True);
   Set_Auto (B, True);
   for I in 1 .. 200 loop
      exit when not A.Alive;
      Snake.Auto.Choose (A);
      Note_Action (A, A.Pending, True);
      Step (A);
      Snake.Auto.Choose (B);
      Note_Action (B, B.Pending, True);
      Step (B);
   end loop;
   Check (A.Hash = B.Hash, "same seeds same hash");
   Check (A.Score = B.Score, "same seeds same score");
   Check (A.Turns = B.Turns, "same seeds same turns");
   Check (A.Log_Count = B.Log_Count, "same seeds same log length");
   Check (A.Food.X = B.Food.X and then A.Food.Y = B.Food.Y,
          "same seeds same pellet");

   --  A different pellet seed changes the food stream (and usually the hash).
   Init (A, 11, 22, 0, 0, 0);
   Init (B, 99, 22, 0, 0, 0);
   Check
     (A.Food.X /= B.Food.X or else A.Food.Y /= B.Food.Y,
      "different pellet seeds place food differently");

   --  Auto never queues a reverse heading.
   Init (W, 5, 6, 0, 0, 0);
   Set_Auto (W, True);
   declare
      Reversed : Boolean := False;
   begin
      for I in 1 .. 80 loop
         exit when not W.Alive;
         declare
            Before : constant Direction := W.Dir;
         begin
            Snake.Auto.Choose (W);
            if W.Pending = Opposite (Before) then
               Reversed := True;
            end if;
            Note_Action (W, W.Pending, True);
            Step (W);
         end;
      end loop;
      Check (not Reversed, "auto never reverses");
   end;

   --  Speed-up every 5 pellets.
   Init (W, 1, 2, 0, 0, 0);
   Check (Interval_Ms (W) = Base_Interval, "base interval");
   W.Pellets := 5;
   Check (Interval_Ms (W) = Base_Interval - Interval_Step, "interval after 5");
   W.Pellets := 50;
   Check (Interval_Ms (W) = Min_Interval, "interval floor");

   --  Occupancy: moving into the current tail (which vacates) is legal.
   Init (W, 1, 2, 0, 0, 0);
   P := W.Segments (W.Length);
   Check (Occupies (W, P, Ignore_Tail => False), "tail is occupied");
   Check (not Occupies (W, P, Ignore_Tail => True), "vacating tail is free");

   --  v0.2: seeds 1/1 must beat the v0.1 death score of 570, and must
   --  finish (win or die) rather than livelock in a late stall.
   Init (W, 1, 1, 0, 0, 0);
   Set_Auto (W, True);
   declare
      Guard     : Integer := 0;
      Max_Guard : constant := 100_000;
   begin
      while W.Alive and then not W.Won and then Guard < Max_Guard loop
         Snake.Auto.Choose (W);
         Note_Action (W, W.Pending, True);
         Step (W);
         Guard := Guard + 1;
      end loop;
      Check (W.Score > 570, "seeds 1/1 score beats 570");
      Check (Guard < Max_Guard, "seeds 1/1 terminates");
   end;

   if Failed = 0 then
      Put_Line ("All smoke checks passed.");
   else
      Put_Line (Integer'Image (Failed) & " smoke checks failed.");
   end if;
   if Failed /= 0 then
      raise Program_Error with "smoke failed";
   end if;
end Smoke;
