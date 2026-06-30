with Board;
with MT; use MT;

package body Bitmapped_Drawing is

   --  Draw a 1-pixel-wide line from (X0,Y0) to (X1,Y1) into Buffer.
   --  Uses Bresenham. Each pixel is a 1x1 Fill_Rect via DMA2D.
   procedure Draw_Line
     (Buffer : Bitmap_Buffer;
      X0, Y0, X1, Y1 : Integer;
      Color : Bitmap_Color)
   is
      DX  : constant Integer := abs (X1 - X0);
      DY  : constant Integer := abs (Y1 - Y0);
      SX  : constant Integer := (if X0 < X1 then 1 else -1);
      SY  : constant Integer := (if Y0 < Y1 then 1 else -1);
      Err : Integer := DX - DY;
      X   : Integer := X0;
      Y   : Integer := Y0;
      E2  : Integer;
   begin
      loop
         if X >= 0 and then Y >= 0
           and then X < Buffer.Width and then Y < Buffer.Height
         then
            Board.DMA2D.Fill_Rect (Buffer, Color, X, Y, 1, 1, False);
         end if;
         exit when X = X1 and then Y = Y1;
         E2 := 2 * Err;
         if E2 > -DY then
            Err := Err - DY;
            X   := X + SX;
         end if;
         if E2 < DX then
            Err := Err + DX;
            Y   := Y + SY;
         end if;
      end loop;
   end Draw_Line;

   --  Callback passed to Hershey_Fonts.Draw_Glyph
   --  Buffer is captured via closure through a local access variable.
   procedure Draw_String
     (Buffer     : Bitmap_Buffer;
      Start_X    : Natural;
      Start_Y    : Natural;
      Msg        : String;
      Font       : Hershey_Font;
      Height     : Natural;
      Bold       : Boolean;
      Foreground : Bitmap_Color;
      Fast       : Boolean := True)
   is
      pragma Unreferenced (Fast);

      Current_X : Natural := Start_X;
      Current_Y : Natural := Start_Y;
      Buf_Copy  : constant Bitmap_Buffer := Buffer;
      FG        : constant Bitmap_Color  := Foreground;

      procedure Stroke (X0, Y0, X1, Y1 : Natural; Width : Positive) is
         pragma Unreferenced (Width);
      begin
         Draw_Line (Buf_Copy,
                    Integer (X0), Integer (Y0),
                    Integer (X1), Integer (Y1),
                    FG);
      end Stroke;

      procedure Draw_Glyph is new Hershey_Fonts.Draw_Glyph (Stroke);

   begin
      for C of Msg loop
         exit when Current_X >= Buffer.Width;
         Draw_Glyph
           (Fnt    => Font,
            C      => C,
            X      => Current_X,
            Y      => Current_Y,
            Height => Height,
            Bold   => Bold);
      end loop;
   end Draw_String;

end Bitmapped_Drawing;
