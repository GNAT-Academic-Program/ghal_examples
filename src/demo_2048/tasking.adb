with Ada.Real_Time; use Ada.Real_Time;
with Bitmap;        use Bitmap;
with DC_Types;      use DC_Types;
with Gesture_Types; use Gesture_Types;
with Gpio;
with Board;
with Game;
with Grid;
with Status;
with Solver;

package body Tasking is

   protected Draw_Prot is
      entry Wait;
      procedure Signal;
   private
      Pending : Boolean := False;
   end Draw_Prot;

   protected body Draw_Prot is
      entry Wait when Pending is
      begin Pending := False; end Wait;
      procedure Signal is begin Pending := True; end Signal;
   end Draw_Prot;

   protected Drawing is
      entry Wait_Done;
      procedure Set_Busy (B : Boolean);
   private
      Idle : Boolean := True;
   end Drawing;

   protected body Drawing is
      entry Wait_Done when Idle is begin null; end Wait_Done;
      procedure Set_Busy (B : Boolean) is begin Idle := not B; end Set_Busy;
   end Drawing;

   protected Events is
      entry Wait;
      procedure Set_Gesture (G : Gesture_Data);
      procedure Set_Solver_Toggle;
      function  Has_Gesture return Boolean;
      procedure Get_Gesture (G : out Gesture_Data);
      function  Solver_Toggled return Boolean;
      procedure Clear_Solver_Toggle;
      function  Solver_On return Boolean;
   private
      Has_Event    : Boolean      := False;
      New_Gesture  : Boolean      := False;
      Pending_G    : Gesture_Data;
      Sol_Toggled  : Boolean      := False;
      Sol_On       : Boolean      := False;
   end Events;

   protected body Events is
      entry Wait when Has_Event is
      begin Has_Event := False; end Wait;

      procedure Set_Gesture (G : Gesture_Data) is
      begin
         if G.Id /= No_Gesture then
            Pending_G   := G;
            New_Gesture := True;
            Has_Event   := True;
         end if;
      end Set_Gesture;

      procedure Set_Solver_Toggle is
      begin
         Sol_On      := not Sol_On;
         Sol_Toggled := True;
         Has_Event   := True;
      end Set_Solver_Toggle;

      function Has_Gesture   return Boolean is (New_Gesture);
      function Solver_Toggled return Boolean is (Sol_Toggled);
      function Solver_On      return Boolean is (Sol_On);

      procedure Get_Gesture (G : out Gesture_Data) is
      begin
         G           := Pending_G;
         New_Gesture := False;
      end Get_Gesture;

      procedure Clear_Solver_Toggle is
      begin Sol_Toggled := False; end Clear_Solver_Toggle;
   end Events;

   procedure Handle_Gesture (G : Gesture_Data) is
   begin
      Events.Set_Gesture (G);
   end Handle_Gesture;

   procedure Toggle_Solver is
   begin
      Events.Set_Solver_Toggle;
   end Toggle_Solver;

   task body Slider is
      Buf : Bitmap_Buffer;
   begin
      loop
         Draw_Prot.Wait;
         Drawing.Set_Busy (True);

         while Game.Is_Sliding loop
            Buf := Board.FB_1.Get_Hidden_Buffer (Layer_1);
            exit when not Game.Slide (Buf);
            Board.DMA2D.Wait_Transfer;
            delay until Clock + Milliseconds (16);
            Board.FB_1.Update_Layer (Layer_1);
         end loop;

         Buf := Board.FB_1.Get_Hidden_Buffer (Layer_1);
         Game.Draw (Buf);
         Board.DMA2D.Wait_Transfer;
         Status.Set_Score (Game.The_Grid.Score);
         Board.FB_1.Update_Layers;

         Drawing.Set_Busy (False);
      end loop;
   end Slider;

   task body Controller is
      Sol_On : Boolean := False;
      G      : Gesture_Data;
      NM     : Solver.Move_Type;
   begin
      loop
         if not Sol_On then
            Events.Wait;
         end if;

         if Events.Solver_Toggled then
            Sol_On := Events.Solver_On;
            Events.Clear_Solver_Toggle;
            Drawing.Wait_Done;
            Status.Set_Autoplay (Sol_On);
            Board.FB_1.Update_Layer (Layer_2);
            if Sol_On then
               Gpio.Set (Board.Led);
            else
               Gpio.Clr (Board.Led);
            end if;
         end if;

         if Sol_On then
            NM := Solver.Next_Move (Game.The_Grid);
            Drawing.Wait_Done;
            case NM is
               when Solver.Up    => Game.Move (Grid.Up);
               when Solver.Down  => Game.Move (Grid.Down);
               when Solver.Left  => Game.Move (Grid.Left);
               when Solver.Right => Game.Move (Grid.Right);
               when Solver.None  => Game.Start;
            end case;
            Draw_Prot.Signal;
            delay until Clock + Milliseconds (300);

         elsif Events.Has_Gesture then
            Events.Get_Gesture (G);
            Game.Treat_Touch (G);
            Draw_Prot.Signal;
         end if;
      end loop;
   end Controller;

end Tasking;
