param(
    [string]$RuntimeRoot = (Join-Path $PSScriptRoot '.local-runtime/runtime')
)
$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$localRoot = Join-Path $projectRoot '.quality-local'
if (!(Test-Path -LiteralPath "$localRoot/application-local.yml") -or !(Test-Path -LiteralPath "$localRoot/redis.conf")) {
    throw '缺少本机运行配置，请按 quality-transfer-guide.md 配置后启动。'
}
$java = (Get-ChildItem "$RuntimeRoot/jdk" -Directory | Select-Object -First 1).FullName + '/bin/java.exe'
$mysqlRoot = (Get-ChildItem "$RuntimeRoot/mysql" -Directory | Select-Object -First 1).FullName
$node = Join-Path $RuntimeRoot 'node/node.exe'
function Start-LocalComponent($name, $port, $executable, $arguments, $directory) {
    $client = [Net.Sockets.TcpClient]::new()
    try { $client.Connect('127.0.0.1', $port); Write-Host "$name 已在端口 $port 运行"; return }
    catch { }
    finally { $client.Dispose() }
    $process = Start-Process -FilePath $executable -ArgumentList $arguments -WorkingDirectory $directory -WindowStyle Hidden -RedirectStandardOutput "$localRoot/$name.log" -RedirectStandardError "$localRoot/$name-error.log" -PassThru
    $process.Id | Set-Content "$localRoot/$name.pid"
    for ($attempt=0; $attempt -lt 60; $attempt++) {
        if ($process.HasExited) { throw "$name 启动失败，请查看 $localRoot/$name-error.log" }
        $probe = [Net.Sockets.TcpClient]::new()
        try { $probe.Connect('127.0.0.1', $port); Write-Host "$name 已就绪，端口 $port"; return }
        catch { }
        finally { $probe.Dispose() }
        Start-Sleep -Seconds 1
    }
    throw "$name 未在60秒内就绪，请查看 $localRoot/$name.log"
}
Start-LocalComponent 'mysql' 13306 "$mysqlRoot/bin/mysqld.exe" @('--no-defaults',"--basedir=$mysqlRoot","--datadir=$RuntimeRoot/mysql-data",'--port=13306','--bind-address=127.0.0.1','--mysqlx=OFF','--console') $projectRoot
Start-LocalComponent 'redis' 16379 "$RuntimeRoot/redis-option1/tools/redis-server.exe" @("$localRoot/redis.conf") $projectRoot
Start-LocalComponent 'backend' 9999 $java @('-Xms256m','-Xmx768m','-jar',"$projectRoot/jshERP-boot/target/jshERP.jar",'--spring.profiles.active=local',"--spring.config.additional-location=file:$($localRoot.Replace('\','/'))/") "$projectRoot/jshERP-boot"
$env:NODE_OPTIONS = '--openssl-legacy-provider'
Start-LocalComponent 'frontend' 3000 $node @('--openssl-legacy-provider',"$projectRoot/jshERP-web/node_modules/@vue/cli-service/bin/vue-cli-service.js",'serve','--host','127.0.0.1','--port','3000') "$projectRoot/jshERP-web"
Write-Host '服务首次启动需要等待编译就绪，访问 http://127.0.0.1:3000 。日志在 .quality-local。'
