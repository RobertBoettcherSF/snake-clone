with Interfaces;
with Snake.Api;
with System.Storage_Elements;

procedure Last_Chance_Handler
  (Source_Location : System.Address;
   Line            : Integer)
is
   use type System.Address;
   use type Interfaces.Unsigned_8;
   use System.Storage_Elements;
   Text : String (1 .. 240);
   N    : Natural := 0;
   Addr : System.Address := Source_Location;
begin
   if Source_Location /= System.Null_Address then
      loop
         exit when N = Text'Last;
         declare
            Item : Interfaces.Unsigned_8;
            for Item'Address use Addr;
            pragma Import (Ada, Item);
         begin
            exit when Item = 0;
            N := N + 1;
            Text (N) := Character'Val (Natural (Item));
         end;
         Addr := Addr + 1;
      end loop;
   end if;
   if N = 0 then
      Snake.Api.Store_Error (Line, "last-chance");
   else
      Snake.Api.Store_Error (Line, Text (1 .. N));
   end if;
   --  AdaWebPack cannot raise after a failed check. Spin so a trap is obvious.
   loop
      null;
   end loop;
end Last_Chance_Handler;
