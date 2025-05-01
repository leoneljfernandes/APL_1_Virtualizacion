#!/bin/bash

function ayuda() {
    echo "Bienvenido al script contador de palabras."
    echo "Debe especificar los siguientes argumentos:"
    echo "  -d, --directorio <directorio>   Especifica el directorio donde se contengan los archivos a analizar."
    echo "  -s, --salida                    Ruta del directorio donde se van a crear los backups."   
    echo "  -c, --cantidad                  Cantidad de archivos a ordenar antes de generar un backup."
    echo "  -k, --kill                      Flag que se utiliza para indicar que el script debe detener el demonio previamente iniciado."
    echo "  -h, --help                      Muestra esta ayuda."
}

function validarParametros(){

    
}