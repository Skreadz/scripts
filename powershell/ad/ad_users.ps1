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
    Write-Host "4 : Création des utilisateurs"
    Write-Host "5 : ACL dossier PERSO"
    Write-Host "6 : ACL dossier SERVICES"
    Write-Host "Q : Quitter"
    $choix = Read-Host "votre choix "
    switch ($choix) {
        1 {ou_principale;pause;menu}
        2 {groupe;pause;menu}
        3 {dossier;pause;menu}
        4 {user;pause;menu}
        5 {acl_user;pause;menu}
        6 {acl_services;pause;menu}
        Q {exit}
        Default {menu}   
}
}

function ou_principale () {         #### Fonction pour créer OU principale ex: SQLI + IMPRIMANTES,GROUPES,UTILISATEURS,ORDINATEURS,SERVEURS
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
function groupe () {        #### Fonction pour créer les groupes GG,GU,GDL en fonction des services du CSV

    $cheminbase = (Get-Addomain).distinguishedname
    $ou_principale = Read-Host "Saisir OU principale"
    $cheminouprincipale = "OU=$ou_principale,$cheminbase"
    $chemingroupe = "OU=GROUPES,"+$cheminouprincipale
    $csv = import-csv -path "C:\Users\Administrateur\Documents\user.csv" -Delimiter ";" -Encoding UTF8
    foreach ($line in $csv) {
        $group = $line.group.toUpper()      #### Récupère la section group du CSV en plus de l'écrire en majuscules
        $GG="GG_"+$group
        $GU="GU_"+$group
        $GDL="GDL_"+$group+"_RW"
 
    New-ADGroup -GroupCategory Security -GroupScope Global -Name $GG -Path $chemingroupe -Verbose
                
    New-ADGroup -GroupCategory Security -GroupScope Global -Name $GU -Path $chemingroupe -Verbose
                 
    New-ADGroup -GroupCategory Security -GroupScope Global -Name $GDL -Path $chemingroupe -Verbose

    Add-ADGroupMember -Identity $GU -Members  $GG -Verbose
    Add-ADGroupMember -Identity $GDL -Members  $GU -Verbose
           
    }
}

function dossier () {           #### Fonction pour créer les dossiers perso users + dossier de services sur le serveur \\SRV-SF1\partage
    $cheminservices = "\\SRV-SF1\partage\SERVICES\"
    $cheminperso = "\\SRV-SF1\partage\PERSO\"
    $csv = import-csv -path "C:\Users\Administrateur\Documents\user.csv" -Delimiter ";" -Encoding UTF8
    foreach ($line in $csv) {
        $group = $line.ou.toUpper()
        $sam = $line.prenom.toLower()+"."+$line.nom.toLower()
        $chemintest = $cheminservices+$group
        $existe = Test-Path -Path $chemintest
        if (!$existe) {     #### Test si le chemin existe sinon il ne lance pas la commande
            New-Item -ItemType Directory -Name $group -Path $cheminservices -Verbose
            }
        New-Item -ItemType Directory -Name $sam -Path $cheminperso -Verbose
    }
}

function user {         #### Fonction pour créer utilisateur

    $cheminbase = (Get-Addomain).distinguishedname
    $ou_principale = Read-Host "Saisir OU principale"
    $cheminouprincipale = "OU=$ou_principale,$cheminbase"
    $cheminuser = "OU=UTILISATEURS,"+$cheminouprincipale
    $csv = import-csv -path "C:\Users\Administrateur\Documents\user.csv" -Delimiter ";" -Encoding UTF8

    foreach ($line in $csv) {
    $sam = $line.prenom.toLower()+"."+$line.nom.toLower()
    $upn = $sam+"@"+$env:USERDNSDOMAIN.toLower()
    $mail = $upn
    $group = $line.ou.toUpper()
    $cheminuser = "OU="+$group+",OU=UTILISATEURS,"+$cheminouprincipale
    $prenom = $line.prenom.toLower()
    $nom = $line.nom.toLower()

    New-ADUser -Name $nom -GivenName $prenom -Surname $nom -SamAccountName $sam -UserPrincipalName $upn -EmailAddress $mail -Enable $true -ChangePasswordAtLogon $true -Path $cheminuser -Verbose -AccountPassword (convertto-securestring "Azerty1+" -asplaintext -force)
    }
}

function acl_user {

    $csv = import-csv -path "C:\Users\Administrateur\Documents\user.csv" -Delimiter ";" -Encoding UTF8
    foreach ($line in $csv) {
        $sam = $line.prenom.toLower()+"."+$line.nom.toLower()
        $service = "\\SRV-SF1\partage\PERSO\"+$sam
        $group = $line.group.toUpper()      #### Récupère la section group du CSV en plus de l'écrire en majuscules
        $GG="GG_"+$group

        Add-ADGroupMember -Identity $GG -Members $sam

        $acl = Get-Acl -Path $service
        $rule = New-Object Security.AccessControl.FileSystemAccessRule("$sam", "Modify" ,"ContainerInherit, ObjectInherit","None","Allow")
        $acl.SetAccessRuleProtection($true,$true)
        $acl.addAccessRule($rule) #ajout de la régle

        $acl | Set-Acl #Appliquer les droits
        }
}

function acl_services {

    $csv = import-csv -path "C:\Users\Administrateur\Documents\user.csv" -Delimiter ";" -Encoding UTF8
    foreach ($line in $csv) {

        $ou = $line.ou.toUpper() 
        $service = "\\SRV-SF1\partage\SERVICES\"+$ou
        $group = $line.group.toUpper()                  #### Récupère la section group du CSV en plus de l'écrire en majuscules
        $GDL="GDL_"+$group+"_RW"

        $acl = Get-Acl -Path $service
        $rule = New-Object Security.AccessControl.FileSystemAccessRule("$GDL", "Modify" ,"ContainerInherit, ObjectInherit","None","Allow")
        $acl.SetAccessRuleProtection($true,$true)
        $acl.addAccessRule($rule) #ajout de la régle

        $acl | Set-Acl #Appliquer les droits
    }
}
menu
