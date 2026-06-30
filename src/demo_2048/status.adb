with Bitmap;            use Bitmap;
with Bitmapped_Drawing;
with Board;
with DC_Types;          use DC_Types;
with Game;
with Hershey_Fonts;

package body Status is

   Null_Rect : constant Rect := (0, 0, 0, 0);
   G_Area    : Rect := Null_Rect;
   Score_Area : Rect := Null_Rect;
   High_Area  : Rect := Null_Rect;
   Btn_Area   : Rect := Null_Rect;
   Margin     : Natural := 4;

   Box_BG    : constant Bitmap_Color := (255, 187, 173, 160);
   Box_FG    : constant Bitmap_Color := (255, 255, 255, 255);
   Label_FG  : constant Bitmap_Color := (255, 230, 213, 197);

   G_High : Integer := -1;

   type AP_State is (Disabled, Off, On);
   G_AP : AP_State := Disabled;

   procedure Draw_Label
      (Buf : Bitmap_Buffer; Area : Rect; Msg : String; FG : Bitmap_Color)
   is
      Max_H : constant Natural := Natural'Max (1, Area.Height * 2 / 5);
      Raw_W : constant Natural := Hershey_Fonts.Strlen (Msg, Game.Times, Max_H);
      H     : constant Natural :=
        (if Raw_W <= Area.Width - 2 * Margin then
            Max_H
         else
            Natural'Max (1, Max_H * (Area.Width - 2 * Margin) / Raw_W));
   begin
      Bitmapped_Drawing.Draw_String
        (Buffer     => Buf,
         Start_X    => Area.X + Margin,
         Start_Y    => Area.Y + Margin,
         Msg        => Msg,
         Font       => Game.Times,
         Height     => H,
         Bold       => False,
         Foreground => FG);
   end Draw_Label;

   procedure Init_Area (Buffer : Bitmap_Buffer) is
      W : constant Natural := Buffer.Width;
      H : constant Natural := Buffer.Height;
   begin
      if G_Area /= Null_Rect then return; end if;
      G_Area := Game.Get_Status_Area;

      --  Layer 2 uses alpha (ARGB4444). Clear the whole layer first so
      --  uninitialized SDRAM alpha/pixels do not blend as random noise.
      Board.DMA2D.Fill (Buffer, Transparent, True);

      Score_Area := (Margin, Margin,
                     W / 2 - 2 * Margin, H / 3 - Margin);
      High_Area  := (W / 2 + Margin, Margin,
                     W / 2 - 2 * Margin, H / 3 - Margin);
      Btn_Area   := (Margin * 4, H / 3 + Margin,
                     W - 8 * Margin, H / 3);

      Board.DMA2D.Fill_Rect (Buffer, Box_BG,
        Score_Area.X, Score_Area.Y, Score_Area.Width, Score_Area.Height, True);
      Draw_Label (Buffer, Score_Area, "SCORE", Label_FG);

      Board.DMA2D.Fill_Rect (Buffer, Box_BG,
        High_Area.X, High_Area.Y, High_Area.Width, High_Area.Height, True);
      Draw_Label (Buffer, High_Area, "BEST", Label_FG);
   end Init_Area;

   function Has_Buttons return Boolean is (Btn_Area /= Null_Rect);

   function Get_Autoplay_Btn_Area return Rect is
     (X      => Btn_Area.X + G_Area.X,
      Y      => Btn_Area.Y + G_Area.Y,
      Width  => Btn_Area.Width,
      Height => Btn_Area.Height);

   procedure Draw_Button (Buf : Bitmap_Buffer) is
      BG : constant Bitmap_Color :=
             (case G_AP is
                when Disabled => (255, 180, 180, 180),
                when Off      => (255, 200, 200, 200),
                when On       => (255, 100, 200, 100));
      FG : constant Bitmap_Color :=
             (case G_AP is
                when Disabled => (255, 150, 150, 150),
                when Off | On => (255, 50, 50, 50));
   begin
      Board.DMA2D.Fill_Rect (Buf, BG,
        Btn_Area.X, Btn_Area.Y, Btn_Area.Width, Btn_Area.Height, True);
      Draw_Label (Buf, Btn_Area, "AUTO", FG);
   end Draw_Button;

   procedure Set_Autoplay_Enabled (State : Boolean) is
      Buf : constant Bitmap_Buffer := Board.FB_1.Get_Hidden_Buffer (Layer_2);
   begin
      G_AP := (if State then Off else Disabled);
      Draw_Button (Buf);
   end Set_Autoplay_Enabled;

   procedure Set_Autoplay (State : Boolean) is
      Buf : constant Bitmap_Buffer := Board.FB_1.Get_Hidden_Buffer (Layer_2);
   begin
      if G_AP = Disabled then return; end if;
      G_AP := (if State then On else Off);
      Draw_Button (Buf);
   end Set_Autoplay;

   procedure Set_Score (Score : Natural) is
      Img : constant String := Score'Image;
      Buf : constant Bitmap_Buffer := Board.FB_1.Get_Hidden_Buffer (Layer_2);
      Msg : constant String := Img (Img'First + 1 .. Img'Last);
      Max_H : constant Natural := Natural'Max (1, Score_Area.Height * 2 / 5);
      Raw_W : constant Natural := Hershey_Fonts.Strlen (Msg, Game.Times, Max_H);
      H   : constant Natural :=
        (if Raw_W <= Score_Area.Width - 2 * Margin then
            Max_H
         else
            Natural'Max (1, Max_H * (Score_Area.Width - 2 * Margin) / Raw_W));
      Y   : constant Natural := Score_Area.Y + Score_Area.Height / 2;
   begin
      Board.DMA2D.Fill_Rect (Buf, Box_BG,
        Score_Area.X, Y, Score_Area.Width, Score_Area.Height / 2, True);
      Bitmapped_Drawing.Draw_String
         (Buffer     => Buf,
          Start_X    => Score_Area.X + Margin,
          Start_Y    => Y,
          Msg        => Msg,
          Font       => Game.Times,
          Height     => H,
         Bold       => True,
         Foreground => Box_FG);

      if Score > G_High then
         G_High := Score;
         Board.DMA2D.Fill_Rect (Buf, Box_BG,
           High_Area.X, Y, High_Area.Width, High_Area.Height / 2, True);
         Bitmapped_Drawing.Draw_String
           (Buffer     => Buf,
            Start_X    => High_Area.X + Margin,
            Start_Y    => Y,
            Msg        => Msg,
            Font       => Game.Times,
            Height     => H,
            Bold       => True,
            Foreground => Box_FG);
      end if;
   end Set_Score;

end Status;
