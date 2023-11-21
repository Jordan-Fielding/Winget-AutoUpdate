#Function to make actions after WAU update

function Invoke-PostUpdateActions {

    #log
    Write-ToLog "Running Post Update actions:" "yellow"

    # Check if Intune Management Extension Logs folder and WAU-updates.log exists, make symlink
    if ((Test-Path -Path "${env:ProgramData}\Microsoft\IntuneManagementExtension\Logs" -ErrorAction SilentlyContinue) -and !(Test-Path -Path "${env:ProgramData}\Microsoft\IntuneManagementExtension\Logs\WAU-updates.log" -ErrorAction SilentlyContinue)) {
        Write-ToLog "-> Creating SymLink for log file (WAU-updates) in Intune Management Extension log folder" "yellow"
        $null = New-Item -Path "${env:ProgramData}\Microsoft\IntuneManagementExtension\Logs\WAU-updates.log" -ItemType SymbolicLink -Value $LogFile -Force -ErrorAction SilentlyContinue
    }

    # Check if Intune Management Extension Logs folder and WAU-install.log exists, make symlink
    if ((Test-Path -Path "${env:ProgramData}\Microsoft\IntuneManagementExtension\Logs" -ErrorAction SilentlyContinue) -and (Test-Path -Path ('{0}\logs\install.log' -f $WorkingDir) -ErrorAction SilentlyContinue) -and !(Test-Path -Path "${env:ProgramData}\Microsoft\IntuneManagementExtension\Logs\WAU-install.log" -ErrorAction SilentlyContinue)) {
        Write-ToLog "-> Creating SymLink for log file (WAU-install) in Intune Management Extension log folder" "yellow"
        $null = (New-Item -Path "${env:ProgramData}\Microsoft\IntuneManagementExtension\Logs\WAU-install.log" -ItemType SymbolicLink -Value ('{0}\logs\install.log' -f $WorkingDir) -Force -Confirm:$False -ErrorAction SilentlyContinue)
    }

    #Set GPO scheduled task if not existing
    $GPOTask = Get-ScheduledTask -TaskName 'Winget-AutoUpdate-Policies' -ErrorAction SilentlyContinue
    if (!$GPOTask) {
        $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$($WorkingDir)\WAU-Policies.ps1`""
        $tasktrigger = New-ScheduledTaskTrigger -Daily -At 6am
        $taskUserPrincipal = New-ScheduledTaskPrincipal -UserId S-1-5-18 -RunLevel Highest
        $taskSettings = New-ScheduledTaskSettingsSet -Compatibility Win8 -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 00:05:00
        # Set up the task, and register it
        $task = New-ScheduledTask -Action $taskAction -Principal $taskUserPrincipal -Settings $taskSettings -Trigger $taskTrigger
        Register-ScheduledTask -TaskName 'Winget-AutoUpdate-Policies' -TaskPath 'WAU' -InputObject $task -Force | Out-Null
        Write-ToLog "-> Policies task created."
    }

    #Remove update zip file and update temp folder
    Write-ToLog "Cleaning WAU Update temp files..."
    Remove-Item -Path "$env:TEMP\WAU_update.zip" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:TEMP\WAU_update" -Recurse -Force -ErrorAction SilentlyContinue


    ### End of post update actions ###

    #Send success Notif
    Write-ToLog "WAU Update completed." "Green"
    $Title = $NotifLocale.local.outputs.output[3].title -f "Winget-AutoUpdate"
    $Message = $NotifLocale.local.outputs.output[3].message -f $WAUAvailableVersion
    $MessageType = "success"
    Start-NotifTask -Title $Title -Message $Message -MessageType $MessageType -Button1Action $OnClickAction -Button1Text $Button1Text

    #Reset WAU_UpdatePostActions Value
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Winget-AutoUpdate" -Name "WAU_PostUpdateActions" -Value 0 -Force | Out-Null

    #Get updated WAU Config
    $Script:WAUConfig = Get-WAUConfig

    #log
    Write-ToLog "Post Update actions finished" "green"

}
