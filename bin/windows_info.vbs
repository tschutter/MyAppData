' Print interesting Windows info about this computer.
'
' Run with "cscript //i //nologo windows_info.vbs".

Option Explicit

' http://blogs.technet.com/b/heyscriptingguy/archive/2006/12/06/how-can-i-determine-the-ou-the-local-computer-belongs-to.aspx

Dim objSysInfo
Set objSysInfo = CreateObject("ADSystemInfo")

Dim strComputer
strComputer = objSysInfo.ComputerName

Dim objComputer
Set objComputer = GetObject("LDAP://" & strComputer)

Dim arrOUs
arrOUs = Split(objComputer.Parent, ",")

Dim arrMainOU
arrMainOU = Split(arrOUs(0), "=")

WScript.Echo "ADSystemInfo.ComputerName: " & objSysInfo.ComputerName
WScript.Echo "ADSystemInfo.SiteName: " & objSysInfo.SiteName
WScript.Echo "ADSystemInfo.DomainShortName: " & objSysInfo.DomainShortName
WScript.Echo "ADSystemInfo.DomainDNSName: " & objSysInfo.DomainDNSName
WScript.Echo "ADSystemInfo.ForestDNSName: " & objSysInfo.ForestDNSName

WScript.Echo "Computer.Name: " & objComputer.name
WScript.Echo "Computer.cn: " & objComputer.cn
WScript.Echo "Computer.DNSHostName: " & objComputer.DNSHostName
WScript.Echo "Computer.OperatingSystem: " & objComputer.operatingSystem
WScript.Echo "Computer.ServicePack: " & objComputer.operatingSystemServicePack
WScript.Echo "Computer.SAMAccountName: " & objComputer.sAMAccountName
WScript.Echo "Computer.Location: " & objComputer.location
WScript.Echo "Computer.UserAccountControl: " & objComputer.userAccountControl
WScript.Echo "Computer.PrimaryGroupID: " & objComputer.primaryGroupID
WScript.Echo "Computer.WhenCreated: " & objComputer.whenCreated
WScript.Echo "Computer.WhenChanged: " & objComputer.whenChanged
WScript.Echo "Computer.DistinguishedName: " & objComputer.distinguishedName
Wscript.Echo "Computer.OU: " & arrMainOU(1)
