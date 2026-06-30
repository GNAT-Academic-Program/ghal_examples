with Bitmap;        use Bitmap;
with Hershey_Fonts; use Hershey_Fonts;

package Bitmapped_Drawing is

   procedure Draw_String
     (Buffer     : Bitmap_Buffer;
      Start_X    : Natural;
      Start_Y    : Natural;
      Msg        : String;
      Font       : Hershey_Font;
      Height     : Natural;
      Bold       : Boolean;
      Foreground : Bitmap_Color;
      Fast       : Boolean := True);
   --  Draw Msg into Buffer using Hershey vector font.
   --  Foreground color used for all strokes.

end Bitmapped_Drawing;
