﻿#requires -Version 1.0 -RunAsAdministrator

<#
      .SYNOPSIS
      Download and install the chocolatey default base packages

      .DESCRIPTION
      Download and install the chocolatey default base packages

      .NOTES
      These are the chocolatey default packages, that we want to have on all new systems

      Version 1.3.0

      .LINK
      http://beyond-datacenter.com

      .LINK
      https://chocolatey.org/docs
#>
[CmdletBinding(ConfirmImpact = 'Low',
   SupportsShouldProcess)]
param ()

begin
{
   Write-Output -InputObject 'Download and install the chocolatey default base packages'

   $null = (& "C:\ProgramData\chocolatey\bin\refreshenv.cmd")

   if (-not $env:ChocolateyInstall)
   {
      $env:ChocolateyInstall = 'C:\ProgramData\chocolatey'
   }

   $null = (Set-MpPreference -EnableControlledFolderAccess Disabled -Force -ErrorAction SilentlyContinue)

   try
   {
      $null = ([Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072)
   }
   catch
   {
      Write-Verbose -Message 'Unable to set PowerShell to use TLS 1.2.'
   }

   # Use Windows built-in compression instead of downloading 7zip
   $env:chocolateyUseWindowsCompression = 'true'

   $AllChocoPackages = @(
      'BGInfo'
      'chocolatey-core.extension'
      'chocolatey-dotnetfx.extension'
      'chocolatey-misc-helpers.extension'
      'chocolatey-windowsupdate.extension'
      'chocolatey-font-helpers.extension'
      'chocolatey-vscode.extension'
      'chocolatey-vscode'
      'FiraCode'
      'microsoft-edge'
      'notepadplusplus'
      'nuget.commandline'
      'nxlog'
      'powershell-core'
      'vscode'
      'vscode-powershell'
   )

   # Initial Package Counter
   $PackageCounter = 1
}

process
{
   foreach ($ChocoPackage in $AllChocoPackages)
   {
      try
      {
         Write-Verbose -Message ('Start the installation of ' + $ChocoPackage)

         if ($pscmdlet.ShouldProcess($ChocoPackage, 'Install'))
         {
            Write-Progress -Activity ('Installing ' + $ChocoPackage) -Status ('Package ' + $PackageCounter + ' of ' + $($AllChocoPackages.Count)) -PercentComplete (($PackageCounter / $AllChocoPackages.Count) * 100)

            try
            {
               $null = (& "$env:ChocolateyInstall\bin\choco.exe" install $ChocoPackage --acceptlicense --limitoutput --no-progress --yes --force --params 'ALLUSERS=1')
            }
            catch
            {
               # Retry with --ignore-checksums - A less secure option!!!
               $null = (& "$env:ChocolateyInstall\bin\choco.exe" install $ChocoPackage --ignore-checksums --acceptlicense --limitoutput --no-progress --yes --force --params 'ALLUSERS=1')
               # Some Packages (e.g. Sysmon) use the latest and greatest version, the checksum check will cause issues in this case!
            }
         }

         # Add Package Step
         $PackageCounter++
      }
      catch
      {
         Write-Warning -Message ('Installation of ' + $ChocoPackage + ' failed!')

         # Add Package Step
         $PackageCounter++
      }
   }
}

end
{
   $null = (Set-MpPreference -EnableControlledFolderAccess Enabled -Force -ErrorAction SilentlyContinue)
}

#region LICENSE
<#
      BSD 3-Clause License

      Copyright (c) 2020, Beyond Datacenter
      All rights reserved.

      Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
      1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
      2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
      3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#>
#endregion LICENSE

#region DISCLAIMER
<#
      DISCLAIMER:
      - Use at your own risk, etc.
      - This is open-source software, if you find an issue try to fix it yourself. There is no support and/or warranty in any kind
      - This is a third-party Software
      - The developer of this Software is NOT sponsored by or affiliated with Microsoft Corp (MSFT) or any of its subsidiaries in any way
      - The Software is not supported by Microsoft Corp (MSFT)
      - By using the Software, you agree to the License, Terms, and any Conditions declared and described above
      - If you disagree with any of the Terms, and any Conditions declared: Just delete it and build your own solution
#>
#endregion DISCLAIMER