with Nor_Flash_Interface;
with W25Q128_Dev;

package Nor_Flash_Dev is

   package Flash is new Nor_Flash_Interface
     (Device              => W25Q128_Dev.Device,
      Bus_Command         => W25Q128_Dev.Chip.Bus_Command,
      Bus_Command_Address => W25Q128_Dev.Chip.Bus_Command_Address,
      Bus_Read_Status     => W25Q128_Dev.Chip.Bus_Read_Status,
      Bus_Command_Read    => W25Q128_Dev.Chip.Bus_Command_Read,
      Bus_Write           => W25Q128_Dev.Chip.Bus_Write,
      Bus_Read            => W25Q128_Dev.Chip.Bus_Read,
      Driver_Config       => W25Q128_Dev.Chip.Expected_Config,
      Driver_Read_SR2     => W25Q128_Dev.Chip.Read_SR2,
      Driver_Write_Status => W25Q128_Dev.Chip.Write_Status);

   subtype Device is W25Q128_Dev.Device;

   function Make_Device return Device;

end Nor_Flash_Dev;