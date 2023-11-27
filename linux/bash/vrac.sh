#!/bin/sh

echo "test"
echo $1 $2 $3 ### ajout de variable a la volée quand on lance la commande ./script.sh var1 var2 var3 ###
echo $$ ### connaitre le PID du script pour par exemple kill le script ###

### condition if ###
if [[ $1 ="john" && $2 = "wick" ]]
then
    echo "votre prénom est $1 et votre nom est $2"
else
    echo "vous n'est pas celui la"
fi
######

### mysql auto ###
sudo apt install -y mysql-server mysql-client

sudo mysql -e "CREATE DATABASE $1 CHARACTER SET UTF8 COLLATE UTF8_BIN"
sudo mysql -e "CREATE USER '$2'@'%' IDENTIFIED BY '$3';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $1.* TO '$2'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"
#######

### boucle ###
for num in {10..30..5};
do 
echo $num;
done

### while ###
while [ -z $answer ] || [ $answer != 'yes' ]
do
    read -p 'do you want enter ? > ' answer
done
echo "Welcome !"

### MENU ###

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

### Skip le screen rose (redemerrage auto des daemons après MAJ) ###
sudo vi /etc/needrestart/needrestart.conf
#$nrconf{restart} = 'i'; >> $nrconf{restart} = 'a';
