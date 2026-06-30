with System;
with Gesture_Types; use Gesture_Types;

package Tasking is

   procedure Handle_Gesture (G : Gesture_Data);
   procedure Toggle_Solver;

   task Slider with
     Priority     => System.Priority'Last,
     Storage_Size => 8 * 1024;

   task Controller with
     Priority     => System.Priority'Last - 1,
     Storage_Size => 32 * 1024;

end Tasking;
