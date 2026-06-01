with Board;
with Usart_Types;
with I2C_Types;

with Debug;

with Ada.Characters.Latin_1;
with System.Storage_Elements; use System.Storage_Elements;

with Last_Chance_Handler;
pragma Unreferenced (Last_Chance_Handler);

procedure I2C_0 is

   BMP390_Address          : constant I2C_Types.I2C_Address := 16#77#;
   BMP390_Chip_Id_Register : constant Storage_Element       := 16#00#;

   Tx_Buf  : Storage_Array (1 .. 1) := (1 => BMP390_Chip_Id_Register);
   Rx_Buf  : Storage_Array (1 .. 1);
   Chip_Id : Storage_Element := 0;

begin
   Board.Initialize;

   Board.I2C_1.Open
     (Board.I2C_1_Dev,
      (Speed => I2C_Types.Standard_Mode,
       Role  => I2C_Types.Master_Only));

   loop
      Board.I2C_1.Write (Board.I2C_1_Dev,
                      BMP390_Address,
                      Tx_Buf);

      Chip_Id := Rx_Buf (1);
      Debug.Put_Line ("BMP390 @ 0x");

      delay 1.0;
   end loop;
end I2C_0;