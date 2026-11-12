# Respuestas: punto 2

Autor: Tomás Avendaño Parra

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

Porque se usó projection, con el que Athena calcula las particiones al momento de consultar con las reglas de la tabla, como rango, formato, intervalo y plantilla de ruta, por lo que no las busca en el catálogo.

## 2. Si se subiera un archivo para el 4 de octubre manteniendo la configuración actual, ¿qué resultado se esperaría y qué se debería modificar para incluirlo?

Athena no lo proyectaría y no leería la carpeta ya que el 4 de octubre está fuera de rango. Por esto no daría error siquiera, simplemente no aparecerían las filas.
