--  Game core. No heap, no tasking, no Text_IO, no hidden world state.
--  Pass World and both RNG states in; SPARK can be added after a freeze.
--
--  The board is 23 wide by 11 high (253 cells). That was the intended
--  size from the start; v0.1/v0.2 shipped a 20x20 square by mistake.
--  See docs/HOW_WE_GOT_HERE.md and docs/ALGORITHM.md.

package Snake is
   Grid_Width      : constant := 23;
   Grid_Height     : constant := 11;
   Grid_Cells      : constant := Grid_Width * Grid_Height;  -- 253
   Cycle_Cells     : constant := Grid_Cells - 1;            -- 252
   Start_Length    : constant := 3;
   Points_Per_Food : constant := 10;
   Base_Interval   : constant := 150;
   Interval_Step   : constant := 15;
   Min_Interval    : constant := 50;
   Food_Per_Speed  : constant := 5;
   --  Fixed cap on the action log (no heap). 65536 holds a full 23x11
   --  fill even in the worst case (about 250 pellets x 252 cycle steps).
   --  If a run still overflows, later moves are dropped and
   --  Log_Truncated is set; the report records both the cap and the flag.
   Max_Log         : constant := 65_536;
   Fitness_Scale   : constant := 100_000;

   subtype Cell_X is Integer range 1 .. Grid_Width;
   subtype Cell_Y is Integer range 1 .. Grid_Height;
   subtype Length_Count is Integer range 0 .. Grid_Cells;
   subtype Score_Value is Integer range 0 .. Points_Per_Food * Grid_Cells;
   subtype Turn_Count is Integer range 0 .. 1_000_000;
   subtype Seed_Value is Integer range 0 .. 2_147_483_647;
   subtype Log_Index is Integer range 0 .. Max_Log;
   subtype Log_Slot is Integer range 1 .. Max_Log;

   type Direction is (Up, Right, Down, Left);
   subtype Dir_Code is Integer range 1 .. 4;

   type Cell_Kind is (Empty, Body_Cell, Head_Cell, Pellet);

   type Position is record
      X : Cell_X := 1;
      Y : Cell_Y := 1;
   end record;

   type Body_Array is array (1 .. Grid_Cells) of Position;
   type Log_Array is array (Log_Slot) of Integer;

   type Rng_State is record
      State : Integer := 1;
   end record;

   type Event_Kind is (None, Moved, Ate, Died, Won);
   type Death_Cause is (None, Wall, Self, Trapped);

   --  Opening snake: three consecutive cells of the 252-cycle, heading
   --  Down column 12 (an even column that the cycle traverses downward
   --  through rows 2..11). See docs/ALGORITHM.md.
   Start_Head : constant Position := (12, 6);
   Start_Neck : constant Position := (12, 5);
   Start_Tail : constant Position := (12, 4);
   Start_Dir  : constant Direction := Down;

   --  The one cell left off the near-cycle (x+y even, so the remaining
   --  252 cells are balanced and can form a cycle).
   Omitted_Cell : constant Position := (23, 1);

   type World is record
      Segments        : Body_Array := [others => (1, 1)];
      Length          : Length_Count := Start_Length;
      Food            : Position := (1, 1);
      Dir             : Direction := Start_Dir;
      Pending         : Direction := Start_Dir;
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
      Log_Truncated   : Boolean := False;
      Hash            : Integer := 0;
      Last_Event      : Event_Kind := None;
      Death_Reason    : Death_Cause := None;
      Enclosed_Area   : Integer := 0;
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

   function Immediate_Fatal (W : World; D : Direction) return Boolean;
   --  True if heading D hits a wall, the body, or is a reverse with length > 1.

   function Has_Escape (W : World) return Boolean;
   --  True if at least one heading is not Immediate_Fatal.

   function Reachable_Free (W : World) return Integer;
   --  Empty and pellet cells reachable from the head without crossing the body.

   function Cell (W : World; X : Cell_X; Y : Cell_Y) return Cell_Kind;

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
