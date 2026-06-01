with Board;
with Usart_Types;
with Spi_Types;
with Nor_Flash_Types;
with Nor_Flash_Dev;
with Debug;
with System.Storage_Elements; use System.Storage_Elements;

procedure Nor_Flash_0 is

   Dev : Nor_Flash_Dev.Device := Nor_Flash_Dev.Make_Device;

   SECTOR_0    : constant Nor_Flash_Types.Sector_Index := 0;
   PAGE_0_ADDR : constant Nor_Flash_Types.Nor_Address  := 0;
   PAGE_SIZE   : constant Storage_Offset               := 256;

   Write_Buf : Storage_Array (1 .. PAGE_SIZE);
   Read_Buf  : Storage_Array (1 .. PAGE_SIZE);

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
       Frequency => Spi_Types.F_1M));

   Debug.Put_Line ("NOR flash smoke test");

   Debug.Put ("Init... ");
   Nor_Flash_Dev.Flash.Open (Dev);
   Debug.Put_Line ("OK");

   Debug.Put ("Erase sector 0... ");
   Nor_Flash_Dev.Flash.Erase_Sector (Dev, SECTOR_0);
   Debug.Put_Line ("OK");

   for I in Write_Buf'Range loop
      Write_Buf (I) := Storage_Element ((I - 1) mod 256);
   end loop;

   Debug.Put ("Write page 0... ");
   Nor_Flash_Dev.Flash.Write_Page (Dev, PAGE_0_ADDR, Write_Buf);
   Debug.Put_Line ("OK");

   Debug.Put ("Read page 0... ");
   Nor_Flash_Dev.Flash.Read (Dev, PAGE_0_ADDR, Read_Buf);
   Debug.Put_Line ("OK");

   Debug.Put ("Verify... ");
   for I in Write_Buf'Range loop
      if Read_Buf (I) /= Write_Buf (I) then
         Debug.Put_Line ("FAIL at byte " & Debug.Img (Integer (I)));
         Nor_Flash_Dev.Flash.Close (Dev);
         return;
      end if;
      -- Debug.Put_Line (Debug.Img (Integer (I)));
   end loop;
   Debug.Put_Line ("OK");

   Nor_Flash_Dev.Flash.Close (Dev);
   Debug.Put_Line ("Done.");

   loop
      delay 1.0;
   end loop;

end Nor_Flash_0;