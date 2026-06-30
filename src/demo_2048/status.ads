with Bitmap; use Bitmap;

package Status is
   procedure Init_Area (Buffer : Bitmap_Buffer);
   procedure Set_Score (Score : Natural);
   function  Has_Buttons return Boolean;
   procedure Set_Autoplay_Enabled (State : Boolean);
   procedure Set_Autoplay (State : Boolean);
   function  Get_Autoplay_Btn_Area return Rect;
end Status;
