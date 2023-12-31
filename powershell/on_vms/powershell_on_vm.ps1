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

    Write-Host "1 : Config IP + Nom Serveur"
    Write-Host "2 : Install ADDS main server + 3DISK (sysvol,logs,bdd)"
    Write-Host "3 : Config DNS Propre"
    Write-Host "4 : Création zone inversée"
    Write-Host "5 : Role DHCP + Etendue"
    Write-Host "6 : Installe AD en réplication + 3DISK (sysvol,logs,bdd)"
    Write-Host "7 : Installe Rôle serveur de fichier"
    Write-Host "8 : Installe DFS main server (2ads répliqué nécessaire + 2serveurs de fichiers dans le domaine)"
    Write-Host "9 : Réplication de fichiers sur AD principale"
    Write-Host "Q : Quitter"
    $choix = Read-Host "votre choix "
    switch ($choix) {
        1 {ip;pause;menu} #### Fonction ad >> fonction pause >> menu
        2 {ad;pause;menu}
        3 {dns;pause;menu}
        4 {zone_inverse;pause;menu}
        5 {dhcp;pause;menu}
        6 {ad_join;pause;menu}
        7 {server_fichier;pause;menu}
        8 {dfs_main_server;pause;menu}
        9 {replication;pause;menu}
        Q {exit}
        Default {menu}   
}
}

function ad {
    Get-Disk
    $diskbdd = Read-Host "Selectionner un disque pour la bdd"
    $disksysvol = Read-Host "Selectionner un disque pour sysvol"
    $disklogs = Read-Host "Selectionner un disque pour les logs"
    $domain = Read-Host "Saisir le nom de domaine"
    $netbios = Read-Host "Saisir le nom NETBIOS"

    Initialize-Disk -Number $diskbdd                                                        #### DISK SYSVOL LOGS DATA
    New-Partition -DiskNumber $diskbdd -DriveLetter B -Size 4GB
    Format-Volume -DriveLetter B -FileSystem NTFS -Confirm:$false -NewFileSystemLabel BDD

    Initialize-Disk -Number $disksysvol
    New-Partition -DiskNumber $disksysvol -DriveLetter S -Size 4GB
    Format-Volume -DriveLetter S -FileSystem NTFS -Confirm:$false -NewFileSystemLabel SYSVOL

    Initialize-Disk -Number $disklogs
    New-Partition -DiskNumber $disklogs -DriveLetter L -Size 4GB
    Format-Volume -DriveLetter L -FileSystem NTFS -Confirm:$false -NewFileSystemLabel LOGS

    Add-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -IncludeAllSubFeature #### AJOUT ROLE AD

    Import-Module ADDSDeployment #### PROMOUVOIR SERVEUR EN CONTROLEUR DE DOMAINE + CREATION FORET
    Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "B:\NTDS" `
    -DomainMode "WinThreshold" `
    -DomainName "$domain" `
    -DomainNetbiosName "$netbios" `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -LogPath "L:\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "S:\SYSVOL" `
    -Force:$true

    Restart-Computer
}

function ip {           #### Fonction changement ip address + rename computer
 
    Get-NetIPConfiguration
    $index = Read-Host "Saisir Index Interface"
    $ipv4 = Read-Host "Saisir IP"
    $mask = Read-Host "Saisir masque de sous-réseau CIDR"
    $gateway = Read-Host "Saisir gateway"
    $dns = Read-Host "Saisir DNS"
    $name = Read-Host "Saisir nom serveur"

    Remove-NetRoute -InterfaceIndex $index -Confirm:$false
    Remove-NetIPAddress -InterfaceIndex $index -Confirm:$false
    New-NetIPAddress –InterfaceIndex $index –IPAddress $ipv4 –PrefixLength $mask –DefaultGateway $gateway
    Set-DnsClientServerAddress -InterfaceIndex $index -ServerAddresses $dns
    Get-NetIPConfiguration

    Rename-Computer -NewName $name
    Restart-Computer
}
function dns {              #### Fonction désactiver écoute dns IPV6 + ajout du serveur dns

    Get-NetIPConfiguration
    $index = Read-Host "Saisir Index Interface"
    $dns = (Get-NetIPAddress -InterfaceIndex $index -AddressFamily IPv4).IPAddress

    Get-DnsClientServerAddress -InterfaceIndex $index -AddressFamily IPv6 | Set-DnsClientServerAddress -ResetServerAddresses
    Set-DnsClientServerAddress -InterfaceIndex $index -ServerAddresses $dns
    nslookup
    pause
}

function zone_inverse {     #### Fonction création zone inversée
    $reseau = Read-Host "Saisir réseau (ex: 192.168.1.0/24)"  

    Add-DnsServerPrimaryZone -NetworkID $reseau -ReplicationScope Domain -DynamicUpdate Secure
    ipconfig /registerdns
}

function dhcp {             #### Fonction rôles DHCP + étendue avec option

    Get-NetIPConfiguration
    $index = Read-Host "Saisir Index Interface"
    $servername = (Get-ADDomain).InfrastructureMaster
    $etenduname = Read-Host "Saisir nom etendue DHCP"
    $stetendu = Read-Host "Saisir début étendue"
    $endetendu = Read-Host "Saisir fin étendue"
    $subnet = Read-Host "Saisir masque (255.255.255.0)"
    $gateway = Read-Host "Saisir Gateway"
    $domain = (Get-ADDomain).DNSRoot
    $dns = (Get-DnsClientServerAddress -InterfaceIndex $index -AddressFamily IPv4).ServerAddresses

    Install-WindowsFeature DHCP -IncludeManagementTools
    Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2  #### Désactiver confirmation d'installe dhcp
    
    Add-DHCPServerInDC -DNSName $servername
    Set-DhcpServerv4OptionValue -DNSServer $dns -DNSDomain $domain -Router $gateway #### Option d'étendue
    Add-DhcpServerv4Scope -Name $etenduname -StartRange $stetendu -EndRange $endetendu -SubnetMask $subnet -Description "Plage DHCP des ordinateurs du domaine $domain" #### Etendue
}

function ad_join {
    Get-Disk
    $diskbdd = Read-Host "Selectionner un disque pour la bdd"
    $disksysvol = Read-Host "Selectionner un disque pour sysvol"
    $disklogs = Read-Host "Selectionner un disque pour les logs"
    $domain = Read-Host "Saisir le nom de domaine"
    #$netbios = Read-Host "Saisir le nom NETBIOS"
    $fqdn = Read-Host "Saisir FQDN du serveur principale"
    $admindomaine = "$domain\administrateur"

    Initialize-Disk -Number $diskbdd                                                        #### DISK SYSVOL LOGS DATA
    New-Partition -DiskNumber $diskbdd -DriveLetter B -Size 4GB
    Format-Volume -DriveLetter B -FileSystem NTFS -Confirm:$false -NewFileSystemLabel BDD

    Initialize-Disk -Number $disksysvol
    New-Partition -DiskNumber $disksysvol -DriveLetter S -Size 4GB
    Format-Volume -DriveLetter S -FileSystem NTFS -Confirm:$false -NewFileSystemLabel SYSVOL

    Initialize-Disk -Number $disklogs
    New-Partition -DiskNumber $disklogs -DriveLetter L -Size 4GB
    Format-Volume -DriveLetter L -FileSystem NTFS -Confirm:$false -NewFileSystemLabel LOGS

    Add-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -IncludeAllSubFeature #### AJOUT ROLE AD
    Get-WindowsFeature FS-DFS* | Install-WindowsFeature -IncludeManagementTools               #### AJOUR ROLE SERVEUR DE FICHIER
    Install-WindowsFeature FS-BranchCache -IncludeManagementTools
    
    New-Item -Path "C:\partage" -itemType Directory
    New-SmbShare -Name "partage" -Path "C:\partage"

    Import-module ADDSDeployment            #### Ajout AD dans forêt existante
    $ForestConfiguration = @{
    '-DatabasePath'           = 'B:\BDD';
    '-DomainName'             = $domain;
    '-InstallDns'             = $true;
    '-LogPath'                = 'L:\LOGS';
    '-NoRebootOnCompletion'   = $false;
    '-SysvolPath'             = 'S:\SYSVOL';
    '-Force'                  = $true;
    '-CreateDnsDelegation'    = $false;
    '-NoGlobalCatalog'        = $false;
    '-ReplicationSourceDC'    = $fqdn;
    '-CriticalReplicationOnly'= $false;
    '-SiteName'               = "Default-First-Site-Name";
    '-Credential'             = (Get-Credential $admindomaine)
    }
    Install-ADDSDomainController @ForestConfiguration
}

function server_fichier {
    Clear-Host
    Write-Host "Menu Serveur de fichier"

    Write-Host "1 : Install Rôles serveur de fichier"
    Write-Host "2 : Création dossier partage\COMMUN;partage\PERSO;\partage\SERVICES"

    $choix = Read-Host "votre choix "
    switch ($choix) {
        1 {role} #### Fonction ad >> fonction pause >> menu
        2 {folder}
        Q {exit}
        Default {menu}   
}
}
    function role {             #### Fonction installe rôles serveur de fichier + réplication + ajout au domaine
        $domain = Read-host "Saisir nom de domaine"
        $admindomain = "Administrateur@$domain"

        Install-WindowsFeature FS-BranchCache -IncludeManagementTools
        Install-WindowsFeature FS-DFS-Replication
        Add-Computer -DomainName $domain  -Credential (Get-Credential $admindomain) -Restart
    }
    function folder {           #### Fonction création smbshare partage$ + création 3 dossier COMMUN,PERSO,SERVICES
        $lecteur = Read-Host "Saisir lettre disque où créer les dossier de partages"
        New-Item -Path $lecteur":\partage" -itemType Directory
        New-SmbShare -Name "partage" -Path $lecteur":\partage"
        New-Item -Path $lecteur":\partage\COMMUN" -ItemType Directory
        New-Item -Path $lecteur":\partage\PERSO" -ItemType Directory
        New-Item -Path $lecteur":\partage\SERVICES" -ItemType Directory
    }

function dfs_main_server {

    $domain = Read-Host "Saisir nom de domaine"
    $ad1 = Read-Host "Saisir serveur AD1"
    $ad2 = Read-Host "Saisir serveur AD2"
    $sf1 = Read-Host "Saisir Serveur de fichier 1"
    $sf2 = Read-Host "Saisir Serveur de fichier 2"
    Get-WindowsFeature FS-DFS* | Install-WindowsFeature -IncludeManagementTools             #### Rôle espace de noms et réplication
    Install-WindowsFeature FS-BranchCache -IncludeManagementTools

    New-Item -Path "C:\partage" -itemType Directory
    New-SmbShare -Name "partage" -Path "C:\partage"

    #Enter-PSSession $ad2                                                                    #### Connexion powershell sur ad2

    #Get-WindowsFeature FS-DFS* | Install-WindowsFeature -IncludeManagementTools
    #Install-WindowsFeature FS-BranchCache -IncludeManagementTools
    
    N#ew-Item -Path "C:\partage" -itemType Directory
    #New-SmbShare -Name "partage" -Path "C:\partage"

    #Exit-PSSession

    New-DfsnRoot -Path "\\$domain\partage" -Type DomainV2 -TargetPath "\\$ad1\partage"      #### Création espace de nom sur serveur ad1 et ad2
    New-DfsnRoot -Path "\\$domain\partage" -Type DomainV2 -TargetPath "\\$ad2\partage"

    New-DfsnFolder -Path "\\$domain\partage\COMMUN" -TargetPath "\\$sf1\partage\COMMUN" -EnableTargetFailback $true -Description 'Folder for legacy software.'         #### ajout des dossier COMMUN,PERSO,SERVICES sur 2 serveurs de fichiers sf1 et sf2
    New-DfsnFolderTarget -Path "\\$domain\partage\COMMUN" -TargetPath "\\$sf2\partage\COMMUN"
    New-DfsnFolder -Path "\\$domain\partage\PERSO" -TargetPath "\\$sf1\partage\PERSO" -EnableTargetFailback $true -Description 'Folder for legacy software.'
    New-DfsnFolderTarget -Path "\\$domain\partage\PERSO" -TargetPath "\\$sf2\partage\PERSO"
    New-DfsnFolder -Path "\\$domain\partage\SERVICES" -TargetPath "\\$sf1\partage\SERVICES" -EnableTargetFailback $true -Description 'Folder for legacy software.'
    New-DfsnFolderTarget -Path "\$domain\partage\SERVICES" -TargetPath "\\$sf2\partage\SERVICES"
}

function replication {          #### Fonction réplication de fichiers
    $serv1 = Read-host "Saisir le nom DNS du premier serveur de fichier"
    $lettre1 = Read-host "Saisir la lettre du lecteur du premier serveur de fichier"
    $serv2 = Read-host "Saisir le nom DNS du deuxieme serveur de fichier"
    $lettre2 = Read-host "Saisir la lettre du lecteur du deuxieme serveur de fichier"

    New-DfsReplicationGroup -GroupName "COMMUN"
    Add-DfsrMember -GroupName "COMMUN" -ComputerName $serv1,$serv2
    Add-DfsrConnection -GroupName "COMMUN" -SourceComputerName $serv1 -DestinationComputerName $serv2
    New-DfsReplicatedFolder -GroupName "COMMUN" -FolderName "COMMUN"
    Set-DfsrMembership -GroupName "COMMUN" -FolderName "COMMUN" -ContentPath $lettre1":\COMMUN" -ComputerName $serv1 -PrimaryMember $True -Force
    Set-DfsrMembership -GroupName "COMMUN" -FolderName "COMMUN" -ContentPath $lettre2":\COMMUN" -ComputerName $serv2 -Force

    New-DfsReplicationGroup -GroupName "PERSO"
    Add-DfsrMember -GroupName "PERSO" -ComputerName $serv1,$serv2
    Add-DfsrConnection -GroupName "PERSO" -SourceComputerName $serv1 -DestinationComputerName $serv2
    New-DfsReplicatedFolder -GroupName "PERSO" -FolderName "PERSO"
    Set-DfsrMembership -GroupName "PERSO" -FolderName "PERSO" -ContentPath $lettre1":\PERSO" -ComputerName $serv1 -PrimaryMember $True -Force
    Set-DfsrMembership -GroupName "PERSO" -FolderName "PERSO" -ContentPath $lettre2":\PERSO" -ComputerName $serv2 -Force

    New-DfsReplicationGroup -GroupName "SERVICES"
    Add-DfsrMember -GroupName "SERVICES" -ComputerName $serv1,$serv2
    Add-DfsrConnection -GroupName "SERVICES" -SourceComputerName $serv1 -DestinationComputerName $serv2
    New-DfsReplicatedFolder -GroupName "SERVICES" -FolderName "SERVICES"
    Set-DfsrMembership -GroupName "SERVICES" -FolderName "SERVICES" -ContentPath $lettre1":\SERVICES" -ComputerName $serv1 -PrimaryMember $True -Force
    Set-DfsrMembership -GroupName "SERVICES" -FolderName "SERVICES" -ContentPath $lettre2":\SERVICES" -ComputerName $serv2 -Force
}
menu