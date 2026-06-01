pragma Ada_2022;
pragma SPARK_Mode (Off);

with Ada.Unchecked_Conversion;
with Ada.Real_Time; use Ada.Real_Time;
with Interfaces; use Interfaces;

package body BMP390 is

   --  -------------------------------------------------------------------
   --  Register addresses (Bosch BMP390 datasheet §5)
   --  -------------------------------------------------------------------

   Chip_Id_Reg    : constant Storage_Element := 16#00#;
   Status_Reg_Loc : constant Storage_Element := 16#03#;
   Temp_Data_Reg  : constant Storage_Element := 16#07#;
   Pwr_Ctrl_Reg   : constant Storage_Element := 16#1B#;
   Calib_Reg      : constant Storage_Element := 16#31#;

   Expected_Chip_Id : constant Chip_Id := 16#60#;

   --  Power-mode settle time after writing PWR_CTRL. The datasheet
   --  specifies setup times in microseconds; 10 ms is conservative.
   Power_Settle_Time : constant Time_Span := Milliseconds (10);

   --  -------------------------------------------------------------------
   --  Status register layout
   --  -------------------------------------------------------------------

   type Status_Reg is record
      Reserved_0 : MT.UInt4 := 0;
      Cmd_Rdy    : MT.Bit   := 0;
      DrDy_Press : MT.Bit   := 0;
      DrDy_Temp  : MT.Bit   := 0;
      Reserved_1 : MT.Bit   := 0;
   end record with Size => 8;

   for Status_Reg use record
      Reserved_0 at 0 range 0 .. 3;
      Cmd_Rdy    at 0 range 4 .. 4;
      DrDy_Press at 0 range 5 .. 5;
      DrDy_Temp  at 0 range 6 .. 6;
      Reserved_1 at 0 range 7 .. 7;
   end record;

   function Byte_To_Status_Reg is new Ada.Unchecked_Conversion
     (Storage_Element, Status_Reg);

   --  -------------------------------------------------------------------
   --  Local helpers
   --  -------------------------------------------------------------------

   type Int8 is range -128 .. 127 with Size => 8;

   --  Combine two little-endian bytes into a 16-bit unsigned value.
   --  BMP390 transmits calibration data LSB-first per datasheet §3.11.1.
   function LE_UInt16 (Lo, Hi : Storage_Element) return MT.UInt16 is
     (MT.UInt16 (Lo) or (MT.UInt16 (Hi) * 256));

   function To_Int8 (B : Storage_Element) return Int8 is
     (if B < 128 then Int8 (B) else Int8 (Integer (B) - 256));

   --  -------------------------------------------------------------------
   --  Calibration coefficient scaling factors (datasheet §9.1)
   --  -------------------------------------------------------------------

   T1_Scale : constant Float := 2.0**8;
   T2_Scale : constant Float := 2.0**(-30);
   T3_Scale : constant Float := 2.0**(-48);

   --  -------------------------------------------------------------------
   --  Internal: read calibration coefficients
   --  -------------------------------------------------------------------

   procedure Set_Correction (Dev : in out Sensor) is
      Tx : constant Storage_Array (1 .. 1) := [1 => Calib_Reg];
      Rx : Storage_Array (1 .. 5);

      Raw_T1 : MT.UInt16;
      Raw_T2 : MT.UInt16;
      Raw_T3 : Int8;
   begin
      Bus.Write_Read (Dev.Bus.all, Dev.Addr, Tx, Rx);

      Raw_T1 := LE_UInt16 (Rx (1), Rx (2));
      Raw_T2 := LE_UInt16 (Rx (3), Rx (4));
      Raw_T3 := To_Int8   (Rx (5));

      Dev.Cal :=
        (Par_T1 => Float (Raw_T1) * T1_Scale,
         Par_T2 => Float (Raw_T2) * T2_Scale,
         Par_T3 => Float (Raw_T3) * T3_Scale);
   end Set_Correction;

   --  -------------------------------------------------------------------
   --  Status register read
   --  -------------------------------------------------------------------

   function Get_Status_Reg (Dev : in out Sensor) return Status_Reg is
      Tx : constant Storage_Array (1 .. 1) := [1 => Status_Reg_Loc];
      Rx : Storage_Array (1 .. 1);
   begin
      Bus.Write_Read (Dev.Bus.all, Dev.Addr, Tx, Rx);
      return Byte_To_Status_Reg (Rx (1));
   end Get_Status_Reg;
   pragma Unreferenced (Get_Status_Reg);

   --  -------------------------------------------------------------------
   --  Power control
   --  -------------------------------------------------------------------

   procedure Set_Pwr_Ctrl
     (Dev      : in out Sensor;
      Pwr_Ctrl : Pwr_Control)
   is
      function To_Byte is new Ada.Unchecked_Conversion
        (Pwr_Control, Storage_Element);

      Tx : constant Storage_Array (1 .. 2) :=
        [1 => Pwr_Ctrl_Reg,
         2 => To_Byte (Pwr_Ctrl)];
   begin
      Bus.Write (Dev.Bus.all, Dev.Addr, Tx);
      delay until Clock + Power_Settle_Time;
   end Set_Pwr_Ctrl;

   --  -------------------------------------------------------------------
   --  Public entry point
   --  -------------------------------------------------------------------

   procedure Open
     (Dev      : in out Sensor;
      I2C      : access Bus.Device;
      Addr     : I2C_Types.I2C_Address;
      Pwr_Ctrl : Pwr_Control)
   is
   begin
      Dev.Bus  := I2C;
      Dev.Addr := Addr;
      Set_Pwr_Ctrl   (Dev, Pwr_Ctrl);
      Set_Correction (Dev);
   end Open;

   --  -------------------------------------------------------------------
   --  Chip ID
   --  -------------------------------------------------------------------

   function Read_Chip_Id (Dev : Sensor) return Chip_Id is
      Tx : constant Storage_Array (1 .. 1) := [1 => Chip_Id_Reg];
      Rx : Storage_Array (1 .. 1) := [1 => 0];
   begin
      Bus.Write_Read (Dev.Bus.all, Dev.Addr, Tx, Rx);
      return Chip_Id (Rx (1));
   end Read_Chip_Id;

   --  -------------------------------------------------------------------
   --  Power control readback (diagnostic)
   --  -------------------------------------------------------------------

   procedure Read_Pwr_Control
     (Dev      : in out Sensor;
      Pwr_Ctrl : out Storage_Element)
   is
      Tx : constant Storage_Array (1 .. 1) := [1 => Pwr_Ctrl_Reg];
      Rx : Storage_Array (1 .. 1);
   begin
      Bus.Write_Read (Dev.Bus.all, Dev.Addr, Tx, Rx);
      Pwr_Ctrl := Rx (1);
   end Read_Pwr_Control;

   --  -------------------------------------------------------------------
   --  Raw temperature read
   --  -------------------------------------------------------------------

   procedure Read_Raw_Temperature
     (Dev : in out Sensor;
      Raw : out Raw_Temperature)
   is
      Tx : constant Storage_Array (1 .. 1) := [1 => Temp_Data_Reg];
      Rx : Storage_Array (1 .. 3);
   begin
      Bus.Write_Read (Dev.Bus.all, Dev.Addr, Tx, Rx);
      Raw := Raw_Temperature (Rx (1))
           + Raw_Temperature (Rx (2)) * 256
           + Raw_Temperature (Rx (3)) * 65_536;
   end Read_Raw_Temperature;

   --  -------------------------------------------------------------------
   --  Compensated temperature (Bosch float algorithm, datasheet §9.2)
   --  -------------------------------------------------------------------

   procedure Read_Temperature
     (Dev    : in out Sensor;
      Temp_C : out Temperature)
   is
      Raw : Raw_Temperature;
   begin
      Read_Raw_Temperature (Dev, Raw);

      declare
         Partial_1 : constant Float := Float (Raw) - Dev.Cal.Par_T1;
         Partial_2 : constant Float := Partial_1 * Dev.Cal.Par_T2;
      begin
         Temp_C := Partial_2 + (Partial_1 * Partial_1) * Dev.Cal.Par_T3;
      end;
   end Read_Temperature;

end BMP390;