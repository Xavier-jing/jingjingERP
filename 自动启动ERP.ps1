$ErrorActionPreference = 'Stop'
$result = 0
$transcriptStarted = $false
try {
    Start-Transcript -Path (Join-Path $PSScriptRoot '.quality-local/autostart.log') -Append | Out-Null
    $transcriptStarted = $true
    & (Join-Path $PSScriptRoot '启动ERP.ps1')
}
catch {
    Write-Output ('ERP 自动启动失败：' + $_.Exception.Message)
    $result = 1
}
finally {
    if ($transcriptStarted) { Stop-Transcript | Out-Null }
}
exit $result
