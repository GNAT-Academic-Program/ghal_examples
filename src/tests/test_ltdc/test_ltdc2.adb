with Board;
with Debug;
with DC_Types;  use DC_Types;
with Bitmap;    use Bitmap;
with Ada.Real_Time;        use Ada.Real_Time;
with Ada.Unchecked_Conversion;
with System;
with System.Storage_Elements; use System.Storage_Elements;
with Interfaces; use Interfaces;

procedure Test_LTDC2 is

   type U32     is mod 2**32;
   type U32_Ptr is access all U32;
   function To_P is new Ada.Unchecked_Conversion
     (System.Address, U32_Ptr);

begin
   Board.Initialize;
   Debug.Put_Line ("Board initialized");

   --  Test DMA2D BEFORE layer init
   declare
      Addr : constant System.Address :=
        Board.SDRAM_1.Reserve (64 * 4);
      Small : constant Bitmap_Buffer :=
        (Addr       => Addr,
         Width      => 8,
         Height     => 1,
         Color_Mode => ARGB_8888,
         Swapped    => False);
   begin
      To_P (Addr).all := 0;
      Board.DMA2D.Fill (Small, (255, 255, 0, 0), True);
      Debug.Put_Line
        ("DMA2D BEFORE layer init: " & To_P (Addr).all'Image);
      --  expect 4294901760 = 0xFFFF0000
   end;

   --  Initialize layer
   Board.FB_1.Initialize_Layer
     (Layer  => Layer_1,
      Format => RGB565);
   Debug.Put_Line ("Layer 1 initialized");

   --  Test DMA2D AFTER layer init
   declare
      Buf  : constant Bitmap_Buffer :=
        Board.FB_1.Get_Hidden_Buffer (Layer_1);
      Addr : constant System.Address := Buf.Addr;
   begin
      Debug.Put_Line
        ("FB buf addr: " &
         Integer_Address'Image (To_Integer (Addr)));
      Debug.Put_Line
        ("FB buf W:" & Buf.Width'Image &
         " H:" & Buf.Height'Image);

      To_P (Addr).all := 0;
      Board.DMA2D.Fill (Buf, (255, 255, 0, 0), True);
      Debug.Put_Line
        ("DMA2D AFTER layer init: " & To_P (Addr).all'Image);
      --  RGB565 red = 0xF800 = 63488
      --  But we're reading as U32 from RGB565 buffer so two pixels packed:
      --  expect 0xF800F800 = 4160814080... or just non-zero
   end;

   --  Update and show
   Board.FB_1.Update_Layer (Layer_1);
   Debug.Put_Line ("Update_Layer done");

   loop
      delay until Clock + Seconds (1);
      Debug.Put_Line ("Still alive");
   end loop;
end Test_LTDC2;