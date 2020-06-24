// Qlib.h 3.7.1 - 3.7.3

// Fichero �nicamente de definiciones opcionales de macros.
// Est� permitido modificarlo, al igual que Qlib.c,
// debi�ndose entonces recompilar IQ (ver Qman.txt).
// Las macros aqu� definidas son utilizables en el c�digo Q
// y en Qlib.c, s�lo si inteprete y compilador de Q trabajan
// sobre la salida del preprocesador de C (cpp).


// Reconfiguraci�n de direcciones base de la m�quina Q (v�ase Q.h para
// valores por defecto).  Descomentar para activar.
// Deben cumplirse que H > Z > 0 y que ambos sean m�ltiplos de 4.
//#define H   0x00200000 // base+1 del heap (1 MB m�x hasta Z=0x00100000)
//#define Z   0x00100000 // base+1 de la zona est�tica m�s pila (1 MB m�x hasta 0x00000000)
//#define LLL -9999      // �ltima etiqueta admisible en Qlib; se debe cumplir LLL < -10


// Para el resto de nombres de macro, con el objeto de evitar posibles
// colisiones con las de Q.h, util�cese el car�cter '_'

// Si queremos usar estos nombres en lugar de sus valores num�ricos
#define __ini	 0    // comienzo
#define __brk    -1   // breakpoint "manual" en IQ
#define __fin    -2   // terminacion normal
#define __abo    -3   // terminacion anticipada

// Igualmente para funciones de Qlib; �sense s�lo etiquetas no superiores a -10
#define exit_    -10    // NOTA: a eliminar en futuras versiones, mantenido por compatibilidad
#define new_     -11    // asigna o libera espacio en heap
#define putf_    -12    // visualiza ristra y/o entero

// nuevo añadido para lenguaje tk
#define divz_    -13    // error division por cero
#define putd_    -14    // visualiza reales
