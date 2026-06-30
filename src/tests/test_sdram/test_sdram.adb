with Board;
with Debug;
with Ada.Real_Time; use Ada.Real_Time;
with MT;            use MT;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with Interfaces; use Interfaces;

procedure Test_SDRAM is

   type UInt32_Array is array (Natural range <>) of UInt32;

   procedure Test_Pattern
     (Base    : System.Address;
      Length  : Natural;
      Pattern : UInt32;
      Label   : String)
   is
      Data : UInt32_Array (0 .. Length / 4 - 1)
        with Address => Base;
      Errors : Natural := 0;
   begin
      --  Write
      for I in Data'Range loop
         Data (I) := Pattern xor UInt32 (I);
      end loop;

      --  Read back
      for I in Data'Range loop
         if Data (I) /= (Pattern xor UInt32 (I)) then
            Errors := Errors + 1;
         end if;
      end loop;

      if Errors = 0 then
         Debug.Put_Line
           (Label & ": PASS (" & Length'Image & " bytes)");
      else
         Debug.Put_Line
           (Label & ": FAIL " & Errors'Image & " errors");
      end if;
   end Test_Pattern;

   Base   : constant System.Address := Board.SDRAM_1.Base_Address;
   Length : constant Natural        := Natural (Board.SDRAM_1.Buffer_Size);

begin
   Board.Initialize;

   Debug.Put_Line ("SDRAM test starting...");
   Debug.Put_Line
     ("Base: " & System.Storage_Elements.Integer_Address'Image
        (System.Storage_Elements.To_Integer (Base)));
   Debug.Put_Line ("Size: " & Length'Image & " bytes");

   Test_Pattern (Base, Length, 16#AAAAAAAA#, "Pattern AA");
   Test_Pattern (Base, Length, 16#55555555#, "Pattern 55");
   Test_Pattern (Base, Length, 16#DEADBEEF#, "Pattern DEADBEEF");
   Test_Pattern (Base, Length, 16#00000000#, "Pattern 00");
   Test_Pattern (Base, Length, 16#FFFFFFFF#, "Pattern FF");

   Debug.Put_Line ("SDRAM test complete.");

   loop
      delay until Clock + Seconds (5);
      Debug.Put_Line ("Still alive.");
   end loop;
end Test_SDRAM;