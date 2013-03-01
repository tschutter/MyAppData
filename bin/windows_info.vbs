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

WScript.Echo "Name: " & objComputer.name
WScript.Echo "cn: " & objComputer.cn
WScript.Echo "ComputerName: " & objComputer.ComputerName
WScript.Echo "SiteName: " & objComputer.SiteName
WScript.Echo "DNSHostName: " & objComputer.DNSHostName
WScript.Echo "DomainShortName: " & objComputer.DomainShortName
WScript.Echo "DomainDNSName: " & objComputer.DomainDNSName
WScript.Echo "ForestDNSName: " & objComputer.ForestDNSName

WScript.Echo "OperatingSystem: " & objComputer.operatingSystem
WScript.Echo "ServicePack: " & objComputer.operatingSystemServicePack
WScript.Echo "SAMAccountName: " & objComputer.sAMAccountName
WScript.Echo "Location: " & objComputer.location
WScript.Echo "UserAccountControl: " & objComputer.userAccountControl
WScript.Echo "PrimaryGroupID: " & objComputer.primaryGroupID
WScript.Echo "WhenCreated: " & objComputer.whenCreated
WScript.Echo "WhenChanged: " & objComputer.whenChanged
WScript.Echo "DistinguishedName: " & objComputer.distinguishedName
Wscript.Echo "OU = " & arrMainOU(1)
