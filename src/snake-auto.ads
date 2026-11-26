package Snake.Auto is

   procedure Choose (W : in out World)
     with Pre => W.Alive and then W.Length >= 1;
   --  Sets W.Pending to the legal heading with the highest move fitness.
   --  Uses only what a player can see. The behaviour seed breaks ties only.

end Snake.Auto;
