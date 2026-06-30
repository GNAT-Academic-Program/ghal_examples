pragma Ada_2022;
pragma SPARK_Mode (Off);

with I2C_Types;
with I2C_Interface;

with MT;
with System.Storage_Elements; use System.Storage_Elements;

--  BMP390 is a device-level driver for the Bosch BMP390 pressure/temperature sensor.
--  It is generic over an I2C bus package (which models the physical I2C peripheral).
--  Each Sensor record carries the chip's I2C address and calibration state.

generic
   with package Bus is new I2C_Interface (<>);
package BMP390 is

   BMP390_Error : Exception;

   type Sensor is limited private;

   subtype Chip_Id         is MT.UInt8;
   subtype Raw_Temperature is MT.UInt32;
   subtype Temperature     is Float;

   type Mode is (Sleep, Forced_1, Forced_2, Normal) with Size => 2;
   for Mode use (
      Sleep    => 2#00#,
      Forced_1 => 2#01#,
      Forced_2 => 2#10#,
      Normal   => 2#11#
   );

   type Pwr_Control is record
      Press_En   : MT.Bit   := 0;
      Temp_En    : MT.Bit   := 0;
      Reserved_0 : MT.UInt2 := 0;
      Modee      : Mode     := Sleep;
      Reserved_1 : MT.UInt2 := 0;
   end record with Size => 8;

   for Pwr_Control use record
      Press_En   at 0 range 0 .. 0;
      Temp_En    at 0 range 1 .. 1;
      Reserved_0 at 0 range 2 .. 3;
      Modee      at 0 range 4 .. 5;
      Reserved_1 at 0 range 6 .. 7;
   end record;

   procedure Open
     (Dev      : in out Sensor;
      Addr     : I2C_Types.I2C_Address;
      Pwr_Ctrl : Pwr_Control);

   function Read_Chip_Id (Dev : Sensor) return Chip_Id;

   procedure Read_Pwr_Control
     (Dev      : in out Sensor;
      Pwr_Ctrl : out Storage_Element);

   procedure Read_Raw_Temperature
     (Dev : in out Sensor;
      Raw : out Raw_Temperature);

   procedure Read_Temperature
     (Dev    : in out Sensor;
      Temp_C : out Temperature);

private

   type Calibration is record
      Par_T1 : Float;
      Par_T2 : Float;
      Par_T3 : Float;
   end record;

   type Sensor is record
      Addr : I2C_Types.I2C_Address;
      Cal  : Calibration;
   end record;

end BMP390;