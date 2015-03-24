Call RunAndReport("lims.glbrc.org", "2.0.50727")

Sub RunAndReport(site, strVersions)
	If WScript.Arguments.Count = 0 Then
		Set objShell = WScript.CreateObject("WScript.Shell")
		Call objShell.Run("""" + WScript.ScriptFullName + """ 1", 0, True)
		Set objShell = Nothing
	Else
		Call RunAndReport2(site, strVersions)
	End If
    
    EnableIEHosting()           ' The EnableIEHosting registry key is required when .NET Framework 4.5 is installed on the client machine
End Sub

Sub RunAndReport2(site, strVersions)
	Dim strPass, strFail
	Dim strFinalResult, strRunResult
	Dim intIcon
	Dim arVersions
	Dim strVer

	If strVersions = "" Then
		MsgBox "No .NET Framework version was detected on your computer!" + Chr(13) + "Please install .NET Framework before running this tool", 16, "STARLIMS v10 Browser configuration"
		WScript.Quit
	End If


	If MsgBox("This tool will automatically configure the .NET security according to STARLIMS requirements." + Chr(13) + Chr(13) + "Do you want to continue?", 32 + 4, "STARLIMS v10 Browser configuration" ) = 7 Then
		WScript.Quit
	End If

	arVersions = Split(strVersions, ",")

	strFinalResult = ""
	strPass = ""
	strFail = ""
	intIcon = 0

	For Each strVer In arVersions
		strRunResult = RunCasPol(site, strVer)
		
		If strRunResult = "" Then
			strPass = strPass + "> v" + strVer + Chr(13)
		Else
			strFail = strFail + "> v" + strVer + ": " + strRunResult + Chr(13)
		End If
	Next

	If Len(strPass) > 0 Then
		strFinalResult = strFinalResult + _
			"Browser configured succesfully for running STARLIMS software on the following .NET Frameworks." + _
		 	Chr(13) + "New STARLIMS codegroups were added to your .NET machine settings." + Chr(13) + Chr(13) + _
			strPass + Chr(13) + Chr(13)
		intIcon = 64
	End If

	If Len(strFail) > 0 Then
		strFinalResult = strFinalResult + _
			"Browser configuration failed on the following .NET frameworks." + Chr(13) + Chr(13) + _
			strFail + Chr(13) + Chr(13)
		If intIcon = 0 Then intIcon = 16 Else intIcon = 48
	End If

	If intIcon <> 16 Then
		strFinalResult = strFinalResult + "Please close your browser before accessing the application!"
	Else
		strFinalResult = strFinalResult + "Please contact your systems adminstrator."
	End If

	MsgBox  strFinalResult, intIcon, "STARLIMS v10 Browser configuration"
End Sub


Function RunCasPol(site, strVer)
	Dim objShell
	Dim strCasPolArgs
	Dim strCasPolExe
	Dim strCommandLine
	Dim intRunStatus

	strCasPolArgs = BuildCommandArguments(site)
	If strCasPolArgs = "" Then
		RunCasPol = "Cannot build command line arguments for CasPol.exe. Probably site name was not specified."
		Exit Function
	End If

	Set objShell = WScript.CreateObject("WScript.Shell")
	strCasPolExe = objShell.ExpandEnvironmentStrings("%windir%\Microsoft.NET\Framework\v" + strVer + "\caspol.exe")
	If Not FileExists(strCasPolExe) Then
		RunCasPol = "Cannot locate " + strCasPolExe + " command line tool."
		Exit Function
	End If

	strCommandLine = strCasPolExe + " -polchgprompt off"
	Call objShell.Run(strCommandLine, 0, True)

	strCommandLine = strCasPolExe + " -rg ""STARLIMS " + site + """"
	Call DelExistingSTARLIMSCodeGroups(objShell, strCommandLine)

	strCommandLine = strCasPolExe + " " + strCasPolArgs
	intRunStatus = objShell.Run(strCommandLine, 0, True)
	
	If intRunStatus <> 0 Then
		RunCasPol = "CasPol.exe command line tool returned this error code: " & CStr(intRunStatus)
		Exit Function
	End If


	Set objShell = Nothing
	RunCasPol = ""
End Function



Function BuildCommandArguments(site)
	If site = "" Then
		BuildCommandArguments = ""
		Exit Function
	End If

	BuildCommandArguments = "-m -ag 1 -site " + site + " FullTrust -n ""STARLIMS " + site + """ -d ""This code group grants the FullTrust permission set to assemblies of STARLIMS software."""
End Function



Function FileExists(strFilePath)
	Dim objFs

	Set objFs = CreateObject("Scripting.FileSystemObject") 
	FileExists = objFs.FileExists(strFilePath)
	Set objFs = Nothing
End Function


Sub DelExistingSTARLIMSCodeGroups(objShell, strCommandLine)
	Dim intRunStatus

	intRunStatus = 0
	Do While intRunStatus = 0
		intRunStatus = objShell.Run(strCommandLine, 0, True)
	Loop
End Sub


Sub EnableIEHosting()
    ' The EnableIEHosting registry key is required when .NET Framework 4.5 is installed on the client machine
    
	Set Shell = CreateObject( "WScript.Shell" )
	
	Shell.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\EnableIEHosting", 1, "REG_DWORD"
	Shell.RegWrite "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\EnableIEHosting", 1, "REG_DWORD"
End Sub
