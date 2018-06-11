#
#  https://stackoverflow.com/a/48030563
#  https://stackoverflow.com/a/37763324
#  https://n3wjack.net/2013/04/22/using-a-web-client-in-powershell/
#  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-6
#
#declare functions
#
function PokeBackIn
  {
    param (
      [Parameter()]
      $portlist = @(20,21,22,23,25,42,53,67,68,69,80,110,119,123,135,137,138,139,143,161,162,389,443,445,636,873,993,995,1433,3306,3389,5800,5900),

      [parameter()]
      [int32]$sleep = 5
    )

    #
    #  https://stackoverflow.com/a/48030563
    #  https://stackoverflow.com/a/37763324
    #  https://n3wjack.net/2013/04/22/using-a-web-client-in-powershell/
    #
    #declare functions
    #

    #create variables
    #[int32]$sleep = 5
    #$portList = 20,21,22,23,25,42,53,67,68,69,80,110,119,123,135,137,138,139,143,161,162,389,443,445,636,873,993,995,1433,3306,3389,5800,5900
    $userAgents = [Microsoft.PowerShell.Commands.PSUserAgent].GetProperties() | Select-Object Name, @{n='UserAgent';e={ [Microsoft.PowerShell.Commands.PSUserAgent]::$($_.Name) }}
    $jsonResult = @{}
    $portError = @{}

    # Clear Terminal
    Clear-Host
    #
    # Allowed TLS/SSL Methods in Order of Attempt
    [Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"
    #
    # Get the web content.
    for($i=1;$i -le $portList.Count; $i++){
      try{
        $Sleep = ($sleep - ($sleep/10))
        $randomAgent = $userAgents[(Get-Random -Minimum 0 -Maximum ($userAgents.count-1))]
        Write-Host "Probing Port "$($portList[$i-1])" with UserAgent $($randomAgent.Name) in $sleep seconds..."
        Start-Sleep $Sleep
        $jsonResult[$i-1] = Invoke-WebRequest -Uri "https://ifconfig.co/port/$($portList[$i-1])" -UserAgent $randomAgent  #-ErrorVariable ErrorBody -ErrorAction Stop
        $jsonResult[$i-1].content
        Write-Output ""
      }
      catch{
        $sleep = $sleep+5
        Write-Warning "HTTP $_. Response when probing port $($portList[$i-1])"
        Write-Warning "Throttling request timing."
        Write-Host ""

        try{
            $randomAgent = $userAgents[(Get-Random -Minimum 0 -Maximum ($userAgents.count-1))]
            Write-Host "Retrying Port "$($portList[$i-1])" in $sleep seconds..."
            Start-Sleep $sleep
            $jsonResult[$i-1] = Invoke-WebRequest -Uri "https://ifconfig.co/port/$($portList[$i-1])" -UserAgent $randomAgent  #-ErrorVariable ErrorBody -ErrorAction Stop
            $jsonResult[$i-1].content
            Write-Output ""
        }
        catch{
          Write-Warning "Skipping Port $($portList[$i-1]): Too Much Fail."
          #Write-Warning "Http $_. Response when probing port $($portList[$i-1])"
          $portError[$i-1] = $portList[$i-1]
        }
      }
    }
    #
    # Output Ports that are reachable from the outside.
    Write-Output ""
    Write-Output "The following ports are reachable:"
    $i=0
    $openPorts=@{}
    Foreach ($content in ($jsonResult.values)){
      if($content.content.Contains('true')){
      $openPorts[$i] = $content.content
      Write-Output $content.Content
      }
    }
    #
    # List ports that failed to test
    if ($portError.values -eq $true){
    Write-Output "", "Unable to test the following ports: "($portError.Values)
    }
}
