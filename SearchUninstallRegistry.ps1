       function Get-VMwareToolsIDFrom64BitAddRemove {
       param([string]$AppName)

            foreach ($item in $(Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall)) {
                If ($item.GetValue('DisplayName') -eq $AppName) {
                    return @{
                    reg_id = $item.PSChildName;
                    msi_id = [Regex]::Match($item.GetValue('ProductIcon'), '(?<={)(.*?)(?=})') | Select-Object -ExpandProperty Value
                    }
                }
            }
        }
        #### This function will get the 32-bit .msi guid to be used for uninstall Acrobat if AdobeUninstaller.exe fails.
       function Get-VMwareToolsIDFrom32BitAddRemove {
       param([string]$AppName)

            foreach ($item in $(Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall)) {
                If ($item.GetValue('DisplayName') -eq $AppName) {
                    return @{
                    reg_id = $item.PSChildName;
                    msi_id = [Regex]::Match($item.GetValue('ProductIcon'), '(?<={)(.*?)(?=})') | Select-Object -ExpandProperty Value
                    }
                }
            }
        }

Write-Output "Calling function Get-VMwareToolsIDFrom64BitAddRemove."
            $vmware_tools_ids_64AddRemove = Get-VMwareToolsIDFrom64BitAddRemove "Adobe Acrobat (64-bit)"
            #### If $vmware_tools_ids_64AddRemove is null then check the 32 bit uninstall registry.
            if ($vmware_tools_ids_64AddRemove -ne $null){
                $GuidToUninstall = $vmware_tools_ids_64AddRemove.reg_id
                Write-Output "Found 64-bit .msi guid $GuidToUninstall.  Caling msiexec /x to remove it."
                Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList "/x $GuidToUninstall /q /l*v C:\SUPPORT\LOGS\APPLOGS\Uninst_32-BitAcrobat_$GuidToUninstall.log" -wait -WindowStyle Hidden
            }else{
                #### Check the 32 bit uninstall registry for an Acrobat .msi guid.
                Write-Output "Calling function Get-VMwareToolsIDFrom32BitAddRemove."
                $vmware_tools_ids_32AddRemove = Get-VMwareToolsIDFrom32BitAddRemove "Adobe Acrobat"
                #### if $vmware_tools_ids_32AddRemove is null it means Acrobat is not installed on the machine after you tried several ways to detect it.
                #### Move on and install the 64 bit version of Acrobat followed by an .msp update.
                if ($vmware_tools_ids_32AddRemove -ne $null){
                    $GuidToUninstall = $vmware_tools_ids_32AddRemove.reg_id
                    Write-Output "Found 32-bit .msi guid $GuidToUninstall.  Caling msiexec /x to remove it."
                    Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList "/x $GuidToUninstall /q /l*v C:\SUPPORT\LOGS\APPLOGS\Uninst_32-BitAcrobat_$GuidToUninstall.log" -wait -WindowStyle Hidden
                }
