﻿#requires -Version 3.0 -Modules UpdateServices

<#
    .SYNOPSIS
    Approves all Windows Server Update Services (WSUS) definition updates
	
    .DESCRIPTION
    Approves all definition updates to all given Windows Server Update Services (WSUS) Computer Groups
	
    .PARAMETER Name
    Specifies the name of a WSUS server.
	
    .PARAMETER TargetGroupNames
    Specifies the name(s) of the WSUS computer target group(s) for which to run this cmdlet.
	
    .EXAMPLE
    PS C:\> Approve-WSUSDefinitionUpdates -TargetGroupNames 'All Computers'

    Approve Definition Updates to the 'All Computers' Group

    .EXAMPLE
    PS C:\> Approve-WSUSDefinitionUpdates -Name 'mycdc01' -TargetGroupNames 'All Computers'

    Approves all definition updates to the 'All Computers' Group on the Windows Server Update Services (WSUS) Server 'mycdc01'

    .EXAMPLE
    PS C:\> Approve-WSUSDefinitionUpdates -TargetGroupNames 'All Computers' -WhatfIf

    Simmulate the approval of all definition updates to the 'All Computers' Windows Server Update Services (WSUS) Group

    .EXAMPLE
    PS C:\> Approve-WSUSDefinitionUpdates -TargetGroupNames 'Pilot Servers','Pilot Workstations'

    Approves all definition updates to the 'Pilot Servers' and 'Pilot Workstations' Windows Server Update Services (WSUS) groups

    .NOTES
    Initial beta Version
#>
[CmdletBinding(ConfirmImpact = 'Low',
SupportsShouldProcess)]
param
(
  [Parameter(ValueFromPipeline,
      ValueFromPipelineByPropertyName,
  Position = 1)]
  [Alias('WSUSServer')]
  [string]
  $Name = $null,
  [Parameter(Mandatory,
      ValueFromPipeline,
      ValueFromPipelineByPropertyName,
      Position = 2,
  HelpMessage = 'Specifies the name(s) of the WSUS computer target group(s) for which to run this cmdlet.')]
  [ValidateNotNullOrEmpty()]
  [Alias('InstallGroups')]
  [string[]]
  $TargetGroupNames
)

begin
{
  try 
  {
    if ($Name) 
    {
      Write-Verbose -Message "Use $Name as WSUS Server"
      $paramGetWsusServer = @{
        Name          = $Name
        ErrorAction   = 'Stop'
        WarningAction = 'Continue'
      }
    }
    else 
    {
      Write-Verbose -Message 'Use the default WSUS Server'
      $paramGetWsusServer = @{
        ErrorAction   = 'Stop'
        WarningAction = 'Continue'
      }
    }
    $WSUS = (Get-WsusServer @paramGetWsusServer)
  }
  catch 
  {
    # get error record
    [Management.Automation.ErrorRecord]$e = $_

    # retrieve information about runtime error
    $info = [PSCustomObject]@{
      Exception = $e.Exception.Message
      Reason    = $e.CategoryInfo.Reason
      Target    = $e.CategoryInfo.TargetName
      Script    = $e.InvocationInfo.ScriptName
      Line      = $e.InvocationInfo.ScriptLineNumber
      Column    = $e.InvocationInfo.OffsetInLine
    }
      
    # output information. Post-process collected info, and log info (optional)
    $info

    Write-Error -Message 'No WSUS Server was found!' -ErrorAction Stop

    break

    exit 1
  }

  $FPClass = $null
  $FPClass = $WSUS.GetUpdateClassifications() | Where-Object -FilterScript {
    $_.Title -eq 'Definition Updates'
  }

  if (-not $FPClass) 
  {
    Write-Error -Message 'No Definition Updates found!' -ErrorAction Stop

    break

    exit 1
  }

  $AllDefinitionUpdates = $null
  $AllDefinitionUpdates = $FPClass.GetUpdates() | Where-Object -FilterScript {
    ($_.Title -like 'Definition Update for Microsoft Security Essentials*') -or ($_.Title -like 'Update for Windows Defender Antivirus antimalware platforms*')
  }

  if (-not $AllDefinitionUpdates) 
  {
    Write-Error -Message 'No Definition Updates found!!!' -ErrorAction Stop

    break

    exit 1
  }

}

process
{
  # Loop over all Updates
  foreach ($UpdateID in $AllDefinitionUpdates.Id.UpdateId.Guid) 
  {
    # Loop over all Goups
    foreach ($TargetGroupName in $TargetGroupNames) 
    {
      try 
      {
        $paramGetWsusUpdate = @{
          UpdateId      = $UpdateID
          ErrorAction   = 'Stop'
          WarningAction = 'SilentlyContinue'
        }
        $paramApproveWsusUpdate = @{
          Action          = 'Install'
          TargetGroupName = $TargetGroupName
          ErrorAction     = 'Stop'
          WarningAction   = 'SilentlyContinue'
        }
        if ($pscmdlet.ShouldProcess("$UpdateID to $TargetGroupName", 'Approve'))
        {
          $null = (Get-WsusUpdate @paramGetWsusUpdate | Approve-WsusUpdate @paramApproveWsusUpdate)
        }
      }
      catch 
      {
        # get error record
        [Management.Automation.ErrorRecord]$e = $_

        # retrieve information about runtime error
        $info = [PSCustomObject]@{
          Exception = $e.Exception.Message
          Reason    = $e.CategoryInfo.Reason
          Target    = $e.CategoryInfo.TargetName
          Script    = $e.InvocationInfo.ScriptName
          Line      = $e.InvocationInfo.ScriptLineNumber
          Column    = $e.InvocationInfo.OffsetInLine
        }
      
        # FYI
        $info
      }
    }
  }
}

end
{
  Write-Verbose -Message 'Done'
}

#region License
<#
    BSD 3-Clause License

    Copyright (c) 2018, enabling Technology <http://enatec.io>
    All rights reserved.

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

    By using the Software, you agree to the License, Terms and Conditions above!
#>
#endregion License

#region Hints
<#
    This is a third-party Software!

    The developer(s) of this Software is NOT sponsored by or affiliated with Microsoft Corp (MSFT) or any of its subsidiaries in any way

    The Software is not supported by Microsoft Corp (MSFT)!
#>
#endregion Hints