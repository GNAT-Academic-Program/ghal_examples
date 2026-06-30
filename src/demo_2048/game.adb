with Board;
with MT;            use MT;
with RNG_Types;     use RNG_Types;
with Ada.Real_Time; use Ada.Real_Time;
with Bitmapped_Drawing;
with Debug;

package body Game is

   use type Random_Value;

   procedure Init_Font is
   begin
      Hershey_Fonts.Read (Hershey_Fonts.FuturaL.Font, Times);
   end Init_Font;

   --  Forward declarations
   procedure Init_Background;
   procedure Init_Cells;
   procedure Add_Tile;
   procedure Init_Slide (Old_Grid : CGrid; Trace : Trace_Grid_T);

   --  -----------------------------------------------------------------------
   --  Layout helpers
   --  -----------------------------------------------------------------------

   function Screen_Size return Natural is
     (Natural'Min (Board.LCD_Width, Board.LCD_Height));

   function Cell_To_Pt (X, Y : Size) return Pt is
     (Pt'(X => Ext_Border + Integer (X) * (Cell_Size + Int_Border),
          Y => Ext_Border + Integer (Y) * (Cell_Size + Int_Border)));

   --  -----------------------------------------------------------------------
   --  Get_Status_Area
   --  -----------------------------------------------------------------------

   function Get_Status_Area return Rect is
      SS : constant Natural := Screen_Size;
   begin
      if Board.LCD_Height >= Board.LCD_Width then
         --  Portrait: status strip at top
         return (X => 0, Y => 0,
                 Width  => Board.LCD_Width,
                 Height => Board.LCD_Height - SS);
      else
         --  Landscape (480x272): status strip on right
         return (X => SS, Y => 0,
                 Width  => Board.LCD_Width - SS,
                 Height => Board.LCD_Height);
      end if;
   end Get_Status_Area;

   function Get_Score return Natural is (The_Grid.Score);

   --  -----------------------------------------------------------------------
   --  Init
   --  -----------------------------------------------------------------------

   procedure Init is
      SS         : constant Natural := Screen_Size;
      CM         : constant Bitmap_Color_Mode :=
                     Board.FB_1.Get_Color_Mode (Layer_1);
      Pixel_Size : constant Natural :=
                     Board.FB_1.Get_Pixel_Size (Layer_1);
   begin
      Cell_Size  := (SS - 5 * 8) / 4;
      Int_Border := 8;
      Ext_Border := (SS - 4 * Cell_Size - 3 * Int_Border) / 2;
      Up_Margin  := Board.LCD_Height - SS;

      Background_Buffer :=
        (Addr       => Board.SDRAM_1.Reserve
                         (UInt32 (SS * SS * Pixel_Size)),
         Color_Mode => CM,
         Width      => SS,
         Height     => SS,
         Swapped    => Board.FB_1.Is_Swapped);

      Background_Slide_Buffer :=
        (Addr       => Board.SDRAM_1.Reserve
                         (UInt32 (SS * SS * Pixel_Size)),
         Color_Mode => CM,
         Width      => SS,
         Height     => SS,
         Swapped    => Board.FB_1.Is_Swapped);

      Cells_Buffer :=
        (Addr       => Board.SDRAM_1.Reserve
                         (UInt32 (Cell_Size * Cell_Size * 16 * Pixel_Size)),
         Color_Mode => CM,
         Width      => Cell_Size,
         Height     => Cell_Size * 16,
         Swapped    => Board.FB_1.Is_Swapped);

      Init_Background;
      Init_Cells;
   end Init;

   --  -----------------------------------------------------------------------
   --  Init_Background
   --  -----------------------------------------------------------------------

   procedure Init_Background is
      BG : constant Bitmap_Color := (255, 187, 173, 160);
      Cell_BG : constant Bitmap_Color := (255, 16#CD#, 16#C0#, 16#B4#);
   begin
      Board.DMA2D.Fill (Background_Buffer, BG, True);
      for Y in 0 .. 3 loop
         for X in 0 .. 3 loop
            Board.DMA2D.Fill_Rect
              (Background_Buffer, Cell_BG,
               Ext_Border + (Int_Border + Cell_Size) * X,
               Ext_Border + (Int_Border + Cell_Size) * Y,
               Cell_Size, Cell_Size, True);
         end loop;
      end loop;
   end Init_Background;

   --  -----------------------------------------------------------------------
   --  Init_Cells — 16 tile sprites in a vertical strip
   --  -----------------------------------------------------------------------

   procedure Init_Cells is
      Colors : constant array (0 .. 15) of Bitmap_Color :=
        ((255, 238, 228, 218), (255, 237, 224, 200),
         (255, 242, 177, 121), (255, 245, 149, 99),
         (255, 246, 124, 95),  (255, 246, 94,  59),
         (255, 237, 207, 114), (255, 237, 204, 97),
         (255, 237, 200, 80),  (255, 237, 197, 63),
         (255, 237, 194, 46),  (255, 60,  58,  50),
         (255, 60,  209, 50),  (255, 35,  107, 29),
         (255, 50,  136, 209), (255, 17,  15,  104));
   begin
      for I in Colors'Range loop
         Board.DMA2D.Fill_Rect
           (Cells_Buffer, Colors (I),
            0, I * Cell_Size, Cell_Size, Cell_Size, True);

         --  Draw tile number
         declare
            Num    : constant Positive := 2 ** (I + 1);
            S      : constant String   := Num'Image;
            FG     : constant Bitmap_Color :=
                       (if Num <= 4
                        then (255, 100, 90, 80)
                        else White);
            H      : constant Natural  := Cell_Size * 2 / 5;
            Margin : constant Natural  := Cell_Size / 8;
         begin
            Bitmapped_Drawing.Draw_String
              (Buffer  => Cells_Buffer,
               Start_X => Margin,
               Start_Y => I * Cell_Size + (Cell_Size - H) / 2,
               Msg     => S (S'First + 1 .. S'Last),
               Font    => Times,
               Height  => H,
               Bold    => True,
               Foreground => FG);
            Board.DMA2D.Wait_Transfer;
         end;
      end loop;
   end Init_Cells;

   --  -----------------------------------------------------------------------
   --  Start
   --  -----------------------------------------------------------------------

   procedure Start is
   begin
      The_Grid.Init;
      Add_Tile;
      Add_Tile;
   end Start;

   --  -----------------------------------------------------------------------
   --  Add_Tile
   --  -----------------------------------------------------------------------

   procedure Add_Tile is
      Rand  : Random_Value := Board.RNG_1.Random;
      N_Free : Natural := 0;
      Val    : constant Natural :=
                 (if Board.RNG_1.Random mod 10 = 0 then 2 else 1);
      Pos    : Natural;
   begin
      for X in Size loop
         for Y in Size loop
            if The_Grid.Get (X, Y) = 0 then
               N_Free := N_Free + 1;
            end if;
         end loop;
      end loop;
      if N_Free = 0 then return; end if;
      Pos := Natural (Rand mod Random_Value (N_Free));
      N_Free := 0;
      Outer :
      for X in Size loop
         for Y in Size loop
            if The_Grid.Get (X, Y) = 0 then
               if N_Free = Pos then
                  The_Grid.Set (X, Y, Val);
                  exit Outer;
               end if;
               N_Free := N_Free + 1;
            end if;
         end loop;
      end loop Outer;
   end Add_Tile;

   --  -----------------------------------------------------------------------
   --  Draw
   --  -----------------------------------------------------------------------

   procedure Copy_BG_To (Dst : Bitmap_Buffer) is
   begin
      Board.DMA2D.Copy_Rect
        (Src_Buffer => Background_Buffer,
         X_Src => 0, Y_Src => 0,
         Dst_Buffer => Dst,
         X_Dst => 0, Y_Dst => Dst.Height - Background_Buffer.Height,
         Width  => Background_Buffer.Width,
         Height => Background_Buffer.Height,
         Synchronous => False);
   end Copy_BG_To;

   procedure Draw_Tile (Coord : Pt; Value : Integer; Dst : Bitmap_Buffer) is
   begin
      Board.DMA2D.Copy_Rect
        (Src_Buffer => Cells_Buffer,
         X_Src => 0, Y_Src => (Value - 1) * Cell_Size,
         Dst_Buffer => Dst,
         X_Dst => Coord.X, Y_Dst => Coord.Y,
         Width  => Cell_Size,
         Height => Cell_Size,
         Synchronous => False);
   end Draw_Tile;

   procedure Draw (Dst : Bitmap_Buffer) is
   begin
      Board.DMA2D.Wait_Transfer;
      Copy_BG_To (Dst);
      for Y in Size loop
         for X in Size loop
            declare
               V : constant Integer := The_Grid.Get (X, Y);
               P : Pt;
            begin
               if V /= 0 then
                  P   := Cell_To_Pt (X, Y);
                  P.Y := P.Y + Dst.Height - Background_Buffer.Height;
                  Draw_Tile (P, V, Dst);
               end if;
            end;
         end loop;
      end loop;
   end Draw;

   --  -----------------------------------------------------------------------
   --  Move + slide animation
   --  -----------------------------------------------------------------------

   procedure Move (Direction : Direction_E) is
      Old_Grid : constant CGrid := The_Grid;
      Trace    : Trace_Grid_T;
   begin
      Trace := The_Grid.Move (Direction);
      Init_Slide (Old_Grid, Trace);
      Add_Tile;
   end Move;

   function Can_Move (Direction : Direction_E) return Boolean is
     (The_Grid.Can_Move (Direction));

   function Is_Sliding return Boolean is (Sliding);

   procedure Init_Slide (Old_Grid : CGrid; Trace : Trace_Grid_T) is
   begin
      Slide_Start_Time := Clock;
      Copy_BG_To (Background_Slide_Buffer);
      Board.DMA2D.Wait_Transfer;

      for Y in Size loop
         for X in Size loop
            declare
               I : constant Moving_Cells_Index_T :=
                     Integer (Y) * Size'Range_Length + Integer (X);
               P : constant Cell_Position_T := Trace (X, Y);
            begin
               if P.X /= X or else P.Y /= Y then
                  declare
                     Src_P : Pt := Cell_To_Pt (X, Y);
                     Dst_P : Pt := Cell_To_Pt (P.X, P.Y);
                  begin
                     Src_P.Y := Src_P.Y + Up_Margin;
                     Dst_P.Y := Dst_P.Y + Up_Margin;
                     Moving_Cells (I) :=
                       (Src       => Src_P,
                        Dst       => Dst_P,
                        Src_Value => Old_Grid.Get (X, Y),
                        Dst_Value => The_Grid.Get (P.X, P.Y),
                        V         => (X => (if P.X > X then 1 elsif P.X < X then -1 else 0),
                                      Y => (if P.Y > Y then 1 elsif P.Y < Y then -1 else 0)),
                        Max_Length => abs (Dst_P.X - Src_P.X) +
                                      abs (Dst_P.Y - Src_P.Y),
                        Moving    => True);
                  end;
               else
                  Moving_Cells (I) := (others => <>);
                  Moving_Cells (I).Moving := False;
                  if Old_Grid.Get (X, Y) /= 0 then
                     Draw_Tile (Cell_To_Pt (X, Y),
                                Old_Grid.Get (X, Y),
                                Background_Slide_Buffer);
                  end if;
               end if;
            end;
         end loop;
      end loop;
      Sliding := True;
   end Init_Slide;

   function Slide (Dst : Bitmap_Buffer) return Boolean is
      Slide_Speed : constant Float := Float (Background_Buffer.Width) * 4.0;
      Length      : constant Integer :=
                      Integer (Slide_Speed *
                        Float (Ada.Real_Time.To_Duration
                          (Clock - Slide_Start_Time)));
      Still_Moving : Boolean := False;
      BG_Changed   : Boolean := False;
   begin
      for Cell of Moving_Cells loop
         if Cell.Moving and then Length >= Cell.Max_Length then
            Cell.Moving := False;
            BG_Changed  := True;
            Draw_Tile ((Cell.Dst.X, Cell.Dst.Y - Up_Margin),
                       Cell.Dst_Value,
                       Background_Slide_Buffer);
         end if;
      end loop;

      if BG_Changed then
         Board.DMA2D.Wait_Transfer;
      end if;

      Copy_BG_To (Dst);
      Board.DMA2D.Wait_Transfer;

      for Cell of Moving_Cells loop
         if Cell.Moving then
            Still_Moving := True;
            Draw_Tile
              ((Cell.Src.X + Length * Cell.V.X,
                Cell.Src.Y + Length * Cell.V.Y),
               Cell.Src_Value, Dst);
         end if;
      end loop;

      if not Still_Moving then
         Sliding := False;
      end if;
      return Sliding;
   end Slide;

   --  -----------------------------------------------------------------------
   --  Treat_Touch
   --  -----------------------------------------------------------------------

   Previous : Gesture_Types.Gesture_Id := Gesture_Types.No_Gesture;

   procedure Treat_Touch (G : Gesture_Data) is
      use Gesture_Types;
   begin
      --  Reset Previous when not sliding (animation complete)
      if not Sliding then
         Previous := No_Gesture;
      end if;
      
      if not Sliding and then Previous = No_Gesture then
         case G.Id is
            when V_Scroll =>
               Move (if G.Cumulated > 0 then Down else Up);
               Previous := V_Scroll;
            when H_Scroll =>
               Move (if G.Cumulated > 0 then Right else Left);
               Previous := H_Scroll;
            when others => null;
         end case;
      end if;
   end Treat_Touch;

end Game;
