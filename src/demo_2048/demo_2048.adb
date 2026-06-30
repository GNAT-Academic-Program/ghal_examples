with Board;
with DC_Types;      use DC_Types;
with Bitmap;        use Bitmap;
with Ada.Real_Time; use Ada.Real_Time;
with Touch_Types;   use Touch_Types;
with Gesture;
with Gesture_Types; use Gesture_Types;
with Game;
with Status;
with Tasking;
with Debug;
with I2C_Types;

procedure Demo_2048 is
   G      : Gesture_Data;
   Sample : Touch_State;
   Count  : Touch_Identifier;
begin
   Board.Initialize;
   Debug.Put_Line ("Board.Initialize done");

   Game.Init_Font;
   Debug.Put_Line ("Game.Init_Font done");

   Board.FB_1.Initialize_Layer
     (Layer  => Layer_1,
      Format => RGB565);
   Debug.Put_Line ("Layer_1 initialized");

   declare
      SA : constant Rect := Game.Get_Status_Area;
   begin
      Debug.Put_Line ("Status area: X=" & SA.X'Image &
                      " Y=" & SA.Y'Image &
                      " W=" & SA.Width'Image &
                      " H=" & SA.Height'Image);
      if SA.Width > 0 and then SA.Height > 0 then
         Board.FB_1.Initialize_Layer
           (Layer  => Layer_2,
            Format => ARGB4444,
            X      => SA.X,
            Y      => SA.Y,
            Width  => SA.Width,
            Height => SA.Height);
         Debug.Put_Line ("Layer_2 initialized");
      end if;
   end;

   Board.FB_1.Set_Background (0, 0, 0);
   Debug.Put_Line ("Background set");

   Game.Init;
   Debug.Put_Line ("Game.Init done");

   Game.Start;
   Debug.Put_Line ("Game.Start done");

   declare
      Buf : constant Bitmap_Buffer := Board.FB_1.Get_Hidden_Buffer (Layer_1);
   begin
      Debug.Put_Line ("L1 hidden buf addr:" &
        Bitmap_Buffer'(Buf)'Address'Image);
      Game.Draw (Buf);
      Board.DMA2D.Wait_Transfer;
      Debug.Put_Line ("Game.Draw done");
   end;

   declare
      Buf : constant Bitmap_Buffer := Board.FB_1.Get_Hidden_Buffer (Layer_2);
   begin
      Status.Init_Area (Buf);
      Status.Set_Autoplay_Enabled (True);
      Status.Set_Score (0);
      Debug.Put_Line ("Status init done");
   end;

   Board.FB_1.Update_Layers;
   Debug.Put_Line ("Update_Layers done - screen should show game");

   loop
      Count  := Board.Touch_1.Active_Touch_Points;
      if Count > 0 then
         Sample := Board.Touch_1.Get_Touch_Point (1);
         Debug.Put_Line ("Touch X=" & Sample.X'Image &
                         " Y=" & Sample.Y'Image);
      else
         Sample := (X => 0, Y => 0, Weight => 0);
      end if;

      Gesture.Process (Sample, Count, G);
      
      --  Debug: print gesture info
      if G.Id /= No_Gesture then
         Debug.Put_Line ("Gesture: " & G.Id'Image &
                         " Origin X=" & G.Origin.X'Image &
                         " Y=" & G.Origin.Y'Image &
                         " Cumulated=" & G.Cumulated'Image);
      end if;
      
      --  Filter gestures: if tap is on autoplay button, toggle solver instead
      --  of passing to game. Otherwise pass swipes to game.
      if G.Id = Tap then
         declare
            Area : constant Rect := Status.Get_Autoplay_Btn_Area;
         begin
            if G.Origin.X >= Area.X and then G.Origin.X < Area.X + Area.Width
              and then G.Origin.Y >= Area.Y and then G.Origin.Y < Area.Y + Area.Height
            then
               Tasking.Toggle_Solver;
            else
               Tasking.Handle_Gesture (G);
            end if;
         end;
      else
         Tasking.Handle_Gesture (G);
      end if;
      
      delay until Clock + Milliseconds (20);
   end loop;
end Demo_2048;
