with Board;
with Debug;
with DC_Types;  use DC_Types;
with Bitmap;    use Bitmap;
with Ada.Real_Time; use Ada.Real_Time;

procedure Test_Display is
   Buf1, Buf2 : Bitmap_Buffer;
begin
   Board.Initialize;

   Board.FB_1.Initialize_Layer (Layer_1, RGB565);
   Board.FB_1.Initialize_Layer (Layer_2, ARGB4444,
     X => 0, Y => 0, Width => 200, Height => 50);

   --  Fill Layer 1 red
   Buf1 := Board.FB_1.Get_Hidden_Buffer (Layer_1);
   Board.DMA2D.Fill (Buf1, (255, 255, 0, 0), True);
   Debug.Put_Line ("L1 addr:" & Buf1.Addr'Image);

   --  Fill Layer 2 blue
   Buf2 := Board.FB_1.Get_Hidden_Buffer (Layer_2);
   Board.DMA2D.Fill (Buf2, (128, 0, 0, 255), True);
   Debug.Put_Line ("L2 addr:" & Buf2.Addr'Image);

   Board.FB_1.Update_Layers;
   Debug.Put_Line ("Done");

   loop
      delay until Clock + Seconds (1);
      Debug.Put_Line ("alive");
   end loop;
end Test_Display;