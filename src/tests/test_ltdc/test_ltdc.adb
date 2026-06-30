with Board;
with Debug;
with DC_Types;  use DC_Types;
with Bitmap;    use Bitmap;
with Ada.Real_Time;        use Ada.Real_Time;
with Ada.Unchecked_Conversion;
with System;
with System.Storage_Elements;

procedure Test_LTDC is

   Buf : Bitmap_Buffer;

   type U16 is mod 2**16;
   type U16_Ptr is access all U16;
   function To_Ptr is new Ada.Unchecked_Conversion
     (System.Address, U16_Ptr);

begin
   Board.Initialize;
   Debug.Put_Line ("Board initialized");

   Board.FB_1.Initialize_Layer
     (Layer  => Layer_1,
      Format => RGB565);
   Debug.Put_Line ("Layer 1 initialized");

   Buf := Board.FB_1.Get_Hidden_Buffer (Layer_1);

   Debug.Put_Line
     ("Buf addr: " &
      System.Storage_Elements.Integer_Address'Image
        (System.Storage_Elements.To_Integer (Buf.Addr)));
   Debug.Put_Line
     ("Buf W:" & Buf.Width'Image &
      " H:"   & Buf.Height'Image);

   --  Fill red (RGB565: R=31, G=0, B=0 => 0xF800)
   Board.DMA2D.Fill (Buf, (Alpha => 255, Red => 255, Green => 0, Blue => 0),
                     True);
   Debug.Put_Line ("DMA2D fill done");

   --  Read back first pixel to confirm DMA2D wrote
   declare
      Val : constant U16 := To_Ptr (Buf.Addr).all;
   begin
      Debug.Put_Line ("First pixel (expect 0xF800): " & Val'Image);
   end;

   Board.FB_1.Update_Layer (Layer_1);
   Debug.Put_Line ("Update_Layer done");

   loop
      delay until Clock + Seconds (1);
      Debug.Put_Line ("Still alive");
   end loop;
end Test_LTDC;