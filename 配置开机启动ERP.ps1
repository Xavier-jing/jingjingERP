$ErrorActionPreference = 'Stop'
$taskName = 'JshERP-AutoStart'
$launcher = Join-Path $PSScriptRoot '自动启动ERP.ps1'
$powershell = Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
$arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $launcher + '"'
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask -and ($existingTask.Actions.Execute -ne $powershell -or $existingTask.Actions.Arguments -ne $arguments)) {
    throw '同名计划任务指向其他程序，请先核对，未覆盖。'
}
$action = New-ScheduledTaskAction -Execute $powershell -Argument $arguments -WorkingDirectory $PSScriptRoot
$trigger = New-ScheduledTaskTrigger -AtStartup
$trigger.Delay = 'PT30S'
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description '开机30秒后后台启动本机 ERP：MySQL、Redis、后端及前端。日志：.quality-local/autostart.log。' -Force | Out-Null
Export-ScheduledTask -TaskName $taskName | Set-Content -LiteralPath (Join-Path $PSScriptRoot '.quality-local/autostart-task.xml') -Encoding UTF8
Write-Output ('已配置开机启动任务：' + $taskName)
