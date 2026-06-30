--  Test_Button — Portable button test firmware for GHAL boards.
--  Tests button input by toggling LED and printing status to console.
--  Works on any board that implements Board.Button and Board.Led.

with Board;
with Debug;
with Gpio;
with Ada.Real_Time; use Ada.Real_Time;

procedure Test_Button is
   Last_Button_State : Boolean := False;
   Current_State     : Boolean := False;
   Press_Count       : Natural := 0;
   Led_State         : Boolean := False;
begin
   Board.Initialize;
   
   Debug.Put_Line ("===========================================");
   Debug.Put_Line ("  Button Test Firmware");
   Debug.Put_Line ("===========================================");
   Debug.Put_Line ("Press the user button to toggle the LED.");
   Debug.Put_Line ("Button presses are counted and logged.");
   Debug.Put_Line ("");

   loop
      --  Read current button state
      Current_State := Board.Button_Pressed;

      --  Detect rising edge (button press)
      if Current_State and then not Last_Button_State then
         --  Button was just pressed
         Press_Count := Press_Count + 1;
         
         --  Toggle LED
         Led_State := not Led_State;
         if Led_State then
            Gpio.Set (Board.Led);
         else
            Gpio.Clr (Board.Led);
         end if;

         --  Log the event
         Debug.Put_Line
           ("Button pressed! Count=" & Press_Count'Image &
            ", LED=" & (if Led_State then "ON" else "OFF"));
      end if;

      --  Update state for next iteration
      Last_Button_State := Current_State;

      --  Small delay to debounce and reduce CPU usage
      delay until Clock + Milliseconds (50);
   end loop;
end Test_Button;
