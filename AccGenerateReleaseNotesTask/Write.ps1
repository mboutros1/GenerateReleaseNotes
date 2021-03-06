$rn = "ReleaseNotes"
if ($null -eq $notesRootPath) { 
    $notesRootPath = "E:\$rn" 
}
if ($null -ne $env:ReleaseNotesPath) {
    $notesRootPath = $env:ReleaseNotesPath
} 

if ((Test-Path $notesRootPath) -ne $true ) {
    New-Item $notesRootPath -ItemType Directory
}
$releaseid = $env:RELEASE_RELEASEID
$inReleaseMode = if ( [string]::IsNullOrEmpty($releaseid) -eq $true) { $false } else { $true }
$b = $env:Build_BuildNumber
$v = [regex]::match("$b", '(\S+) ').Groups[1].Value

if ($inReleaseMode -eq $false) {
    $v = $v.Substring(0, $v.LastIndexOf('.'))  
}
$n = $env:ReleaseNotes
$ignore = $env:ABS_GenRn -eq 0 
$lclNotesPath = "$env:SYSTEM_DEFAULTWORKINGDIRECTORY\$rn.md"
if ($null -ne $env:Subdomain) {
    Write-Host "Subdomain ${env:Subdomain}"
}
Write-Host "Local Path: $lclNotesPath"


if ((Test-Path $lclNotesPath) -and ($null -eq $env:System_IgnoreLclNotesPath) ) {
    Write-Verbose "Reading from local notes file $env:System_IgnoreLclNotesPath"
    $n = [System.IO.File]::ReadAllText($lclNotesPath) 
    Write-Host ("##vso[task.uploadsummary]$lclNotesPath") 
}

if ( ($null -eq $n) -or (-not ($n -Match "##")) ) {
    Write-Host "No Notes"
    $ignore = $true
}
else { 
    Write-Host "============ Notes =================="
    Write-Host $n
    Write-Host "======================================"
    $ignore = $false
} 

Write-Verbose "Release Id: $releaseid"
Write-Host "$v Isclient $env:ABS_IsClient GenerateNotes $env:ABS_GenRn Ignore:$ignore" 

if ($ignore -eq $true) {
    Write-Host "Skipped, most probably no notes"
}
else {
    if (($v.length -lt 12) -and ($v.length -gt 4)) {
        $n = $n + "`n"
        if ( $inReleaseMode) {
            if (($v.length -lt 12) -and ($v.length -gt 4)) {
                Write-Host "In Release mode"
                #in release mode
                $d = "$notesRootPath\${env:Subdomain}\$v\"
                New-Item -ItemType Directory -Force -Path $d
                $p = "$d\$rn.$v.md"        
                Write-Host "##vso[task.setvariable variable=notesPath]`"$p`""
                [System.IO.File]::AppendAllText( "$p" , $n)
                if ($null -ne $publishLoc) {
                    $dest = "$publishLoc\$($env:RELEASE_DEFINITIONNAME)\$($env:Release_EnvironmentName)\$v"
                    if ((Test-Path $dest) -ne $true) {
                        New-item -ItemType Directory -Path $dest
                    }
                    [System.IO.File]::AppendAllText( "$dest\$rn.md" , $n)   
                    Write-Host "Destination: $dest"
                }
                $ignore = $true
            }
        }
        else { 
            if (($v.length -lt 8) -and ($v.length -gt 4)) {
                Write-Host "In Build mode" 
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
            else {
                $ignore = $true
            }
        }
    } 
    
    ## wiki update
    if ( ($ignore -eq $false) -and ($inReleaseMode -eq $false)) {
    
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
            $exContent = $result.content | ConvertFrom-JsonUsingDOTNET
            if ($null -ne $exContent) {     
                $headers = @{"If-Match" = $etag } 
                $content = $exContent.content 
            }
        }
        $content = $content + "`n" + $n 
    
        $uri = "$($tfsUri)/$($teamproject)/_apis/wiki/wikis/$($wikiIdentifier)/pages?path=$($pagePath)&api-version=4.1"
    
        $body = @{
            "content" = $content;
        };
        Invoke-PutCommand -uri $uri -body $body  -usedefaultcreds $true -headers $headers
    }
    
} 


 