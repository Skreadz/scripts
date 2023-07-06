$csv = import-csv -path "C:\csv\listeutilisateurs.csv"
foreach ($line in $csv)
{
#Definition variables avec collecte infos dans CSV
$name = $line.NOM
$prenom = $line.PRENOM
$nameuser = $line.NOMUTILISATEUR
$password = $line.PASSWORD
$group = $line.GROUPE


#Ajout nouvelle utilisateur dans AD
New-ADuser `
-SamAccountName $nameuser `
-UserPrincipalName $nameuser `
-Name $name `
-GivenName $prenom `
-Enable $true `
-ChangePasswordAtLogon $true `
-Path "OU=Bureau,DC=serv24,DC=local" `
-AccountPassword (convertto-securestring $password -asplaintext -force)

#Ajout utilisateur a un groupe
Add-ADGroupMember -Identity $group -Members $nameuser

#Ajout script a un utilisateur
Set-ADUser -Identity $nameuser -ScriptPath C:\Users\Administrateur\Documents\Scripts\lecteur.bat

#Ajout dossier partagé a un utilisateur avec controle total
New-item d:\partages\$nameuser -ItemType Directory
New-SmbShare -Name $nameuser -Path D:\partages\$nameuser -FullAccess $nameuser
net user $nameuser /time:Lundi-Vendredi,08:00-18:00
}



$liste = Import-Csv -Path "/liste.csv" -Delimiter ";" -Encoding UTF8
$cheminbase = "c:\temp"

ForEach-Object ($line in $liste) {
    $nomdossier = $line.nom.toUpper()
    $chemindossier = Join-Path -Path $cheminbase -ChildPath $nomdossier

    if (-not (Test-Path $chemindossier)) {
        mkdir c:\temp\$nomdossier
    }
    else {
        Write-Host "le dossier existe deja"
    }
}


New-ADUser -Name "test" -Enable $true -ChangePasswordAtLogon $true -Path "OU=VENTE,OU=UTILISATEURS,OU=SQLI,DC=zouz,DC=local" -Verbose -AccountPassword (convertto-securestring "Azerty1+" -asplaintext -force)