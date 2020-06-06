# Compilador para el lenguaje Tokke

## Tipos de datos

| Tipo | Ejemplo |
| -------- | --------- |
| int | int i = 4 |
| float | float f = 12.04f |
| double | double d = 12.04 |
| byte | byte b = 20b |
| boolean | boolean if = true |
| char | char word = 's' |

## Estructuras de datos

Actualmente, Tokke solo dispone de una estructura de datos:

| Estructura | Declaración | Acceso | Asignación | Notas adicionales |
| -------- | --------- | -------- | -------- | -------- |
| Array estático | type[] arr = [1,2,3,4,5,6] <br>o<br>  type[] arr = type[5] | arr[n] | arr[n] = a | Tiene capacidad multidimensional. Sólo puede ser de un tipo de datos |

## Operaciones

A continuación, mostramos el repertorio de operaciones compatibles del lenguaje:

### Asignación

    int e = 10

Se permiten casteos implícitos entre tipos de datos numéricos, manteniéndose siempre el tipo de la izquierda.

    int i = 10
    double e = i
    // La variable 'e' resulta en 10.0

### Matemáticas

El orden de cálculo es de izquierda a derecha, teniendo en cuenta la precedencia de los operandos en matemáticas: paréntesis, potencias, multiplicación, división, suma y resta.

#### Aritméticas

| Operaciones | Simbología |
| -------- | --------- |
| Suma, resta, multiplicación, división | +, -, *, / |
| Potencia | ^ |
| Módulo | % |
| Suma unitaria, resta unitaria | i++ o ++i, i-- o --i |
| Aritmética y asignación | i += 1, i -= 1, i *= 1, i/= 1 |
| Comparación | a > b, a >= b a != b, a == b |

Notas:

* Las comparaciones que se realizan entre valores numéricos, convirtiendo ambos valores al tipo de dato más grande.
* Las comparaciones entre string se puede realizar solamente con ==

#### Bit a bit

| Operación | Simbología |
| -------- | --------- |
| AND | a && b |
| OR | a || b |
| Negación | !a |
| Desplazamiento | a << 4, a >>  |

#### Booleanos

| Operación | Simbología |
| -------- | --------- |
| AND | a && b |
| OR | a || b |
| Negación | !a |

### Cadenas de caracteres

La concatenación se realiza con el símbolo '+'.

También es posible obtener "substrings" de la siguiente manera:

    char[] str = new char[n]
    str[0] = ‘c’
    str[1] = ‘a’
    str[2] = ‘n’
    str[3] = ‘o’
    str[4] = ‘n’

    str = splice(str, 0, 2) // Ahora str tiene un array con “can”

### Estructuras de control

#### For

    // Versión con índice
    for(int i = 0; i < 10; i++) {

    }

    // Versión para array
    for i in array {

    }

#### While

    while(exp){

    }

#### If - else

    if(exp) {

    } else if (exp) {

    } else {

    }

### Funciones

Las funciones solo aceptan paso de parámetros por valor.

    def type nombre ([type nombre1, (type nombre2, …)]) {

    }

### Funciones propias

    // Imprimir por la consola
    print(str)
    println(str)

    // Devuelve los elementos en un array
    size(arr)

    // Devuelve subarray de arr entre ini y fin, ambos inclusive.
    splice(arr, ini, fin)

### Estructura del programa

El programa se divide en 3 partes principales: la zona de variables globales, declaración de funciones y al final, la función main()

A modo de ejemplo:

    int a
    int b = 3

    def int suma(int a, float b) {
      return a + b
    }

    def int main() {
      a = 2
      print(suma(a + b))
      return 0
    }
