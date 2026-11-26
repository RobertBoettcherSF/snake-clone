with Snake.Auto;

package body Snake.Api is
   use type I32;

   The_World : World;

   Error_Line_Store : Integer := 0;
   Error_Text        : String (1 .. 240) := [others => ' '];
   Error_Len         : Integer := 0;

   procedure Store_Error (Line : Integer; Text : String) is
      N : Integer := Text'Length;
   begin
      Error_Line_Store := Line;
      if N > Error_Text'Length then
         N := Error_Text'Length;
      end if;
      Error_Len := N;
      if N > 0 then
         Error_Text (1 .. N) := Text (Text'First .. Text'First + N - 1);
      end if;
   end Store_Error;

   function Error_Line_Value return Integer is
   begin
      return Error_Line_Store;
   end Error_Line_Value;

   function Error_Length_Value return Integer is
   begin
      return Error_Len;
   end Error_Length_Value;

   function Error_Char_Value (Index : Positive) return Integer is
   begin
      if Index > Error_Len then
         return 0;
      end if;
      return Character'Pos (Error_Text (Index));
   end Error_Char_Value;

   function Clamp_Seed (V : I32) return Seed_Value is
   begin
      if V < 0 then
         return 0;
      end if;
      return Integer (V);
   end Clamp_Seed;

   function Clamp_Score (V : I32) return Score_Value is
   begin
      if Integer (V) < Score_Value'First then
         return Score_Value'First;
      elsif Integer (V) > Score_Value'Last then
         return Score_Value'Last;
      else
         return Integer (V);
      end if;
   end Clamp_Score;

   function Clamp_Turns (V : I32) return Turn_Count is
   begin
      if Integer (V) < Turn_Count'First then
         return Turn_Count'First;
      elsif Integer (V) > Turn_Count'Last then
         return Turn_Count'Last;
      else
         return Integer (V);
      end if;
   end Clamp_Turns;

   function Clamp_Length (V : I32) return Length_Count is
   begin
      if Integer (V) < Length_Count'First then
         return Length_Count'First;
      elsif Integer (V) > Length_Count'Last then
         return Length_Count'Last;
      else
         return Integer (V);
      end if;
   end Clamp_Length;

   procedure Init
     (Pellet_Seed    : I32;
      Behaviour_Seed : I32;
      Best_Score     : I32;
      Best_Turns     : I32;
      Best_Length    : I32)
   is
   begin
      Init
        (The_World,
         Clamp_Seed (Pellet_Seed),
         Clamp_Seed (Behaviour_Seed),
         Clamp_Score (Best_Score),
         Clamp_Turns (Best_Turns),
         Clamp_Length (Best_Length));
   end Init;

   procedure Restart is
   begin
      Init
        (The_World,
         The_World.Pellet_Seed,
         The_World.Behaviour_Seed,
         The_World.Best_Score,
         The_World.Best_Turns,
         The_World.Best_Length);
   end Restart;

   procedure Set_Seeds (Pellet_Seed, Behaviour_Seed : I32) is
      Auto : constant Boolean := The_World.Auto_On;
   begin
      Init
        (The_World,
         Clamp_Seed (Pellet_Seed),
         Clamp_Seed (Behaviour_Seed),
         The_World.Best_Score,
         The_World.Best_Turns,
         The_World.Best_Length);
      The_World.Auto_On := Auto;
   end Set_Seeds;

   procedure Act (Dir : I32) is
   begin
      if Integer (Dir) >= 1 and then Integer (Dir) <= 4 then
         Set_Pending (The_World, Dir_Of (Integer (Dir)));
      end if;
   end Act;

   procedure Set_Auto (On : I32) is
   begin
      Set_Auto (The_World, Integer (On) /= 0);
   end Set_Auto;

   procedure Set_Paused (On : I32) is
   begin
      Set_Paused (The_World, Integer (On) /= 0);
   end Set_Paused;

   function Tick return I32 is
   begin
      if The_World.Auto_On
        and then The_World.Alive
        and then not The_World.Paused
      then
         Snake.Auto.Choose (The_World);
         Note_Action (The_World, The_World.Pending, True);
      elsif The_World.Alive and then not The_World.Paused then
         Note_Action (The_World, The_World.Pending, False);
      end if;
      Step (The_World);
      case The_World.Last_Event is
         when None  => return 0;
         when Moved => return 1;
         when Ate   => return 2;
         when Died  => return 3;
         when Won   => return 4;
      end case;
   end Tick;

   function Score return I32 is
   begin
      return I32 (The_World.Score);
   end Score;

   function Length return I32 is
   begin
      return I32 (The_World.Length);
   end Length;

   function Turns return I32 is
   begin
      return I32 (The_World.Turns);
   end Turns;

   function Best_Score return I32 is
   begin
      return I32 (The_World.Best_Score);
   end Best_Score;

   function Best_Turns return I32 is
   begin
      return I32 (The_World.Best_Turns);
   end Best_Turns;

   function Best_Length return I32 is
   begin
      return I32 (The_World.Best_Length);
   end Best_Length;

   function Fitness return I32 is
   begin
      return I32 (Fitness_Of (The_World.Score, The_World.Turns));
   end Fitness;

   function Alive return I32 is
   begin
      if The_World.Alive then
         return 1;
      else
         return 0;
      end if;
   end Alive;

   function Won return I32 is
   begin
      if The_World.Won then
         return 1;
      else
         return 0;
      end if;
   end Won;

   function Auto_On return I32 is
   begin
      if The_World.Auto_On then
         return 1;
      else
         return 0;
      end if;
   end Auto_On;

   function Paused return I32 is
   begin
      if The_World.Paused then
         return 1;
      else
         return 0;
      end if;
   end Paused;

   function Pellet_Seed return I32 is
   begin
      return I32 (The_World.Pellet_Seed);
   end Pellet_Seed;

   function Behaviour_Seed return I32 is
   begin
      return I32 (The_World.Behaviour_Seed);
   end Behaviour_Seed;

   function Food_X return I32 is
   begin
      return I32 (The_World.Food.X);
   end Food_X;

   function Food_Y return I32 is
   begin
      return I32 (The_World.Food.Y);
   end Food_Y;

   function Dir_Code return I32 is
   begin
      return I32 (Code_Of (The_World.Dir));
   end Dir_Code;

   function Interval_Ms return I32 is
   begin
      return I32 (Interval_Ms (The_World));
   end Interval_Ms;

   function Grid return I32 is
   begin
      return I32 (Grid_Size);
   end Grid;

   function Cell (X, Y : I32) return I32 is
   begin
      if Integer (X) in Cell_Coord'Range and then Integer (Y) in Cell_Coord'Range
      then
         return I32 (Cell_Kind'Pos (Cell (The_World, Integer (X), Integer (Y))));
      end if;
      return 0;
   end Cell;

   function Hash return I32 is
   begin
      return I32 (The_World.Hash);
   end Hash;

   function Log_Count return I32 is
   begin
      return I32 (The_World.Log_Count);
   end Log_Count;

   function Log_Entry (Index : I32) return I32 is
   begin
      if Integer (Index) in 1 .. The_World.Log_Count then
         return I32 (The_World.Log (Integer (Index)));
      end if;
      return 0;
   end Log_Entry;

   function Last_Event return I32 is
   begin
      return I32 (Event_Kind'Pos (The_World.Last_Event));
   end Last_Event;

   function Error_Line return I32 is
   begin
      return I32 (Error_Line_Store);
   end Error_Line;

   function Error_Length return I32 is
   begin
      return I32 (Error_Len);
   end Error_Length;

   function Error_Char (Index : I32) return I32 is
   begin
      if Integer (Index) >= 1 and then Integer (Index) <= Error_Len then
         return I32 (Character'Pos (Error_Text (Integer (Index))));
      end if;
      return 0;
   end Error_Char;

end Snake.Api;
