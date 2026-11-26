package Snake.Auto is

   procedure Choose (W : in out World)
     with Pre => W.Alive and then W.Length >= 1;
   --  Sets W.Pending using only what a player can see.
   --  A move is taken only if the new head can still reach the new tail
   --  (BFS). Food is taken only when a virtual run of the shortest path
   --  stays tail-reachable after the eat; otherwise the snake follows
   --  its tail or the late zig-zag cycle. The behaviour seed breaks ties
   --  only. Score still beats turns; turns break ties.

end Snake.Auto;
