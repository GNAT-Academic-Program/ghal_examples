with Grid; use Grid;

package Solver is
   type Move_Type is (Up, Down, Left, Right, None);
   function Next_Move (G : CGrid) return Move_Type;
end Solver;
