function ou_principale {
    $cheminbase = (Get-Addomain).distinguishedname
    $ou_principale = Read-Host "Saisir OU principale"

    New-ADOrganizationalUnit -Name $ou_principale -Path $cheminbase
    $cheminouprincipale = "OU="+$cheminouprincipale+","+$cheminbase
    $ou_default = @("IMPRIMANTES","GROUPES","USERS","ORDINATEURS","SERVEURS")

    ForEach ($line in $ou_default) 
        {
        New-ADOrganizationalUnit -Name $line -Path $cheminouprincipale
        }
}
    

