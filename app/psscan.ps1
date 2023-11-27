param(
  [Parameter(Position = 0)]
  [string[]]$hosts,

  [Parameter(Position = 1)]
  [int[]]$ports,

  [Parameter()]
  [switch]$UDP,

  [Parameter()]
  [switch]$Help
)

if (!$ports -Or $Help) {
Write-Host "   /###     /###     /###      /###      /###   ###  /###    "
Write-Host "  / ###  / / #### / / #### /  / ###  /  / ###  / ###/ #### /  "
Write-Host " /   ###/ ##  ###/ ##  ###/  /   ###/  /   ###/   ##   ###/   {1.4.0#stable}"
Write-Host "##    ## ####     ####      ##        ##    ##    ##    ##    "
Write-Host "##    ##   ###      ###     ##        ##    ##    ##    ##    "
Write-Host "##    ##     ###      ###   ##        ##    ##    ##    ##    "
Write-Host "##    ##       ###      ### ##        ##    ##    ##    ##    "
Write-Host "##    ##  /###  ## /###  ## ###     / ##    /#    ##    ##    "
Write-Host "#######  / #### / / #### /   ######/   ####/ ##   ###   ###  "
Write-Host "######      ###/     ###/     #####     ###   ##   ###   ### "
Write-Host "##                                                            "
Write-Host "##                                                            "
Write-Host "##                                                            "
Write-Host " ##                                                           "
Write-Host "     { 01110000111001101110011011000110110000101101110 }      "
  Write-Host "usage: psscan.ps1 <host|hosts> <port|ports> [-UDP] [-Help]"
  Write-Host " e.g.: psscan.ps1 192.168.1.2 445 -UDP"
  return
}

foreach($p in [array]$ports) {
  foreach($h in [array]$hosts) {
    $protocol = "tcp"
    if ($UDP) {
      $protocol = "udp"
    }

    $msg = "$h,$protocol,$p,"
    if ($protocol -eq "tcp") {
      $t = new-Object system.Net.Sockets.TcpClient
      $c = $t.ConnectAsync($h,$p)
      for($i=0; $i -lt 10; $i++) {
        if ($c.isCompleted) { break; }
        Start-Sleep -milliseconds 100
      }
      $t.Close();

      $r = "Filtered"
      if ($c.isFaulted -and $c.Exception -match "actively refused") {
        $r = "Closed"
      } elseif ($c.Status -eq "RanToCompletion") {
        $r = "Open"
      }
    }
    elseif ($protocol -eq "udp") {
      $u = new-object system.net.sockets.udpclient
      $u.Client.ReceiveTimeout = 500
      $u.Connect($h,$p)
      [void]$u.Send(1,1)
      $l = new-object system.net.ipendpoint([system.net.ipaddress]::Any,0)
      $r = "Filtered"
      try {
        if ($u.Receive([ref]$l)) {
          $r = "Open"
        }
      }
      catch {
        if ($Error[0].ToString() -match "failed to respond") {
          if ((Get-wmiobject win32_pingstatus -Filter "address = '$h' and Timeout=1000 and ResolveAddressNames=false").StatusCode -eq 0) {
            $r = "Open"
          }
        }
        elseif ($Error[0].ToString() -match "forcibly closed") {
          $r = "Closed"
        }
      }
      $u.Close()
    }

    $msg += $r
    Write-Host "$msg"
  }
}

