#include "Q.h"
# 1 "<stdin>"
# 1 "<interno>"
# 1 "<línea-de-órdenes>"
# 31 "<línea-de-órdenes>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 32 "<línea-de-órdenes>" 2
# 1 "<stdin>"
# 1 "Qlib.h" 1
# 2 "<stdin>" 2
BEGIN
L 0: R6 = R7;
 R7=R7-4;
 R7=R7-4;
 I(R7)=3;
 R1=0x11ffc;
 R2=I(R7);
 I(R1)=R2;
 R7=R7+4;
 R7=R7-4;
 R7=R7-4;
 I(R7)=7;
 R1=0x11ff8;
 R2=I(R7);
 I(R1)=R2;
 R7=R7+4;
 R7=R7-4;
 P(R7)=R6;
 R7=R7-4;
 P(R7)=-2;
 R0=R7;
 GT(1);
L 2: R6=R7;
 R7=R7-4;
 R1=P(R0+4);
 P(R6-4)=R1;
 R7=R7-4;
 R1=P(R0);
 P(R6-8)=R1;
 R0=R0+8;
 R7=R7-4;
 R7=R7-4;

 R1=I(R0);
 I(R6-16)=R1;
 R0=R0+4;
 R1=I(R0);
 I(R6-12)=R1;
 R0=R0+4;
 R1=R6-12;
 R7=R7-4;
 R2=I(R1);
 I(R7)=R2;
 R1=R6-16;
 R7=R7-4;
 R2=I(R1);
 I(R7)=R2;
 R0=I(R7+4);
 R1=I(R7);
 R0=R0+R1;
 R7=R7+4;
 I(R7)=R0;

 R0=I(R7);
 R7=R7+4;

 R5=P(R6-8);
 R7=R7+4;
 R1=P(R6-4);
 R7=R7+4;
 R7=R6;
 R6=R1;
 GT(R5);
 R5=P(R6-8);
 R7=R7+4;
 R1=P(R6-4);
 R7=R7+4;
 R7=R6;
 R6=R1;
 GT(R5);
L 3: R6=R7;
 R7=R7-4;
 R1=P(R0+4);
 P(R6-4)=R1;
 R7=R7-4;
 R1=P(R0);
 P(R6-8)=R1;
 R0=R0+8;
 R7=R7-4;
 R7=R7-4;

 R1=I(R0);
 I(R6-16)=R1;
 R0=R0+4;
 R1=I(R0);
 I(R6-12)=R1;
 R0=R0+4;
 R1=R6-12;
 R7=R7-4;
 R2=I(R1);
 I(R7)=R2;
 R1=R6-16;
 R7=R7-4;
 R2=I(R1);
 I(R7)=R2;
 R0=I(R7+4);
 R1=I(R7);
 R0=R0*R1;
 R7=R7+4;
 I(R7)=R0;

 R0=I(R7);
 R7=R7+4;

 R5=P(R6-8);
 R7=R7+4;
 R1=P(R6-4);
 R7=R7+4;
 R7=R6;
 R6=R1;
 GT(R5);
 R5=P(R6-8);
 R7=R7+4;
 R1=P(R6-4);
 R7=R7+4;
 R7=R6;
 R6=R1;
 GT(R5);
L 1: R6=R7;
 R7=R7-4;
 R1=P(R0+4);
 P(R6-4)=R1;
 R7=R7-4;
 R1=P(R0);
 P(R6-8)=R1;
 R0=R0+8;
 R7=R7-4;
 R7=R7-4;
 I(R7)=10;
 R1=R6-12;
 R2=I(R7);
 I(R1)=R2;
 R7=R7+4;
 R7=R7-4;
 R7=R7-4;
 I(R7)=7;
 R1=R6-16;
 R2=I(R7);
 I(R1)=R2;
 R7=R7+4;
 R1=0x11ffc;
 R7=R7-4;
 R2=I(R1);
 I(R7)=R2;
 R1=R6-12;
 R7=R7-4;
 R2=I(R1);
 I(R7)=R2;

 R7=R7-4;
 P(R7)=R6;
 R7=R7-4;
 P(R7)=4;
 R0=R7;
 GT(2);
L 4:

 R7=R7+4;
 R7=R7+4;
 R7=R7+4;
 R7=R7+4;
 R7=R7-4;
 I(R7)=R0;
 R1=0x11ff8;
 R7=R7-4;
 R2=I(R1);
 I(R7)=R2;
 R1=R6-16;
 R7=R7-4;
 R2=I(R1);
 I(R7)=R2;

 R7=R7-4;
 P(R7)=R6;
 R7=R7-4;
 P(R7)=5;
 R0=R7;
 GT(2);
L 5:

 R7=R7+4;
 R7=R7+4;
 R7=R7+4;
 R7=R7+4;
 R7=R7-4;
 I(R7)=R0;

 R7=R7-4;
 P(R7)=R6;
 R7=R7-4;
 P(R7)=6;
 R0=R7;
 GT(3);
L 6:

 R7=R7+4;
 R7=R7+4;
 R7=R7+4;
 R7=R7+4;
 R7=R7-4;
 I(R7)=R0;
STAT(0)
 STR(0x11ff0, "%d\n");
CODE(0)
 R1=0x11ff0;
 R2=I(R7);
 R7=R7+4;
 R0=7;
 GT(-12);
L 7:
 GT(-2);
END
