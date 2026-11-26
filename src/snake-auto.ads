package Snake.Auto is

   procedure Choose (W : in out World)
     with Pre => W.Alive and then W.Length >= 1;
   --  Sets W.Pending using only what a player can see.
   --  A move is taken only if the new head can still reach the new tail
   --  (BFS), except a last-pellet eat that fills the board (a win).
   --  On-cycle play stays in the forward gap of the 252-cell near-cycle;
   --  the omitted cell is taken by a tail-safe one-off when the head is
   --  adjacent. The behaviour seed breaks ties only. Score beats turns.

   function On_Cycle (P : Position) return Boolean;
   --  True if P is one of the 252 cells of the near-cycle (not Omitted_Cell).

   function Cycle_Index (P : Position) return Integer
     with Pre => On_Cycle (P);
   --  0 .. Cycle_Cells-1, in cycle order.

   function Cycle_Next (P : Position) return Direction
     with Pre => On_Cycle (P);

end Snake.Auto;
