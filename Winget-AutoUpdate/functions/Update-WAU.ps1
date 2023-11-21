#Function to update WAU

function Update-WAU {

    $OnClickAction = "https://github.com/Romanitho/Winget-AutoUpdate/releases"
    $Button1Text = $NotifLocale.local.outputs.output[10].message

    #Send available update notification
    $Title = $NotifLocale.local.outputs.output[2].title -f "Winget-AutoUpdate"
    $Message = $NotifLocale.local.outputs.output[2].message -f $WAUCurrentVersion, $WAUAvailableVersion
    $MessageType = "info"
    Start-NotifTask -Title $Title -Message $Message -MessageType $MessageType -Button1Action $OnClickAction -Button1Text $Button1Text

    #Run WAU update
    try {

        #Force to create a zip file
        $ZipFile = "$env:TEMP\WAU_update.zip"
        New-Item $ZipFile -ItemType File -Force | Out-Null

        #Download the zip
        Write-ToLog "Downloading the GitHub Repository version $WAUAvailableVersion" "Cyan"
        Invoke-RestMethod -Uri "https://github.com/Romanitho/Winget-AutoUpdate/releases/download/v$($WAUAvailableVersion)/WAU.zip" -OutFile $ZipFile

        #Extract Zip File
        Write-ToLog "Unzipping the WAU Update package" "Cyan"
        $location = "$env:TEMP\WAU_update"
        Expand-Archive -Path $ZipFile -DestinationPath $location -Force
        Get-ChildItem -Path $location -Recurse | Unblock-File

        #Run installer for update
        Write-ToLog "Updating WAU..." "Yellow"
        Start-Process powershell -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$location\winget-upgrade.ps1`" -Update"

        #Set Post Update actions to 1
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Winget-AutoUpdate" -Name "WAU_PostUpdateActions" -Value 1 -Force | Out-Null

        exit

    }

    catch {

        #Send Error Notif
        $Title = $NotifLocale.local.outputs.output[4].title -f "Winget-AutoUpdate"
        $Message = $NotifLocale.local.outputs.output[4].message
        $MessageType = "error"
        Start-NotifTask -Title $Title -Message $Message -MessageType $MessageType -Button1Action $OnClickAction -Button1Text $Button1Text
        Write-ToLog "WAU Update failed" "Red"

    }

}