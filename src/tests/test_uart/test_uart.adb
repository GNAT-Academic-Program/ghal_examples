with Board;
with Debug;
with Ada.Real_Time; use Ada.Real_Time;

procedure Test_UART is
   Count : Natural := 0;
begin
   Board.Initialize;
   loop
      Debug.Put_Line
        ("Hello! count=" & Count'Image);
      Count := Count + 1;
      delay until Clock + Seconds (1);
   end loop;
end Test_UART;