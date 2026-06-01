with Board;

package body Nor_Flash_Dev is

   function Make_Device return Device is
   begin
      return W25Q128_Dev.Chip.Make_Device
        (Spi => Board.Spi_1_DEV'Access,
         CS  => Board.Spi_1_CS);
   end Make_Device;

end Nor_Flash_Dev;