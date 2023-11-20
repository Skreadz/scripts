#!/bin/bash

## Script deviner un chiffre entre 1 et 100 ##

number=$((RANDOM % 100 + 1))

while true
do
    read guess
 
    if [[ $guess -eq $number ]]; then
        echo "Bravo vous avez trouvé le chiffre : $number"
    break
    elif [[ $guess -lt $number ]]; then
        echo " le nombre est plus grand"
    else
        echo " le nombre est plus petit"
    fi
done