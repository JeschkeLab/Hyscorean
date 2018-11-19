param(   
    [string] $AddedFolder =  "C:\Users\luis\AppData\Local\Atlassian\SourceTree\git_local\bin", 
[bool] $ApplyImmediately = $true   
)   
 
 
$environmentRegistryKey = 'Registry::HKCU\Environment'    
 
$oldPath = (Get-ItemProperty -Path $environmentRegistryKey -Name Path).Path    
 
# See if a new folder has been supplied.    
 
if (!$AddedFolder)    
{    
Write-Warning 'No Folder Supplied. $ENV:PATH Unchanged'    
return    
}    
 
if ($ENV:PATH | Select-String -SimpleMatch $AddedFolder)    
{    
Write-Warning 'Folder already within $ENV:PATH'    
return    
}    
 
$newPath = $oldPath + ’;’ + $AddedFolder    
 
Set-ItemProperty -Path $environmentRegistryKey -Name Path -Value $newPath    
 
if ($ApplyImmediately)    
{    
if (-not ("Win32.NativeMethods" -as [Type]))    
{    
# import sendmessagetimeout from win32    
Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"    
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]    
public static extern IntPtr SendMessageTimeout(    
IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,    
uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);    
"@    
}    
 
$HWND_BROADCAST = [IntPtr] 0xffff;    
$WM_SETTINGCHANGE = 0x1a;    
$result = [UIntPtr]::Zero    
 
# notify all windows of environment block change    
[Win32.Nativemethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, "Environment", 2, 5000, [ref] $result);    
}    
 
