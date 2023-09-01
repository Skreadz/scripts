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

    Write-Host "1 : Creation VM Windows Server Core 2022"
    Write-Host "2 : Creation VM Windows Server GUI 2022"
    Write-Host "3 : Ajout disk virtuel SCSI 4GB bdo sysvol logs"
    Write-Host "4 : Delete VMS"
    Write-Host "Q : Quitter"
    $choix = Read-Host "votre choix "
    switch ($choix) {
        1 {win19core;pause;menu} #### Fonction win19core >> fonction pause >> menu
        2 {win19gui;pause;menu}
        3 {3disksup;pause;menu}
        4 {delete_vms;pause;menu}
        Q {exit}
        Default {menu}   
}
}

function win19core () #### Fonction Création de VM WIN19CORE
{
    $pathvm = "C:\vm"
    $nomvm = Read-Host "Saisir nom de la vm"
    $ram = Read-Host "Saisir ram en GB"
    $switch = Read-Host "Saisir nom vswitch"
    #$switch_type = Read-Host "Saisir type vswitch (external,internal,private)"
    
    $memory = Invoke-Expression $ram

    New-Item -ItemType Directory -Name $nomvm -Path $pathvm
    Copy-Item -Path "C:\sysprep\WIN19CORE.vhdx" -Destination $pathvm\$nomvm\$nomvm.vhdx

    #New-VMSwitch -Name $switch -SwitchType $switch_type
    New-VM -Name $nomvm -MemoryStartupBytes $memory -Path "C:\vm" -Generation 1 -Switch $switch
    Add-VMHardDiskDrive -VMName $nomvm -Path $pathvm\$nomvm\$nomvm.vhdx
    Set-VM -Name $nomvm -ProcessorCount 2
    Set-VM -Name $nomvm -CheckpointType Disabled
    Start-VM $nomvm
}
function win19gui () #### Fonction Création de VM WIN19GUI
{
    $pathvm = "C:\vm"
    $nomvm = Read-Host "Saisir nom de la vm"
    $ram = Read-Host "Saisir ram en GB"
    $switch = Read-Host "Saisir nom vswitch"
    $memory = Invoke-Expression $ram

    New-Item -ItemType Directory -Name $nomvm -Path $pathvm
    Copy-Item -Path "C:\sysprep\WIN19GUI.vhdx" -Destination $pathvm\$nomvm\$nomvm.vhdx


    New-VM -Name $nomvm -MemoryStartupBytes $memory -Path "C:\vm" -Generation 1 -Switch $switch
    Add-VMHardDiskDrive -VMName $nomvm -Path $pathvm\$nomvm\$nomvm.vhdx
    Set-VM -Name $nomvm -ProcessorCount 2
    Set-VM -Name $nomvm -CheckpointType Disabled
    Start-VM $nomvm
}

function 3disksup ()        #### Fonction Création + Ajout 3 disk SCSI sur une VM au choix
{
    Get-VM | Select-Object Name | Format-Table
    $vm = Read-Host "Choix VM "
    $pathvm = "C:\vm"

    New-VHD -Path $pathvm\$vm\bdo.vhdx -SizeBytes 4196MB
    New-VHD -Path $pathvm\$vm\sysvol.vhdx -SizeBytes 4196MB
    New-VHD -Path $pathvm\$vm\logs.vhdx -SizeBytes 4196MB

    Add-VMHardDiskDrive -VMName $vm -ControllerType SCSI -Path $pathvm\$vm\bdo.vhdx
    Add-VMHardDiskDrive -VMName $vm -ControllerType SCSI -Path $pathvm\$vm\sysvol.vhdx
    Add-VMHardDiskDrive -VMName $vm -ControllerType SCSI -Path $pathvm\$vm\logs.vhdx
}

function delete_vms {       #### Fonction delete VMS

    Get-VM | Select-Object Name | Format-Table
    $nomvm = Read-Host "Saisir nom de la vm"
    $pathvm = "C:\vm"

    Stop-VM -Name $nomvm -Force
    Remove-VM -Name $nomvm -Force
    Remove-Item -Recurse -Force $pathvm\$nomvm
}
menu
