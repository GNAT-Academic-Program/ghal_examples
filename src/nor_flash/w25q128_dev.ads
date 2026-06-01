with W25Q128_Spi;
with Gpio;
with Board;
with System.Storage_Elements; use System.Storage_Elements;

package W25Q128_Dev is

   procedure Spi_Write
     (Dev : in out Board.Spi_1.Device;
      Buf :        Storage_Array);

   procedure Spi_Read
     (Dev : in out Board.Spi_1.Device;
      Buf :    out Storage_Array);

   package Chip is new W25Q128_Spi
     (Spi_Device      => Board.Spi_1.Device,
      Gpio_Pin        => Gpio.Pin,
      Spi_Write_Bytes => Spi_Write,
      Spi_Read_Bytes  => Spi_Read,
      Pin_Set         => Gpio.Set,
      Pin_Clear       => Gpio.Clr);

   subtype Device is Chip.Device;

   function Make_Device
     (Spi : access Board.Spi_1.Device;
      CS  : Gpio.Pin) return Device
     renames Chip.Make_Device;

end W25Q128_Dev;