function pause ($message="Appuyer sur touche pour continuer") 
{
    Write-Host -NoNewline $message
    $null = $Host.UI.RawUI.ReadKey("noecho,includeKeydown")    #### Fonction Pause
    Write-Host ""    
}

function menu () #### Fonction Menu
{
    Clear-Host
    Write-Host "Menu Script"

    Write-Host "1 : Création OU principale"
    Write-Host "2 : Création groupe"
    Write-Host "3 : Création dossier partages"
    Write-Host "Q : Quitter"
    $choix = Read-Host "votre choix "
    switch ($choix) {
        1 {ou_principale;pause;menu}
        2 {groupe;pause;menu}
        3 {dossier;pause;menu}
        Q {exit}
        Default {menu}   
}
}

function ou_principale () {
    $cheminbase = (Get-Addomain).distinguishedname
    $ou_principale = Read-Host "Saisir OU principale"

    New-ADOrganizationalUnit -Name $ou_principale -Path $cheminbase
    $cheminouprincipale = "OU=$ou_principale,$cheminbase"
    $ou_default = @("IMPRIMANTES","GROUPES","UTILISATEURS","ORDINATEURS","SERVEURS")

    ForEach ($line in $ou_default) {
    New-ADOrganizationalUnit -Name $line -Path $cheminouprincipale -Verbose -ProtectedFromAccidentalDeletion:$false
    }

    $csv = Import-Csv -Path "C:\Users\Administrateur\Documents\user.csv" -Delimiter ";" -Encoding UTF8
    $cheminuser = "OU=UTILISATEURS,"+$cheminouprincipale

    ForEach ($line in $csv) {
    $ou_user = $line.ou.toUpper()
    New-ADOrganizationalUnit -Name $ou_user -Path $cheminuser -Verbose -ProtectedFromAccidentalDeletion:$false     
    }
}
function groupe () {

    $cheminbase = (Get-Addomain).distinguishedname
    $ou_principale = Read-Host "Saisir OU principale"
    $cheminouprincipale = "OU=$ou_principale,$cheminbase"
    $chemingroupe = "OU=GROUPES,"+$cheminouprincipale
    $csv = import-csv -path "C:\Users\Administrateur\Documents\user.csv" -Delimiter ";" -Encoding UTF8
    foreach ($line in $csv) {
        $group = $line.group.toUpper()
        $GG="GG_"+$group
        $GU="GU_"+$group
        $GDL="GDL_"+$group+"_RW"
 
    New-ADGroup -GroupCategory Security -GroupScope Global -Name $GG -Path $chemingroupe -Verbose
                
    New-ADGroup -GroupCategory Security -GroupScope Global -Name $GU -Path $chemingroupe -Verbose
                 
    New-ADGroup -GroupCategory Security -GroupScope Global -Name $GDL -Path $chemingroupe -Verbose
           
    }
}

function dossier () {
    $cheminservices = "\\SRV-SF1\partage$\SERVICES\"
    $cheminperso = "\\SRV-SF1\partage$\PERSO\"
    $csv = import-csv -path "C:\Users\Administrateur\Documents\user.csv" -Delimiter ";" -Encoding UTF8
    foreach ($line in $csv) {
        $group = $line.ou.toUpper()
        $sam = $line.prenom.toLower()+"."+$line.nom.toLower()
        $chemintest = $cheminservices+$group
        #$existe = Test-Path -Path $chemintest
        #if (!$existe) {
            New-Item -ItemType Directory -Name $group -Path $cheminservices -Verbose
            #}
        New-Item -ItemType Directory -Name $sam -Path $cheminperso -Verbose
    }
}
menu
