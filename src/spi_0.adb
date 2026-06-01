with Board;
with Gpio;
with Usart_Types;
with Spi_Types;
with Debug;

with System.Storage_Elements;

procedure SPI_0 is
   use System.Storage_Elements;

   --  JEDEC ID command
   CMD   : constant Storage_Array (1 .. 1) := (1 => 16#9F#);
   JEDEC : Storage_Array (1 .. 3) := (others => 0);

begin
   Board.Initialize;

   Board.Console.Open
     (Board.CONSOLE_DEV,
      (Baud      => Usart_Types.B115200,
       Data_Bits => Usart_Types.Data_8,
       Parity    => Usart_Types.None,
       Stop_Bits => Usart_Types.Stop_1,
       Flow      => Usart_Types.None));

   Board.Spi_1.Open
     (Board.Spi_1_DEV,
      (Mode      => Spi_Types.Mode_0,
       Data_Size => Spi_Types.Data_8,
       Bit_Order => Spi_Types.MSB_First,
       Frequency => Spi_Types.F_100K));

   Gpio.Clr (Board.Spi_1_CS);
   Board.Spi_1.Write (Board.Spi_1_DEV, CMD);
   Board.Spi_1.Read  (Board.Spi_1_DEV, JEDEC);
   Gpio.Set (Board.Spi_1_CS);

   Debug.Put ("JEDEC:");
   for B of JEDEC loop
      Debug.Put (" " & Debug.Hex (Integer (B)));
   end loop;
   Debug.Put_Line ("");

   loop
      delay 1.0;
   end loop;

end SPI_0;
