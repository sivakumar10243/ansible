$innosetup = 'faveoagent.exe'
$api = '"https://agentsw.faveodemo.com"'
$clientid = '1'
$siteid = '1'
$assetTypeId = 34
$power = 0
$rdp = 0
$ping = 0
$auth = '"2v373lQ5O1jKHH4x8o0I7K9OUaoTRIRsdT3exnHDg7nlmtDVEsfTI4YRbIwi"'
$downloadlink = 'https://agentsw.faveodemo.com/api/agent/download/?platform=windows&architecture=amd64'
$apilink = $downloadlink.split('/')
$noMesh = 0
$noZoho = 1

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$serviceName = 'faveoagent'
$service = Get-Service $serviceName -ErrorAction SilentlyContinue
    Write-Host "Downloading the agent..."

if ($service) {
    $uninstallerPath = "C:\Program Files\FaveoAgent\unins000.exe"
    Start-Process -FilePath $uninstallerPath -ArgumentList "/VERYSILENT", "/SILENT", "/SUPPRESSMESSAGEBOXES", "/SUPPRESSMSGBOXES", "/uninstall", "/quiet", "/norestart" -WindowStyle Hidden -Wait
}
$OutPath = $env:TMP
$output = $innosetup

$installArgs = @('-m install --api ', "$api", '--client-id', $clientid, '--site-id', $siteid, '-asset_type_id', "$assetTypeId", '--auth', "$auth")

if ($power) {
    $installArgs += "--power"
}

if ($rdp) {
    $installArgs += "--rdp"
}

if ($ping) {
    $installArgs += "--ping"
}

if ($noMesh) {
   $installArgs += "--nomesh"
}

if ($noZoho) {
   $installArgs += "-with_zoho=0"
} else {
   $installArgs += "-with_zoho=1"
}

Try
{
    $DefenderStatus = Get-MpComputerStatus | select  AntivirusEnabled
    if ($DefenderStatus -match "True") {
        Add-MpPreference -ExclusionPath 'C:\Program Files\FaveoAgent\*'
        Add-MpPreference -ExclusionPath 'C:\ProgramData\FaveoAgent\*'
    }
}
Catch {
    # pass
}

$X = 0
do {
  Write-Output "Waiting for network"
  Start-Sleep -s 5
  $X += 1
} until(($connectresult = Test-NetConnection $apilink[2] -Port 443 | ? { $_.TcpTestSucceeded }) -or $X -eq 3)

if ($connectresult.TcpTestSucceeded -eq $true){
    Try
    {
        Add-MpPreference -ExclusionPath $OutPath
        Invoke-WebRequest -Uri $downloadlink -OutFile $OutPath\$output
        Start-Process -FilePath $OutPath\$output -ArgumentList ('/VERYSILENT /SUPPRESSMSGBOXES') -Wait
        write-host ('Extracting...')
        Start-Sleep -s 5
        Start-Process -FilePath "C:\Program Files\FaveoAgent\faveoagent.exe" -ArgumentList $installArgs -Wait
        exit 0
    }
    Catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Error -Message "$ErrorMessage $FailedItem"
        exit 1
    }
    Finally
    {
        Remove-Item -Path $OutPath\$output
    }
} else {
    Write-Output "Unable to connect to server"
}