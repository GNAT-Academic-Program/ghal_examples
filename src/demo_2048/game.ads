with Bitmap;        use Bitmap;
with DC_Types;      use DC_Types;
with Gesture_Types; use Gesture_Types;
with Grid;          use Grid;
with Ada.Real_Time; use Ada.Real_Time;
with Hershey_Fonts;
with Hershey_Fonts.FuturaL;

package Game is

   Times : Hershey_Fonts.Hershey_Font;

   procedure Init_Font;

   The_Grid : CGrid;
   --  Public so Tasking and Status can read Score and pass to Move.

   procedure Init;
   function  Get_Status_Area return Rect;
   function  Get_Score return Natural;
   procedure Start;
   procedure Draw    (Dst : Bitmap_Buffer);
   procedure Move    (Direction : Direction_E);
   function  Can_Move (Direction : Direction_E) return Boolean;
   function  Is_Sliding return Boolean;
   function  Slide   (Dst : Bitmap_Buffer) return Boolean;
   procedure Treat_Touch (G : Gesture_Data);

private
   type Pt  is record X, Y : Integer; end record;
   type Spd is record X, Y : Integer; end record;

   type Moving_Cell_T is record
      Src, Dst   : Pt      := (0, 0);
      Src_Value  : Integer := 0;
      Dst_Value  : Integer := 0;
      V          : Spd     := (0, 0);
      Max_Length : Integer := 0;
      Moving     : Boolean := False;
   end record;

   subtype Moving_Cells_Index_T is
     Integer range 0 .. Size'Range_Length * Size'Range_Length - 1;
   type Moving_Cells_A is array (Moving_Cells_Index_T) of Moving_Cell_T;

   Moving_Cells     : Moving_Cells_A;
   Sliding          : Boolean          := False;
   Slide_Start_Time : Ada.Real_Time.Time;
   Cell_Size        : Natural          := 0;
   Ext_Border       : Natural          := 0;
   Int_Border       : Natural          := 8;
   Up_Margin        : Natural          := 0;

   Background_Buffer       : Bitmap_Buffer;
   Background_Slide_Buffer : Bitmap_Buffer;
   Cells_Buffer            : Bitmap_Buffer;

end Game;
