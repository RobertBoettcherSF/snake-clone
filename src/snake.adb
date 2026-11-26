with Interfaces;

package body Snake is
   use Interfaces;


   procedure Seed_Rng (R : out Rng_State; Seed : Seed_Value) is
   begin
      R.State := Seed;
   end Seed_Rng;

   function Next_Random (R : in out Rng_State; Limit : Integer) return Integer is
      S : Unsigned_32 := Unsigned_32 (R.State);
   begin
      S := S * 1_103_515_245 + 12_345;
      S := S and 16#7FFF_FFFF#;
      R.State := Integer (S);
      return Integer (S rem Unsigned_32 (Limit));
   end Next_Random;

   function Opposite (D : Direction) return Direction is
   begin
      case D is
         when Up    => return Down;
         when Down  => return Up;
         when Left  => return Right;
         when Right => return Left;
      end case;
   end Opposite;

   function Code_Of (D : Direction) return Dir_Code is
   begin
      case D is
         when Up    => return 1;
         when Right => return 2;
         when Down  => return 3;
         when Left  => return 4;
      end case;
   end Code_Of;

   function Dir_Of (Code : Dir_Code) return Direction is
   begin
      case Code is
         when 1 => return Up;
         when 2 => return Right;
         when 3 => return Down;
         when 4 => return Left;
      end case;
   end Dir_Of;

   function Ahead
     (P : Position; D : Direction; Valid : out Boolean) return Position
   is
      X : Integer := P.X;
      Y : Integer := P.Y;
   begin
      case D is
         when Up    => Y := Y - 1;
         when Down  => Y := Y + 1;
         when Left  => X := X - 1;
         when Right => X := X + 1;
      end case;
      if X < 1 or X > Grid_Size or Y < 1 or Y > Grid_Size then
         Valid := False;
         return P;
      end if;
      Valid := True;
      return (X => X, Y => Y);
   end Ahead;

   function Head (W : World) return Position is
   begin
      return W.Segments (1);
   end Head;

   function Occupies
     (W : World; P : Position; Ignore_Tail : Boolean) return Boolean
   is
      Last : Length_Count;
   begin
      if W.Length = 0 then
         return False;
      end if;
      if Ignore_Tail and then W.Length >= 1 then
         Last := W.Length - 1;
      else
         Last := W.Length;
      end if;
      for I in 1 .. Last loop
         if W.Segments (I).X = P.X and then W.Segments (I).Y = P.Y then
            return True;
         end if;
      end loop;
      return False;
   end Occupies;

   function Cell (W : World; X, Y : Cell_Coord) return Cell_Kind is
   begin
      if W.Food.X = X and then W.Food.Y = Y then
         return Pellet;
      end if;
      if W.Length >= 1
        and then W.Segments (1).X = X
        and then W.Segments (1).Y = Y
      then
         return Head_Cell;
      end if;
      for I in 2 .. W.Length loop
         if W.Segments (I).X = X and then W.Segments (I).Y = Y then
            return Body_Cell;
         end if;
      end loop;
      return Empty;
   end Cell;

   function Interval_Ms (W : World) return Integer is
      Levels : constant Integer := W.Pellets / Food_Per_Speed;
      Raw    : constant Integer := Base_Interval - Levels * Interval_Step;
   begin
      if Raw < Min_Interval then
         return Min_Interval;
      end if;
      return Raw;
   end Interval_Ms;

   function Fitness_Of (Score : Score_Value; Turns : Turn_Count) return Integer is
   begin
      return Score * Fitness_Scale - Turns;
   end Fitness_Of;

   procedure Place_Food (W : in out World) is
      Empty_Count : Integer := 0;
      Pick        : Integer;
      Seen        : Integer := 0;
   begin
      for Y in Cell_Coord loop
         for X in Cell_Coord loop
            if not Occupies (W, (X, Y), False) then
               Empty_Count := Empty_Count + 1;
            end if;
         end loop;
      end loop;
      if Empty_Count = 0 then
         W.Won := True;
         W.Alive := False;
         return;
      end if;
      Pick := Next_Random (W.Pellet_Rng, Empty_Count);
      for Y in Cell_Coord loop
         for X in Cell_Coord loop
            if not Occupies (W, (X, Y), False) then
               if Seen = Pick then
                  W.Food := (X, Y);
                  return;
               end if;
               Seen := Seen + 1;
            end if;
         end loop;
      end loop;
      --  Unreachable if Empty_Count and Pick are consistent.
      pragma Assert (False, "snake.adb: Place_Food ran out of empty cells");
      W.Won := True;
      W.Alive := False;
   end Place_Food;

   procedure Note_Action
     (W : in out World; D : Direction; From_Auto : Boolean)
   is
      Code : Integer := Integer (Code_Of (D));
   begin
      if From_Auto then
         Code := Code + 10;
      end if;
      if W.Log_Count < Max_Log then
         W.Log_Count := W.Log_Count + 1;
         W.Log (W.Log_Count) := Code;
      else
         for I in 1 .. Max_Log - 1 loop
            W.Log (I) := W.Log (I + 1);
         end loop;
         W.Log (Max_Log) := Code;
      end if;
   end Note_Action;

   procedure Mix (H : in out Unsigned_32; V : Integer) is
   begin
      H := (H xor Unsigned_32 (V)) * 16_777_619;
   end Mix;

   procedure Refresh_Hash (W : in out World) is
      H : Unsigned_32 := 16#811C_9DC5#;
   begin
      Mix (H, W.Length);
      Mix (H, W.Score);
      Mix (H, W.Turns);
      Mix (H, W.Pellets);
      Mix (H, W.Food.X);
      Mix (H, W.Food.Y);
      Mix (H, Code_Of (W.Dir));
      Mix (H, W.Pellet_Seed);
      Mix (H, W.Behaviour_Seed);
      Mix (H, W.Pellet_Rng.State);
      Mix (H, W.Behaviour_Rng.State);
      if W.Alive then
         Mix (H, 1);
      else
         Mix (H, 0);
      end if;
      if W.Won then
         Mix (H, 3);
      end if;
      for I in 1 .. W.Length loop
         Mix (H, W.Segments (I).X);
         Mix (H, W.Segments (I).Y);
      end loop;
      W.Hash := Integer (H and 16#7FFF_FFFF#);
   end Refresh_Hash;

   procedure Refresh_Bests (W : in out World) is
   begin
      if W.Score > W.Best_Score then
         W.Best_Score := W.Score;
         W.Best_Turns := W.Turns;
      elsif W.Score = W.Best_Score
        and then W.Score > 0
        and then (W.Best_Turns = 0 or else W.Turns < W.Best_Turns)
      then
         W.Best_Turns := W.Turns;
      end if;
      if W.Length > W.Best_Length then
         W.Best_Length := W.Length;
      end if;
   end Refresh_Bests;

   procedure Init
     (W               : out World;
      Pellet_Seed     : Seed_Value;
      Behaviour_Seed  : Seed_Value;
      Best_Score      : Score_Value;
      Best_Turns      : Turn_Count;
      Best_Length     : Length_Count)
   is
      Mid : constant Cell_Coord := 10;
   begin
      W :=
        (Segments       => [others => (1, 1)],
         Length         => Start_Length,
         Food           => (1, 1),
         Dir            => Right,
         Pending        => Right,
         Score          => 0,
         Turns          => 0,
         Pellets        => 0,
         Best_Score     => Best_Score,
         Best_Turns     => Best_Turns,
         Best_Length    => Best_Length,
         Pellet_Seed    => Pellet_Seed,
         Behaviour_Seed => Behaviour_Seed,
         Pellet_Rng     => (State => 1),
         Behaviour_Rng  => (State => 1),
         Alive          => True,
         Won            => False,
         Paused         => False,
         Auto_On        => False,
         Log            => [others => 0],
         Log_Count      => 0,
         Hash           => 0,
         Last_Event     => None);
      W.Segments (1) := (X => Mid, Y => Mid);
      W.Segments (2) := (X => Mid - 1, Y => Mid);
      W.Segments (3) := (X => Mid - 2, Y => Mid);
      Seed_Rng (W.Pellet_Rng, Pellet_Seed);
      Seed_Rng (W.Behaviour_Rng, Behaviour_Seed);
      Place_Food (W);
      if W.Best_Length < Start_Length then
         W.Best_Length := Start_Length;
      end if;
      Refresh_Hash (W);
   end Init;

   procedure Set_Pending (W : in out World; D : Direction) is
   begin
      if D /= Opposite (W.Dir) then
         W.Pending := D;
      end if;
   end Set_Pending;

   procedure Set_Paused (W : in out World; Paused : Boolean) is
   begin
      W.Paused := Paused;
   end Set_Paused;

   procedure Set_Auto (W : in out World; On : Boolean) is
   begin
      W.Auto_On := On;
   end Set_Auto;

   procedure Step (W : in out World) is
      Valid  : Boolean;
      Next_P : Position;
      Eating : Boolean;
   begin
      W.Last_Event := None;
      if not W.Alive or else W.Paused or else W.Won then
         return;
      end if;
      if W.Pending /= Opposite (W.Dir) then
         W.Dir := W.Pending;
      end if;
      Next_P := Ahead (W.Segments (1), W.Dir, Valid);
      if not Valid then
         W.Alive := False;
         W.Last_Event := Died;
         if W.Turns < Turn_Count'Last then
            W.Turns := W.Turns + 1;
         end if;
         Refresh_Bests (W);
         Refresh_Hash (W);
         return;
      end if;
      Eating := Next_P.X = W.Food.X and then Next_P.Y = W.Food.Y;
      if Occupies (W, Next_P, Ignore_Tail => not Eating) then
         W.Alive := False;
         W.Last_Event := Died;
         if W.Turns < Turn_Count'Last then
            W.Turns := W.Turns + 1;
         end if;
         Refresh_Bests (W);
         Refresh_Hash (W);
         return;
      end if;
      if not Eating then
         for I in reverse 2 .. W.Length loop
            W.Segments (I) := W.Segments (I - 1);
         end loop;
         W.Segments (1) := Next_P;
      else
         for I in reverse 1 .. W.Length loop
            W.Segments (I + 1) := W.Segments (I);
         end loop;
         W.Segments (1) := Next_P;
         W.Length := W.Length + 1;
         W.Pellets := W.Pellets + 1;
         if W.Score <= Score_Value'Last - Points_Per_Food then
            W.Score := W.Score + Points_Per_Food;
         end if;
      end if;
      if W.Turns < Turn_Count'Last then
         W.Turns := W.Turns + 1;
      end if;
      if Eating then
         Place_Food (W);
         if W.Won then
            W.Last_Event := Won;
         else
            W.Last_Event := Ate;
         end if;
      else
         W.Last_Event := Moved;
      end if;
      Refresh_Bests (W);
      Refresh_Hash (W);
   end Step;

end Snake;
