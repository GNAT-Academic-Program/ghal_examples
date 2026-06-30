with Board;
with I2C_Types;
with BMP;
with Debug;
with System.Storage_Elements; use System.Storage_Elements;

procedure I2C_Bmp is

   BMP390_Address : constant I2C_Types.I2C_Address := 16#77#;

   Sensor       : BMP.Sensor;
   Pwr_Ctrl     : constant BMP.Pwr_Control :=
     (Press_En => 0, Temp_En => 1, Modee => BMP.Normal, others => <>);
   Pwr_Ctrl_Reg : Storage_Element;
   Temp_C       : BMP.Temperature := 0.0;

begin
   Board.Initialize;

   Debug.Put_Line ("Opening BMP390...");
   BMP.Open (Sensor, BMP390_Address, Pwr_Ctrl);
   Debug.Put_Line ("BMP390 open OK");

   loop
      BMP.Read_Pwr_Control (Sensor, Pwr_Ctrl_Reg);
      Debug.Put_Line ("pwr_ctrl: " & Debug.Hex (Natural (Pwr_Ctrl_Reg)));

      BMP.Read_Temperature (Sensor, Temp_C);
      Debug.Put_Line ("temp: " & Temp_C'Image & " C");

      delay 0.5;
   end loop;
end I2C_Bmp;
