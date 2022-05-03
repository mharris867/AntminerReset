if (!(Test-Path .\PSCreds_${env:USERNAME}.xml)) {
    # look for stored credentials
    Write-Host "Unable to find: $(Get-Location)/PSCreds_${env:USERNAME}.xml"
    $creds = Get-Credential # credentials are usually "root" user and "root" password for Antminer
    $creds | Export-CliXml -Path ".\PSCreds_${env:USERNAME}.xml" # Store credentials
}
else {
    $creds = Import-CliXml -Path ".\PSCreds_${env:USERNAME}.xml" # Import Stored Credentials
}
if (!([bool]([Environment]::GetCommandLineArgs() -like '*-noninteractive*'))) {
    # Do not prompt for user input if in noninteractive mode
    $antminerIP = Read-Host -Prompt "Press enter to accept the default Antminer IP 192.168.2.27" # Prompt for Antminer IP
}
if ([string]::IsNullOrWhiteSpace($antminerIP)) { $antminerIP = "192.168.2.27" } # Set Antminer IP to default if not input from user

$loopforever = $true
While ($loopforever) {
    # Starting with a Ksols/S(RT) setting of 32 Ksols in the line below to trigger a restart. This might need tweeking. 
    # Thinking about using http://$antminerIP/cgi-bin/get_miner_conf.cgi to find the bitmain-freq and increase or reduce the Ksols threshold if necessary
    $minerconfig = Invoke-RestMethod http://$antminerIP/cgi-bin/get_miner_conf.cgi -Credential $creds -AllowUnencryptedAuthentication 
    if ((Invoke-RestMethod http://$antminerIP/cgi-bin/get_miner_status.cgi -Credential $creds -AllowUnencryptedAuthentication).summary.ghs5s -lt 32) {

        # Commented out the try catch block for a hard restart. Everything works but the Soft Reset is easier on power supply
        <# 
        try {
            Invoke-RestMethod http://$antminerIP/cgi-bin/reboot.cgi -Credential $creds -AllowUnencryptedAuthentication
        }
        Catch {
            if (($Error[0] -like "*500 - Internal Server Error*")) {
                Write-Warning "$(Get-Date) Lost connection to Antminer during restart and caused (500 - Internal Server Error). This is normal during reboot..." 
            }
            else {
                Write-Error "$(Get-Date) $($Error[0])"
            }
        } 
        #>
        
        #url encoded body for soft reset. This is the only encoding I could get to work so far.
        $body = "_ant_pool1url=$([uri]::EscapeDataString($minerconfig.pools.url[0]))&_ant_pool1user=$($minerconfig.pools.user[0])&_ant_pool1pw=$($minerconfig.pools.pass[0])&_ant_pool2url=$([uri]::EscapeDataString($minerconfig.pools.url[1]))&_ant_pool2user=$($minerconfig.pools.user[1])&_ant_pool2pw=$($minerconfig.pools.pass[1])&_ant_pool3url=$([uri]::EscapeDataString($minerconfig.pools.url[2]))&_ant_pool3user=$($minerconfig.pools.user[2])&_ant_pool3pw=$($minerconfig.pools.pass[2])&_ant_nobeeper=false&_ant_notempoverctrl=false&_ant_fan_customize_switch=false&_ant_fan_customize_value=&_ant_freq=$($minerconfig.'bitmain-freq')"
        Invoke-RestMethod http://$antminerIP/cgi-bin/set_miner_conf.cgi  -Credential $creds -AllowUnencryptedAuthentication -Method "POST" -Body $body -ContentType "application/x-www-form-urlencoded; charset=UTF-8" 
        Write-Host "$(Get-Date) Slow hash rate detected. Restarted Antminer" -ForegroundColor DarkRed 
    }
    Write-Host "$(Get-Date) Sleeping for 15min" -ForegroundColor DarkGreen 
    Start-Sleep -Seconds 900
}