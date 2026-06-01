package body W25Q128_Dev is

   procedure Spi_Write
     (Dev : in out Board.Spi_1.Device;
      Buf : Storage_Array)
   is
   begin
      Board.Spi_1.Write (Dev, Buf);
   end Spi_Write;

   procedure Spi_Read
     (Dev : in out Board.Spi_1.Device;
      Buf : out Storage_Array)
   is
   begin
      Board.Spi_1.Read (Dev, Buf);
   end Spi_Read;

end W25Q128_Dev;