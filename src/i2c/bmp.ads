with BMP390;
with Board;

package BMP is new BMP390 (Bus => Board.I2C_1);