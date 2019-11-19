$env:ReleaseNotesPath = "C:\One\Scripts\ABSRNotes\Results\"
$env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI = "http://tfs.fintech.deloitte.com:8080/tfs/DefaultCollection/"
$env:SYSTEM_TEAMPROJECT = "ABSSuite Web"

# $env:BUILD_DEFINITIONNAME = "ABSSuite-Sprint-11.11"
# $env:BUILD_BUILDNUMBER = "11.11.224 - 20190829.37813"
# $env:BUILD_BUILDID = 37813

$env:fullVer = "11.12"
$defId = 170
$teamproject = $env:SYSTEM_TEAMPROJECT
$tfsUri = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI

# $env:RELEASE_DEFINITIONNAME = "ABS QA Web"
# $env:BUILD_BUILDNUMBER = "0.0.1-gated+20190208.7"
# $env:RELEASE_ENVIRONMENTNAME = "Verified QA"  
# $env:RELEASE_DEFINITIONID = 8
# $env:RELEASE_RELEASEID = 19354
# $env:BUILD_BUILDID = 31206
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
    #    if ($index -gt 1) {

    $env:BUILD_BUILDID = $c.id
    $env:BUILD_BUILDNUMBER = $c.buildNumber
    $env:BUILD_DEFINITIONNAME = $c.definition.name
    write-host "$index out of "$result.count " id:" $c.id  $c.definition.name
    .\GenerateReleaseNotes.ps1 "releaseNotes.md" "ReleaseNotes" "C:\one\Scripts\ABSRNotes\RNTemplate.txt" "" "File" True False False "" "" 50 50 "" "" True False True
    #   }
    $index = $index + 1
}


# .\GenerateReleaseNotes.ps1 "releaseNotes.md" "ReleaseNotes" "C:\one\Scripts\ABSRNotes\RNTemplate.txt" "" "File" True False False "" "" 50 50 "" "" True False True