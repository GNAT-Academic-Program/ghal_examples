with Interfaces; use Interfaces;
with MT;         use MT;

package body Solver is

   type Grid_Hash is new UInt64;

   Max_Depth : constant := 3;

   function Hash (G : CGrid) return Grid_Hash is
      H : Grid_Hash := 0;
   begin
      for Y in Size loop
         for X in Size loop
            H := Shift_Left (H, 4) or Grid_Hash (G.Get (X, Y) mod 16);
         end loop;
      end loop;
      return H;
   end Hash;

   function Eval (G : CGrid) return Float is
      Score : Float := Float (G.Score);
      Empty : Natural := 0;
   begin
      for Y in Size loop
         for X in Size loop
            if G.Get (X, Y) = 0 then
               Empty := Empty + 1;
            end if;
         end loop;
      end loop;
      return Score + Float (Empty) * 10.0;
   end Eval;

   function Expectimax
     (G     : CGrid;
      Depth : Natural;
      Is_Max : Boolean) return Float;

   function Expectimax
     (G     : CGrid;
      Depth : Natural;
      Is_Max : Boolean) return Float
   is
      Dirs : constant array (1 .. 4) of Direction_E :=
        (Up, Down, Left, Right);
   begin
      if Depth = 0 then
         return Eval (G);
      end if;

      if Is_Max then
         declare
            Best : Float := -1.0e10;
         begin
            for D of Dirs loop
               declare
                  Test_Grid : CGrid := G;
               begin
                  if Test_Grid.Can_Move (D) then
                     declare
                        Next  : CGrid := G;
                        Trace : Trace_Grid_T;
                        Val   : Float;
                     begin
                        Trace := Next.Move (D);
                        Val := Expectimax (Next, Depth - 1, False);
                        if Val > Best then
                           Best := Val;
                        end if;
                     end;
                  end if;
               end;
            end loop;
            return Best;
         end;
      else
         --  Chance node: average over possible tile spawns
         declare
            Sum   : Float := 0.0;
            Count : Natural := 0;
         begin
            for Y in Size loop
               for X in Size loop
                  if G.Get (X, Y) = 0 then
                     for Val in 1 .. 2 loop
                        declare
                           Next : CGrid := G;
                        begin
                           Next.Set (X, Y, Val);
                           Sum := Sum + Expectimax (Next, Depth - 1, True);
                           Count := Count + 1;
                        end;
                     end loop;
                  end if;
               end loop;
            end loop;
            if Count = 0 then
               return Eval (G);
            else
               return Sum / Float (Count);
            end if;
         end;
      end if;
   end Expectimax;

   function Next_Move (G : CGrid) return Move_Type is
      Dirs : constant array (1 .. 4) of Direction_E :=
        (Up, Down, Left, Right);
      Best_Dir : Move_Type := None;
      Best_Val : Float := -1.0e10;
   begin
      for D of Dirs loop
         declare
            Test_Grid : CGrid := G;
         begin
            if Test_Grid.Can_Move (D) then
               declare
                  Next  : CGrid := G;
                  Trace : Trace_Grid_T;
                  Val   : Float;
               begin
                  Trace := Next.Move (D);
                  Val := Expectimax (Next, Max_Depth, False);
                  if Val > Best_Val then
                     Best_Val := Val;
                     case D is
                        when Up    => Best_Dir := Up;
                        when Down  => Best_Dir := Down;
                        when Left  => Best_Dir := Left;
                        when Right => Best_Dir := Right;
                     end case;
                  end if;
               end;
            end if;
         end;
      end loop;
      return Best_Dir;
   end Next_Move;

end Solver;
