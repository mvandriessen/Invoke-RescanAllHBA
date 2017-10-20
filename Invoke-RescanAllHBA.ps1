Function Invoke-RescanAllHBA
{

<#
.SYNOPSIS
  Rescan all HBA on a host
.DESCRIPTION
  This function will rescan all HBAs on all hosts or in a specified cluster in parallel.
.NOTES
  Author:  Maarten Van Driessen
.PARAMETER vCenterName
  Specify the name of the vCenter server
.PARAMETER Cluster
  Specify the name of the cluster you want to rescan. If no cluster is specified,
  all hosts in vCenter are rescanned
.EXAMPLE
  Invoke-RescanAllHBA -vCenterName "vcenter.lab.local" -Cluster "Cluster1"
  
  Rescans the cluster "Cluster1" connected to vcenter.lab.local

.NOTES
  PowerCLI needs to be installed on the system you're running the script from. 
#>

    param
    (
        [Parameter(mandatory = $true)][string]$vCenterName,
        [Parameter(Mandatory = $false)][string]$Cluster
    )
    
    Function Write-Log 
    {
        #Function written by William Lam @lamw
        # www.virtuallyghetto.com
        param(
            [Parameter(Mandatory = $true)]
            [String]$message
        )
    
        $timeStamp = Get-Date -Format "dd-MM-yyyy_HH:mm:ss"
    
        Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
        Write-Host -ForegroundColor Green " $message"
        $logMessage = "[$timeStamp] $message"
        $logMessage | Out-File -Append -LiteralPath "C:\temp\$($verboseLogFile)"
    }

    if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core)) 
    {
        Import-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue
    }
    
    Connect-VIServer -Server $vCenterName
    if($Cluster.length -eq 0)
    {
        Write-Log "No cluster specified, getting all hosts..."
        $HostsView = Get-VMHost | get-View
    }
    else
    {
        Write-Log "Getting all hosts in the $($Cluster)..."
        $HostsView = Get-Cluster $Cluster | Get-VMHost | get-View
    }

    foreach ($HostView in $HostsView) 
    {
        #logic to be run in the job
        $rescanjob = 
        {
            Function Write-Log 
            {
                #Function written by William Lam @lamw
                # www.virtuallyghetto.com
                param(
                    [Parameter(Mandatory = $true)]
                    [String]$message
                )
            
                $timeStamp = Get-Date -Format "dd-MM-yyyy_HH:mm:ss"
            
                Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
                Write-Host -ForegroundColor Green " $message"
                $logMessage = "[$timeStamp] $message"
                $logMessage | Out-File -Append -LiteralPath "C:\temp\$($verboseLogFile)"
            }

            $verboseLogFile = "$($args[2]).log"
            
            if (!(Get-Module -Name VMware.VimAutomation.Core) -and (Get-Module -ListAvailable -Name VMware.VimAutomation.Core)) 
            {
                Write-Log "Loading PowerCLI..."
                Import-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue
            }
            Write-Log "PowerCLI loaded..."
            
            Write-Log "Connecting to $($args[0])..."
            connect-viserver $args[0] -session $args[1] -WarningAction:Ignore -ErrorAction:Stop | out-null

            try     
            {
                Write-Log "Rescanning host: $($args[2])"
                $esxhostview = Get-View -ViewType "hostsystem" -Property "ConfigManager.StorageSystem" -Filter @{"Name" = "^" + $args[2] + "$"}
                
                $StorageSystem = get-view $esxhostview.ConfigManager.StorageSystem -Property "availableField"
                $StorageSystem.RescanAllHba()
                $StorageSystem.RescanVmfs()
            }
            catch 
            {
                Write-Log "Something went wrong while rescanning host: $($args[2])"
            }
            Write-Log "Script ended with arguments: vcenter:$($args[0]), esxhost:$($args[2])"
        }
        $vcenter = ($HostView.Client.ServiceUrl).split("/")[2]
        $session = $HostView.Client.SessionSecret
        $esxhost = $HostView.Name
        Start-Job -argumentlist $vcenter, $session, $esxhost -scriptblock $rescanjob | out-null
    }
}