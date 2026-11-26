-- Game core. No heap, no tasking, no Text_IO, no hidden world state.
-- Pass World and both RNG states in; SPARK can be added after a freeze.

package Snake is
   Grid_Size       : constant := 20;
   Start_Length    : constant := 3;
   Points_Per_Food : constant := 10;
   Base_Interval   : constant := 150;
   Interval_Step   : constant := 15;
   Min_Interval    : constant := 50;
   Food_Per_Speed  : constant := 5;
   Max_Log         : constant := 4096;
   Fitness_Scale   : constant := 100_000;

   subtype Cell_Coord is Integer range 1 .. Grid_Size;
   subtype Length_Count is Integer range 0 .. Grid_Size * Grid_Size;
   subtype Score_Value is Integer range 0 .. Points_Per_Food * Grid_Size * Grid_Size;
   subtype Turn_Count is Integer range 0 .. 1_000_000;
   subtype Seed_Value is Integer range 0 .. 2_147_483_647;
   subtype Log_Index is Integer range 0 .. Max_Log;
   subtype Log_Slot is Integer range 1 .. Max_Log;

   type Direction is (Up, Right, Down, Left);
   subtype Dir_Code is Integer range 1 .. 4;

   type Cell_Kind is (Empty, Body_Cell, Head_Cell, Pellet);

   type Position is record
      X : Cell_Coord := 1;
      Y : Cell_Coord := 1;
   end record;

   type Body_Array is array (1 .. Grid_Size * Grid_Size) of Position;
   type Log_Array is array (Log_Slot) of Integer;

   type Rng_State is record
      State : Integer := 1;
   end record;

   type Event_Kind is (None, Moved, Ate, Died, Won);

   type World is record
      Segments        : Body_Array := [others => (1, 1)];
      Length          : Length_Count := Start_Length;
      Food            : Position := (1, 1);
      Dir             : Direction := Right;
      Pending         : Direction := Right;
      Score           : Score_Value := 0;
      Turns           : Turn_Count := 0;
      Pellets         : Length_Count := 0;
      Best_Score      : Score_Value := 0;
      Best_Turns      : Turn_Count := 0;
      Best_Length     : Length_Count := 0;
      Pellet_Seed     : Seed_Value := 1;
      Behaviour_Seed  : Seed_Value := 1;
      Pellet_Rng      : Rng_State := (State => 1);
      Behaviour_Rng   : Rng_State := (State => 1);
      Alive           : Boolean := True;
      Won             : Boolean := False;
      Paused          : Boolean := False;
      Auto_On         : Boolean := False;
      Log             : Log_Array := [others => 0];
      Log_Count       : Log_Index := 0;
      Hash            : Integer := 0;
      Last_Event      : Event_Kind := None;
   end record;

   procedure Seed_Rng (R : out Rng_State; Seed : Seed_Value);
   function Next_Random (R : in out Rng_State; Limit : Integer) return Integer
     with Pre => Limit >= 1;

   function Opposite (D : Direction) return Direction;
   function Code_Of (D : Direction) return Dir_Code;
   function Dir_Of (Code : Dir_Code) return Direction;
   function Ahead (P : Position; D : Direction; Valid : out Boolean)
     return Position;

   function Head (W : World) return Position
     with Pre => W.Length >= 1;

   function Occupies
     (W : World; P : Position; Ignore_Tail : Boolean) return Boolean;

   function Cell (W : World; X, Y : Cell_Coord) return Cell_Kind;

   function Interval_Ms (W : World) return Integer
     with Post => Interval_Ms'Result >= Min_Interval;

   function Fitness_Of (Score : Score_Value; Turns : Turn_Count) return Integer;

   procedure Init
     (W               : out World;
      Pellet_Seed     : Seed_Value;
      Behaviour_Seed  : Seed_Value;
      Best_Score      : Score_Value;
      Best_Turns      : Turn_Count;
      Best_Length     : Length_Count)
     with Post =>
       W.Length = Start_Length
       and W.Alive
       and not W.Won
       and W.Score = 0
       and W.Turns = 0;

   procedure Set_Pending (W : in out World; D : Direction);
   procedure Set_Paused (W : in out World; Paused : Boolean);
   procedure Set_Auto (W : in out World; On : Boolean);

   procedure Step (W : in out World);
   --  One turn: apply the pending heading, move, eat or die. Auto choice
   --  is applied by the caller before Step (see Snake.Auto).

   procedure Note_Action (W : in out World; D : Direction; From_Auto : Boolean);
   procedure Refresh_Hash (W : in out World);
   procedure Refresh_Bests (W : in out World);

end Snake;
