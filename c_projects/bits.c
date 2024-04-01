/* 
 * CS:APP Data Lab 
 * 
 * <Please put your name and userid here>
 * <name: Can Erozer, userid: U40104182>
 * 
 * bits.c - Source file with your solutions to the Lab.
 *          This is the file you will hand in to your instructor.
 *
 * WARNING: Do not include the <stdio.h> header; it confuses the dlc
 * compiler. You can still use printf for debugging without including
 * <stdio.h>, although you might get a compiler warning. In general,
 * it's not good practice to ignore compiler warnings, but in this
 * case it's OK.  
 */

#if 0
/*
 * Instructions to Students:
 *
 * STEP 1: Read the following instructions carefully.
 */

You will provide your solution to the Data Lab by
editing the collection of functions in this source file.

INTEGER CODING RULES:
 
  Replace the "return" statement in each function with one
  or more lines of C code that implements the function. Your code 
  must conform to the following style:
 
  int Funct(arg1, arg2, ...) {
      /* brief description of how your implementation works */
      int var1 = Expr1;
      ...
      int varM = ExprM;

      varJ = ExprJ;
      ...
      varN = ExprN;
      return ExprR;
  }

  Each "Expr" is an expression using ONLY the following:
  1. Integer constants 0 through 255 (0xFF), inclusive. You are
      not allowed to use big constants such as 0xffffffff.
  2. Function arguments and local variables (no global variables).
  3. Unary integer operations ! ~
  4. Binary integer operations & ^ | + << >>
    
  Some of the problems restrict the set of allowed operators even further.
  Each "Expr" may consist of multiple operators. You are not restricted to
  one operator per line.

  You are expressly forbidden to:
  1. Use any control constructs such as if, do, while, for, switch, etc.
  2. Define or use any macros.
  3. Define any additional functions in this file.
  4. Call any functions.
  5. Use any other operations, such as &&, ||, -, or ?:
  6. Use any form of casting.
  7. Use any data type other than int.  This implies that you
     cannot use arrays, structs, or unions.

 
  You may assume that your machine:
  1. Uses 2s complement, 32-bit representations of integers.
  2. Performs right shifts arithmetically.
  3. Has unpredictable behavior when shifting an integer by more
     than the word size.

EXAMPLES OF ACCEPTABLE CODING STYLE:
  /*
   * pow2plus1 - returns 2^x + 1, where 0 <= x <= 31
   */
  int pow2plus1(int x) {
     /* exploit ability of shifts to compute powers of 2 */
     return (1 << x) + 1;
  }

  /*
   * pow2plus4 - returns 2^x + 4, where 0 <= x <= 31
   */
  int pow2plus4(int x) {
     /* exploit ability of shifts to compute powers of 2 */
     int result = (1 << x);
     result += 4;
     return result;
  }

FLOATING POINT CODING RULES

For the problems that require you to implent floating-point operations,
the coding rules are less strict.  You are allowed to use looping and
conditional control.  You are allowed to use both ints and unsigneds.
You can use arbitrary integer and unsigned constants.

You are expressly forbidden to:
  1. Define or use any macros.
  2. Define any additional functions in this file.
  3. Call any functions.
  4. Use any form of casting.
  5. Use any data type other than int or unsigned.  This means that you
     cannot use arrays, structs, or unions.
  6. Use any floating point data types, operations, or constants.


NOTES:
  1. Use the dlc (data lab checker) compiler (described in the handout) to 
     check the legality of your solutions.
  2. Each function has a maximum number of operators (! ~ & ^ | + << >>)
     that you are allowed to use for your implementation of the function. 
     The max operator count is checked by dlc. Note that '=' is not 
     counted; you may use as many of these as you want without penalty.
  3. Use the btest test harness to check your functions for correctness.
  4. Use the BDD checker to formally verify your functions
  5. The maximum number of ops for each function is given in the
     header comment for each function. If there are any inconsistencies 
     between the maximum ops in the writeup and in this file, consider
     this file the authoritative source.

/*
 * STEP 2: Modify the following functions according the coding rules.
 * 
 *   IMPORTANT. TO AVOID GRADING SURPRISES:
 *   1. Use the dlc compiler to check that your solutions conform
 *      to the coding rules.
 *   2. Use the BDD checker to formally verify that your solutions produce 
 *      the correct answers.
 */


#endif
/* Copyright (C) 1991-2012 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <http://www.gnu.org/licenses/>.  */
/* This header is separate from features.h so that the compiler can
   include it implicitly at the start of every compilation.  It must
   not itself include <features.h> or any other header that includes
   <features.h> because the implicit include comes before any feature
   test macros that may be defined in a source file before it first
   explicitly includes a system header.  GCC knows the name of this
   header in order to preinclude it.  */
/* We do support the IEC 559 math functionality, real and complex.  */
/* wchar_t uses ISO/IEC 10646 (2nd ed., published 2011-03-15) /
   Unicode 6.0.  */
/* We do not support C11 <threads.h>.  */
// Rating: 1
/* 
 * bitNor - return ~(x|y) using only ~ and & 
 *   Example: bitNor(0x6, 0x5) = 0xFFFFFFF8
 *   Legal ops: ~ &
 *   Max ops: 8
 *   Rating: 1
 */
int bitNor(int x, int y)
{
  // Due to the DeMorgan's Law, we can write ~(x|y) as (~x & ~y)
  return (~x & ~y) ;
}
/* 
 * tmin - return minimum two's complement integer 
 *   Legal ops: ! ~ & ^ | + << >>
 *   Max ops: 4
 *   Rating: 1
 */
int tmin(void)
{
  //two's complement minimum number can be found with the formula: -2^(w-1) where w is the bit number.
  //since we are restricted with some operations, we have to use operations other than ^(power operation)
  // and -
  //Therefore for appropiate soltion, two's complement minimum number in binary is 100000.....0
  int min= ~(0x0) << 31;
  return min;
}

// Rating: 2
/* 
 * byteSwap - swaps the nth byte and the mth byte
 *  Examples: byteSwap(0x12345678, 1, 3) = 0x56341278
 *            byteSwap(0xDEADBEEF, 0, 2) = 0xDEEFBEAD
 *  You may assume that 0 <= n <= 3, 0 <= m <= 3
 *  Legal ops: ! ~ & ^ | + << >>
 *  Max ops: 25
 *  Rating: 2
 */
int byteSwap(int x, int n, int m) {
    // In order to swap the bytes, first we need to shift the nth and mth byte
    // to the first byte location in order to be able to manipulate them.
    int nn=n<<3; //(gives n*2^3, the number of shifts needed to shift nth byte to the 0th byte position)
    int mm=m<<3; //(gives m*2^3, the number of shifts needed to shift mth byte to the 0th byte position)
    // the power of 2 is 3 because we are shifting the bytes. Since number >> 1 or number << 1 shifts 1 bits, we need to
    // multiply with 8 (1 byte--> 8 bit).

    int shift_nth_byte= x>>nn;
    int shift_mth_byte= x>>mm;
    //now the nth and mth byte are in the 0 th byte position

    //but if n and m are not 3, there are other bytes in the front of the 0th byte position.
    //in order to convert the bytes to 0 (other than 0th byte), we need to make masking.
    //The only way to do that is masking it with AND 0Xff
    int shift_nnth_byte= shift_nth_byte & 0xff;
    int shift_mmth_byte= shift_mth_byte & 0xff;

    //Before we swap the bytes we need to clear the nth and mth positions of x (convert to 0).
    //I will do this with XORing the byte positions with itself (masking operation with XOR). 
    int cleared_nth= x^(shift_nnth_byte<<nn); //clearing the nth byte position of x
    int cleared_mth= x^(shift_mmth_byte<<mm); //clearing the mth byte position of x

    // nth and mth positions together cleared
    int cleared=cleared_nth & cleared_mth;

    //finially, we have to insert nth byte to mth byte position and mth byte to nth byte position
    int xx= cleared | (shift_nnth_byte<<mm); // insert nth byte to mth byte position
     

    return xx | (shift_mmth_byte<<nn); // insert mth byte to nth byte position
}
// Rating: 3
/* 
 * bitMask - Generate a mask consisting of all 1's 
 *   lowbit and highbit
 *   Examples: bitMask(5,3) = 0x38
 *   Assume 0 <= lowbit <= 31, and 0 <= highbit <= 31
 *   If lowbit > highbit, then mask should be all 0's
 *   Legal ops: ! ~ & ^ | + << >>
 *   Max ops: 16
 *   Rating: 3
 */
int bitMask(int highbit, int lowbit) {
  // ~(0x0) (32 bits of ones) is shifted leftwards value of the lowbit times
  //in order to set the how many zeros will be in front of first one bit (lowbit th bit).
  int lowbit_shift= ~(0x0) << lowbit;
  // + 1 is added to highbit since the first position of the 32-bit is 0. 
  int num_shift= highbit +1;
  int highbit_shift = ~(0x0) << num_shift;
  int hhighbit_shift= ~(highbit_shift);
  //the interseciton of 1's in the lowbit_shift and highbit_shift will give our result
  //if lowbit > highbit there won't be any interseciton of 1's so result will be all 0's
  return lowbit_shift & hhighbit_shift;
}
/* 
 * isGreater - if x > y  then return 1, else return 0 
 *   Example: isGreater(4,5) = 0, isGreater(5,4) = 1
 *   Legal ops: ! ~ & ^ | + << >>
 *   Max ops: 24
 *   Rating: 3
 */
int isGreater(int x, int y)
{
  // In order to check x>y we have to partition the question:

  //1) First and the easiest check is whether x and y have opposite signs or not.
  //If x has positive value and y has negative value, the funciton returns 1 otherwise 0...
  //To check that it is sufficient to look at the MSB of x and y.
  //I will use MSB of ~x & y to check that

  int check_x= x>>31;
  int check_y= y>>31;
  int ccheck_x=!(!(check_x));
  int ccheck_y=!(!(check_y));
  int is_negative= ~(ccheck_x) & ccheck_y;

  //2) Second one is using the + operator. I will subtract y from x. If x is bigger than y the result will be
  //always positive. Conversely if y is bigger than x the result will be always negative.
  //The exact value after subtraction is not important. It is sufficient to look at the MSB of the result.
  //Since we cannot use the - operator, I can only use x - y = x + (~(y)+1).
  // But this condition is only valid if they are both positive or both negative. So I have to check whether
  //they have the same sign.

  int subtraction= x + (~(y)+1);
  int ssubtraction= subtraction>>31;
  int sssubtraction= !(!(ssubtraction));
  int check= (ccheck_x) ^ (ccheck_y);
  int check1= !(check) & !(sssubtraction);

  //3) Third one is checking whether they x and y hold the same value. 
  int is_sameval= x ^ y;
  int iis_sameval= !(!(is_sameval));


  return is_negative | (check1 & iis_sameval);
}

/* 
 * isPositive - return 1 if x > 0, return 0 otherwise 
 *   Example: isPositive(-1) = 0.
 *   Legal ops: ! ~ & ^ | + << >>
 *   Max ops: 8
 *   Rating: 3
 */
int isPositive(int x)
{
  //If the MSB of x is 1 then the function will return 0 and if the MSB of x is 0 then the function will return 1.
  //But this doesn't check whether x is zero or not. 
  int result= !(x>>31);
  int is_zero= !(!(x));

  

  return result & is_zero;
}
/* 
 * addOK - Determine if can compute x+y without overflow
 *   Example: addOK(0x80000000,0x80000000) = 0,
 *            addOK(0x80000000,0x70000000) = 1, 
 *   Legal ops: ! ~ & ^ | + << >>
 *   Max ops: 20
 *   Rating: 3
 */
int addOK(int x, int y) {
  //There are three different cases that we should look for:
  //1) The signs of x and y are both positive.
  //2) The signs are different.
  //3) The signs are both negative.

  //I will start with case 2: If the signs are different there are no way that the sums will cause
  // an overflow. To check that, I will XOR the MSB of x and y.

  int x_msb=!(!(x>>31));
  int y_msb=!(!(y>>31));
  int dif_sign= x_msb ^ y_msb;

  //Case 1 and 3: If x and y are both positive but the result of their sum is not positive, then overflow occured. 
  //And vice versa, if x and y are both positive.
  //In order to check this I will look at the MSB of and x and y and their sum.

  int sum_msb= x+y;
  int ssum_msb= !(!(sum_msb>>31));
  int check_sign= x_msb & y_msb;
  int check= check_sign ^ ssum_msb;
  int ccheck = !(check);

  
  return ccheck | dif_sign;
}
/*
 * bitParity - returns 1 if x contains an odd number of 0's
 *   Examples: bitParity(5) = 0, bitParity(7) = 1
 *   Legal ops: ! ~ & ^ | + << >>
 *   Max ops: 20
 *   Rating: 4
 */
int bitParity(int x)
{
  /*The approach I used: the number of 0's can be only detected if we XOR the each bit in the binary number.
  For example, say user passed 5 to the parameter. Then we have (0101). If we XOR the each bit:
  (((0th bit XOR 1rd bit) XOR 2nd bit) XOR 3rd bit) = (((1 XOR 0) XOR 1) XOR 0) = 0.
  This algorithm successfully returns true value. However, we are dealing with 32 bit numbers which requires 
  me to use 31 XOR operation as well as 31 >> operation. This number (31 +31 =62 > 20) exceeds the maximum
  operation allowed in the question. Therefore, more efficient algorithm is needed.
  Instead of XORing every bit, we can continuously divide 32-bit binary number to 2 until we get 1 at the end and
  XOR each equal parts.
  To explain this idea: since we don't have an iterator, we cannot keep track of the number of 0 bits.
  Instead we can use the property of XOR. If there are even number 0's and 1's XORing the bit will yield 0 since 
  0 XOR 0 =0  and 1 XOR 1=0. But if there odd number of 0's and 1's the the result will be 1.  */

  // I started with 16 because we need to compare two equal parts of x.
  // We must continue to divide 32 to 2 until we cannot divide x. 
  int result = x ^ (x>>16);
  int rresult= result ^ (result>>8);
  int rrresult= rresult ^ (rresult>>4);
  int rrrresult= rrresult ^ (rrresult>>2);
  int rrrrresult= rrrresult ^ (rrrresult>>1);
  
  //result is now a binary number. we need to get the rightmost value with AND masking. 
  

  return rrrrresult & 1;
}
