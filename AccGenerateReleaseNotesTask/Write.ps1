

$rn = "ReleaseNotes"
if ($null -eq $notesRootPath) { 
    $notesRootPath = "E:\$rn" 
}
if ($null -ne $env:ReleaseNotesPath) {
    $notesRootPath = $env:ReleaseNotesPath
}
#debugging only

# $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI = "http://tfs.fintech.deloitte.com:8080/tfs/DefaultCollection/"
# $env:SYSTEM_TEAMPROJECT = "ABSSuite Web"
# $env:fullVer = "11.10"
# $env:ReleaseNotes = "newNotes"
# $env:ABS_GenRn = 1
# $env:SYSTEM_DEFAULTWORKINGDIRECTORY = "C:\Proj"
# $notesRootPath = "C:\$rn" 

#=========================

if ((Test-Path $notesRootPath) -ne $true ) {
    New-Item $notesRootPath -ItemType Directory
}
$releaseid = $env:RELEASE_RELEASEID
$inReleaseMode = $true
$v = $env:fullVer
$n = $env:ReleaseNotes
$ignore = $env:ABS_GenRn -eq 0 
$lclNotesPath = "$env:SYSTEM_DEFAULTWORKINGDIRECTORY\$rn.md"
if ($null -ne $env:Subdomain) {
    Write-Host "Subdomain ${env:Subdomain}"
}
Write-Host "Local Path: $lclNotesPath"
Write-Host "$v Isclient $env:ABS_IsClient GenerateNotes $env:ABS_GenRn Ignore:$ignore" 
if ($null -ne $n) {
    Write-Host "============ Notes =================="
    Write-Host $n
    Write-Host "======================================"
}
else {
    $ignore = $true
}
if ((Test-Path $lclNotesPath) -and ($null -eq $env:System_IgnoreLclNotesPath) ) {
    Write-Verbose "Reading from local notes file $env:System_IgnoreLclNotesPath"
    $n = [System.IO.File]::ReadAllText($lclNotesPath) 
    Write-Host ("##vso[task.uploadsummary]$lclNotesPath") 
}

if (-not ($n -Match "##") ) {
    Write-Host "No Notes"
    $ignore = $true
}
Write-Verbose "Release Id: $releaseid"


if ( ($ignore -eq $false) -and ($v.length -lt 8) -and ($v.length -gt 4)) { 
    $n = $n + "`n"
    if ( [string]::IsNullOrEmpty($releaseid) -ne $true) {
        Write-Host "In Release mode"
        #in release mode
        $d = "$notesRootPath\${env:Subdomain}\$v\"
        New-Item -ItemType Directory -Force -Path $d
        $p = "$d\$rn.$v.md"        
        Write-Host "##vso[task.setvariable variable=notesPath]`"$p`""
        [System.IO.File]::AppendAllText( "$p" , $n)
        if ($null -ne $publishLoc) {
            $dest = "$publishLoc\$($env:Release_Definition_Name)\$($env:Release_EnvironmentName)\$v"
            if ((Test-Path $dest) -ne $true) {
                New-item -ItemType Directory -Path $dest
            }
            [System.IO.File]::AppendAllText( "$dest\$rn.md" , $n)   
        }
        $ignore = $true
    }
    else { 
        Write-Host "In Build mode"
        $inReleaseMode = $false

        $vrn = "$notesRootPath\$rn.$v.md" 
        if (Test-Path $vrn) {
            $fVersion = [regex]::match("${env:BUILD_BUILDNUMBER}", '(\S+) ').Groups[1].Value.Trim()
            Write-Host "File Exist  $fVersion  $vrn"
            $current = [System.IO.File]::ReadAllText("$vrn") 
            if (-not($current -Match $fVersion)) {
                Write-Host "New Content"
                [System.IO.File]::AppendAllText( $vrn, $n) 
            }
            else { 
                Write-Host "Ignored because it is old $fVersion"
                $ignore = $true
            }
        }
        else {
            [System.IO.File]::AppendAllText( $vrn, $n) 
        } 
    }
  
 
}
else { 
    Write-Verbose "$v  is not between 4-8 $ignore"
}
## wiki update
if ($ignore -eq $false -and $inReleaseMode -eq $false) {
    Import-Module -Name "$PSScriptRoot\GenerateReleaseNotes.psm1" -Force 


    $content = [System.IO.File]::ReadAllText("$notesRootPath\$rn.$v.md") 


    $tfsUri = $env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI
    $teamproject = $env:SYSTEM_TEAMPROJECT -replace " " , "%20"
    $pagePath = "%2FRelease%20Notes%2F$v"

    $wikiIdentifier = "ABSSuite-Web.wiki"
    $uri = "$($tfsUri)$($teamproject)/_apis/wiki/wikis/$($wikiIdentifier)/pages?path=$($pagePath)&api-version=4.1&includeContent=true"
    try { $result = Invoke-GetWithHeaderCommand -uri $uri   -usedefaultcreds $true } catch {
        $_.Exception.Response.StatusCode.Value__
    }
    $headers = $null
    if ($null -ne $result.header -and $null -ne $result.content) {
        $etag = $result.header["ETag"]; 
        $exContent = $result.content
        if ($null -ne $exContent) {     
            $headers = @{"If-Match" = $etag } 
            #$content = $exContent.content 
        }
    }
    $content = $content + "`n" + $n 

    $uri = "$($tfsUri)/$($teamproject)/_apis/wiki/wikis/$($wikiIdentifier)/pages?path=$($pagePath)&api-version=4.1"

    $body = @{
        "content" = $content;
    };
    Invoke-PutCommand -uri $uri -body $body  -usedefaultcreds $true -headers $headers
}

 