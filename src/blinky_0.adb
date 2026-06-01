with Board;
with Gpio;

procedure Blinky_0 is
begin
   Board.Initialize;
   loop
      Gpio.Toggle (Board.LED);
      delay 1.0;
   end loop;
end Blinky_0;