#include "Q.h"
BEGIN
L 0: 	R7=0x12000;
	GT(1); // salta a main 
L 1: // definicion de funcion main
	R7=R7-4; // reserva espacio para variable i
	R7=R7-4;
	I(R7)=0; // asigna constante a pila 
	R1=0x11ffc;
	R2=I(R7);
	I(R1)=R2;
	R7=R7+4; // asignacion variable i 
	L 2:
	R1=0x11ffc;
	R7=R7-4;
	R2=I(R1);
	I(R7)=R2; // asignacion constante a pila 
	R7=R7-4;
	I(R7)=5; // asigna constante a pila 
	R0=I(R7+4);
	R1=I(R7);
	R0=R0<R1; // igual expresion
	R7=R7+4;
	U(R7)=R0; // guarda boolean en pila
	R0=U(R7);
	IF(!R0) GT(3); // for expresion
	R1=0x11ffc;
	R7=R7-4;
	R2=I(R1);
	I(R7)=R2; // asignacion constante a pila 
STAT(0)
	STR(0x11fee, "%d"); // espacio para digito
CODE(0)
	R1=0x11fee;
	R2=I(R7);
	R0=4; // direccion retorno
	R7=R7+4;
	GT(putf_);
L 4:
	R0 = I(0x11ffc); // Incremento for
	R0 = R0 + 1;
	I(0x11ffc) = R0;
	GT(2); // itera for
	L 3: // fin for
	GT(-2);
END
