with Board;
with Debug;
with Bitmap;    use Bitmap;
with MT;        use MT;
with Ada.Real_Time;        use Ada.Real_Time;
with Ada.Unchecked_Conversion;
with System;
with System.Storage_Elements; use System.Storage_Elements;

procedure Test_DMA2D is

   type U32     is mod 2**32;
   type U32_Ptr is access all U32;
   function To_U32_Ptr is new Ada.Unchecked_Conversion
     (System.Address, U32_Ptr);

   --  Allocate a small buffer in SDRAM
   Buf_Size : constant := 64 * 64 * 4;  --  64x64 ARGB8888
   Buf_Addr : System.Address;

   Buf : Bitmap_Buffer;

   procedure Check
     (Label    : String;
      Got      : U32;
      Expected : U32)
   is
   begin
      if Got = Expected then
         Debug.Put_Line (Label & ": PASS (0x" & Got'Image & ")");
      else
         Debug.Put_Line (Label & ": FAIL got=0x" & Got'Image &
                         " expected=0x" & Expected'Image);
      end if;
   end Check;

begin
   Board.Initialize;
   Debug.Put_Line ("Board initialized");

   --  Allocate buffer from SDRAM
   Buf_Addr := Board.SDRAM_1.Reserve (UInt32 (Buf_Size));
   Debug.Put_Line
     ("Buffer at: " &
      Integer_Address'Image (To_Integer (Buf_Addr)));

   Buf := (Addr       => Buf_Addr,
           Width      => 64,
           Height     => 64,
           Color_Mode => ARGB_8888,
           Swapped    => False);

   --  Test 1: Fill entire buffer red
   Debug.Put_Line ("Test 1: Fill red...");
   Board.DMA2D.Fill (Buf, (255, 255, 0, 0), True);
   Check ("  First pixel",  To_U32_Ptr (Buf_Addr).all,             16#FFFF0000#);
   Check ("  Last pixel",   To_U32_Ptr (Buf_Addr + (Buf_Size - 4)).all, 16#FFFF0000#);

   --  Test 2: Fill rect green in top-left 10x10
   Debug.Put_Line ("Test 2: Fill_Rect green 10x10...");
   Board.DMA2D.Fill_Rect
     (Buf, (255, 0, 255, 0), 0, 0, 10, 10, True);
   Check ("  Pixel (0,0)",   To_U32_Ptr (Buf_Addr).all,            16#FF00FF00#);
   Check ("  Pixel (9,9)",   To_U32_Ptr (Buf_Addr + (9 * 64 + 9) * 4).all, 16#FF00FF00#);
   Check ("  Pixel (10,0)",  To_U32_Ptr (Buf_Addr + 10 * 4).all,  16#FFFF0000#);

   --  Test 3: Copy_Rect — copy green rect to bottom-right
   Debug.Put_Line ("Test 3: Copy_Rect...");
   Board.DMA2D.Copy_Rect
     (Src_Buffer => Buf, X_Src => 0, Y_Src => 0,
      Dst_Buffer => Buf, X_Dst => 54, Y_Dst => 54,
      Width => 10, Height => 10, Synchronous => True);
   Check ("  Dst pixel (54,54)",
          To_U32_Ptr (Buf_Addr + (54 * 64 + 54) * 4).all,
          16#FF00FF00#);
   Check ("  Dst pixel (63,63)",
          To_U32_Ptr (Buf_Addr + (63 * 64 + 63) * 4).all,
          16#FF00FF00#);

   Debug.Put_Line ("DMA2D test complete.");

   loop
      delay until Clock + Seconds (5);
      Debug.Put_Line ("Still alive");
   end loop;
end Test_DMA2D;