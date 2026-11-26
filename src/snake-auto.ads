package Snake.Auto is

   --  When Length is at most Early_Direct_Length, a tail-safe shortest
   --  path that stays in the forward gap (and does not skip the
   --  pellet) is always preferred. Between that and Direct_Blend_Length
   --  the path is taken only if the cycle way is at least twice as
   --  long. Above the blend end, play stays on the 252-cycle. Values
   --  were confirmed on the 100-seed batch (100/100 wins).
   Early_Direct_Length : constant := 60;
   Direct_Blend_Length : constant := 120;


   procedure Choose (W : in out World)
     with Pre => W.Alive and then W.Length >= 1;
   --  Sets W.Pending using only what a player can see.
   --  A move is taken only if the new head can still reach the new tail
   --  (BFS), except a last-pellet eat that fills the board (a win).
   --  On-cycle play stays in the forward gap of the 252-cell near-cycle;
   --  the omitted cell is taken by a tail-safe one-off when the head is
   --  adjacent. While the snake is short, a shortest path that stays
   --  in the forward gap is taken if a virtual run stays tail-safe.
   --  The behaviour seed breaks ties only. Score beats turns.

   function On_Cycle (P : Position) return Boolean;
   --  True if P is one of the 252 cells of the near-cycle (not Omitted_Cell).

   function Cycle_Index (P : Position) return Integer
     with Pre => On_Cycle (P);
   --  0 .. Cycle_Cells-1, in cycle order.

   function Cycle_Next (P : Position) return Direction
     with Pre => On_Cycle (P);

end Snake.Auto;
