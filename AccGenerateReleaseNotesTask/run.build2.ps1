$d = "C:\one\Scripts\GenerateReleaseNotes\TestResult"
$env:ReleaseNotesPath = "C:\One\Scripts\ABSRNotes\Results\"
$env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI = "http://tfsabs.sltc.com:8080/tfs/DefaultCollection/"
$env:SYSTEM_TEAMPROJECT = "ABSSuite Web"

# $env:BUILD_DEFINITIONNAME = "ABSSuite-Sprint-11.11"
# $env:BUILD_BUILDNUMBER = "11.11.224 - 20190829.37813"
# $env:BUILD_BUILDID = 37813

$env:fullVer = "11.12"
$defId = 170
$teamproject = $env:SYSTEM_TEAMPROJECT
$tfsUri = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI
 
# write-host $Env:ABS_Marketing_Ver
# $s = 
# [regex]::match($s, '\(([^\)]+)\)').Groups[1].Value
$Verbose = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Import-Module -Name "$PSScriptRoot\GenerateReleaseNotes.psm1" -Force 
$VerbosePreference = "SilentlyContinue"


$uri = "$($tfsUri)$($teamproject)/_apis/build/builds?definitions=$defId&queryOrder=startTimeAscending"
Write-Host $uri
try { $result = Invoke-GetCommand -uri $uri   -usedefaultcreds $true | ConvertFrom-JsonUsingDOTNET } catch {
    $_.Exception.Response.StatusCode.Value__
}
$index = 1
foreach ($c in $result.value) {
    if ($index -gt 1) {

        $env:BUILD_BUILDID = $c.id
        $env:BUILD_BUILDNUMBER = $c.buildNumber
        $env:BUILD_DEFINITIONNAME = $c.definition.name
        write-host "$index out of "$result.count " id:" $c.id  $c.definition.name
        .\GenerateReleaseNotes.ps1  -outputfile "$d\rd.md"  -publishLoc "$d\pub\" -notesRootPath "$d\root" -templateLocation "File" -templatefile "$d\RNTemplate.txt" -emptySetText "None" -generateForOnlyPrimary $false -usedefaultcreds $true -generateForCurrentRelease $false -maxWi 500 -maxChanges 500 -appendToFile $false -showParents $true -wiFilter "Bug,PRODUCT BACKLOG ITEM,Feature,Epic" -unifiedList $true -outputvariablename "ReleaseNotesTotal" ## -overrideStartReleaseId 26111 
    }
    $index = $index + 1
}
 