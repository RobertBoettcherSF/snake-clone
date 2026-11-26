with Interfaces;

package Snake.Api is

   subtype I32 is Interfaces.Integer_32;

   procedure Init
     (Pellet_Seed    : I32;
      Behaviour_Seed : I32;
      Best_Score     : I32;
      Best_Turns     : I32;
      Best_Length    : I32);
   pragma Export (C, Init, "sn_init");

   procedure Restart;
   pragma Export (C, Restart, "sn_restart");

   procedure Set_Seeds (Pellet_Seed, Behaviour_Seed : I32);
   pragma Export (C, Set_Seeds, "sn_set_seeds");

   procedure Act (Dir : I32);
   pragma Export (C, Act, "sn_act");

   procedure Set_Auto (On : I32);
   pragma Export (C, Set_Auto, "sn_set_auto");

   procedure Set_Paused (On : I32);
   pragma Export (C, Set_Paused, "sn_set_paused");

   function Tick return I32;
   pragma Export (C, Tick, "sn_tick");

   function Score return I32;
   pragma Export (C, Score, "sn_score");
   function Length return I32;
   pragma Export (C, Length, "sn_length");
   function Turns return I32;
   pragma Export (C, Turns, "sn_turns");
   function Best_Score return I32;
   pragma Export (C, Best_Score, "sn_best_score");
   function Best_Turns return I32;
   pragma Export (C, Best_Turns, "sn_best_turns");
   function Best_Length return I32;
   pragma Export (C, Best_Length, "sn_best_length");
   function Fitness return I32;
   pragma Export (C, Fitness, "sn_fitness");
   function Alive return I32;
   pragma Export (C, Alive, "sn_alive");
   function Won return I32;
   pragma Export (C, Won, "sn_won");
   function Auto_On return I32;
   pragma Export (C, Auto_On, "sn_auto");
   function Paused return I32;
   pragma Export (C, Paused, "sn_paused");
   function Pellet_Seed return I32;
   pragma Export (C, Pellet_Seed, "sn_pellet_seed");
   function Behaviour_Seed return I32;
   pragma Export (C, Behaviour_Seed, "sn_behaviour_seed");
   function Interval_Ms return I32;
   pragma Export (C, Interval_Ms, "sn_interval_ms");
   function Grid_Width_Value return I32;
   pragma Export (C, Grid_Width_Value, "sn_grid_width");
   function Grid_Height_Value return I32;
   pragma Export (C, Grid_Height_Value, "sn_grid_height");
   function Cell (X, Y : I32) return I32;
   pragma Export (C, Cell, "sn_cell");
   function Hash return I32;
   pragma Export (C, Hash, "sn_hash");
   function Log_Count return I32;
   pragma Export (C, Log_Count, "sn_log_count");
   function Log_Entry (Index : I32) return I32;
   pragma Export (C, Log_Entry, "sn_log_entry");
   function Log_Cap return I32;
   pragma Export (C, Log_Cap, "sn_log_cap");
   function Log_Truncated return I32;
   pragma Export (C, Log_Truncated, "sn_log_truncated");
   function Last_Event return I32;
   pragma Export (C, Last_Event, "sn_last_event");
   function Error_Line return I32;
   pragma Export (C, Error_Line, "sn_error_line");
   function Error_Length return I32;
   pragma Export (C, Error_Length, "sn_error_length");
   function Error_Char (Index : I32) return I32;
   pragma Export (C, Error_Char, "sn_error_char");
   function Death_Reason return I32;
   pragma Export (C, Death_Reason, "sn_death_reason");
   function Enclosed_Area return I32;
   pragma Export (C, Enclosed_Area, "sn_enclosed_area");

   --  Filled by the last-chance handler (wasm).
   procedure Store_Error (Line : Integer; Text : String);
   function Error_Line_Value return Integer;
   function Error_Length_Value return Integer;
   function Error_Char_Value (Index : Positive) return Integer;

end Snake.Api;
