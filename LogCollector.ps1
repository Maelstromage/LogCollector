$folder = "\\$env:COMPUTERNAME\$PSScriptRoot" -replace(':','$')
$creds = Get-Credential
$comps = import-csv -Path "$PSScriptRoot\computers.csv"

write-host "Using folder $folder"



foreach ($comp in $comps.device){
    if(!(test-path "$PSScriptRoot\$comp")){new-item -Path $PSScriptRoot -ItemType directory -Name $comp}
    Invoke-Command -Credential $creds -ComputerName $comp -ArgumentList $folder,$comp,$creds -ScriptBlock {
        param($folder,$comp,$creds)
        New-PSDrive -name "homecomp" -Credential $creds -PSProvider "filesystem" -root "$folder\$comp"
        if(!(test-path "C:\temp")){new-item -path "C:\" -ItemType "directory" -name "Temp"}
        Copy-Item "c:\Windows\CCM\Logs" -Destination "homecomp:\" -Recurse
        Get-WindowsUpdateLog -LogPath "homecomp:\WindowsUpdate.log" 
        (Get-WmiObject -Class Win32_NTEventlogFile | Where-Object LogfileName -eq 'System').BackupEventlog("c:\temp\System.evtx")
        Move-Item "c:\temp\system.evtx" -Destination "homecomp:\"
        Remove-PSDrive -Name "homecomp"
    }
}

write-host "Hit enter to end"
read-host
