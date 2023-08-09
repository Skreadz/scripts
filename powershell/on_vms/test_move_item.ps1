ForEach ($line in $csv) {

$ou_user = $line.ou.toUpper()

if ($ou_user =  DIRECTEUR) {
    Move-ADObject -Identity $cheminclass -TargetPath $cheminoudirecteur
}
elseif ($ou_user = ENSEIGNANT) {
    Move-ADObject -Identity $cheminclass -TargetPath $cheminouenseignant
}
else {
    Write-Output Pas besoin de déplacer
}
}