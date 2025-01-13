# Su-Force
Su-Force es un script sencillo en bash para encontrar la contraseña de un usuario en un sistema Linux.
Este script tiene la cualidad de que se pueden trabajar con subprocesos, es decir, puedes probar mas contraseñas en menos tiempo, excelente si no quieres esperar mucho al usar un diccionario demasiado grande.

Para su ejecucion normal solo necesitas pasarle como primer argumento el nombre del usuario y como segundo argumento el diccionario:
```bash
bash suforce.sh username dictionary.txt
```

En caso de querer trabajar con los subprocesos, solo debes indicarle como tercer parametro cuantos subprocesos/hilos se ejecutaran, aumentando asi la velocidad:
```bash
bash suforce.sh username dictionary.txt 5
```
>**[!] Recomiendo no usar mas de 10 subprocesos ya que el programa puede dar falsos positivos.**
