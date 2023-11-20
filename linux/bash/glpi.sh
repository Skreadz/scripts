#!/bin/bash

glpi () {
   echo 'en codage'
}
 
 
echo "#######################   Faites votre choix   ########################"
echo "  1)installation GLPI"
 
 
read n
case $n in
  1) glpi;;
  *) echo "invalid option";;
esac