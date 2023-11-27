#!/bin/bash
for port in {1..65536};
do  
    nc -zvw1 $1 $port &>/dev/null ### Annule la sortie de commande ###
        if [ $? -eq 0 ]; ### Récupère la valeur de la dernière commande ###
        then    
            echo "Port $port is open"
        fi
done
