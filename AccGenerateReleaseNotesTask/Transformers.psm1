$global:existFixed = $false
$global:existAdded = $false
function Get-TypeCaption { 
    Param(
        $wi        
    )
    $ty = $wi.fields.'System.WorkItemType'
    
    switch ($ty) {
        "Bug" {
            if ($global:existAdded -eq $false) {
                $widetail = "`n##Fixed`n"
                $global:existAdded = $true 
            }
        }
        default {
            if ($global:existFixed -eq $false) {
                $widetail = "`n##Added/Changed`n"
                $global:existFixed = $true 
            } 
        }
    } 
    $widetail 
}
function Get-ChangesetWorkItems { 
    param (
        $tfsUri,
        $teamproject,
        $id,
        $loc,
        $usedefaultcreds,
        $wiFilter,
        $wiStateFilter,
        $showParents
    )
    
    $wiArray = @()
    $range = Get-MergeRange  -tfsUri $tfsUri -teamproject $teamproject  -id $id -loc $loc -usedefaultcreds $usedefaultcreds
    if (($range.from -gt 0) -and ($range.to -gt 0)) {
        for ($i = $range.from; $i -lt ($range.to + 1) ; $i++ ) {
            #http://tfs.fintech.deloitte.com:8080/tfs/DefaultCollection/_apis/tfvc/changesets/117737/workItems
            
            $uri = "$($tfsUri)_apis/tfvc/changesets/$($i)/workItems"
            $jsondata = Get-Detail  -uri $uri -usedefaultcreds $usedefaultcreds
            write-Verbose "Merged Commit  of $id - $i"
            Write-Host "Merged Commit of $id - $i"
            foreach ($wi in  $jsondata.value ) {
                Add-Member -InputObject $wi -MemberType NoteProperty -Name url -Value "$($tfsUri)_apis/wit/workItems/$($wi.id)";
                $wiArray += $wi
            }
        }
    }
    $wiData = @{
        count = $wiArray.length;
        value = $wiArray;
    }
    $workItems = Expand-WorkItemData -workItemData $wiData -usedefaultcreds $usedefaultcreds -wifilter $wiFilter -wiStateFilter $wiStateFilter -showParents $showParents

    $workItems

}

function Get-MergeRange {
    param (
        $tfsUri,
        $teamproject,
        $id,
        $loc,
        $usedefaultcreds
    )
    #    http://tfs.fintech.deloitte.com:8080/tfs/DefaultCollection/_apis/tfvc/changesets/117737/changes
    $uri = "$($loc)/changes" # "$($tfsUri)/_apis/tfvc/changesets/$($id)/changes"
    $jsondata = Get-Detail -uri $uri -usedefaultcreds $usedefaultcreds
    $count = $jsondata.count
    $ret = @{ }
    $ret.from = 0 
    $ret.to = 0 
    if (-not($count -eq 0)) {
        $mSource = $jsondata.value[0].mergeSources
        if (-not($mSource -eq $null) -and -not($mSource.length -eq 0)) {            
            $ret.from = $mSource[0].versionFrom
            $ret.to = $mSource[0].versionTo
        }
    }
    $ret
} 

function Add-MergedWit { 
    param  (
        $tfsUri, 
        $teamproject,
        $unifiedWorkItems,
        $id ,
        $loc,
        $usedefaultcreds,
        $wiFilter ,
        $wiStateFilter,
        $showParents 
    )  


    $otherWk = Get-ChangesetWorkItems -tfsUri $tfsUri -teamproject $teamproject -id $id -loc $loc -usedefaultcreds $usedefaultcreds -wifilter $wiFilter -wiStateFilter $wiStateFilter -showParents $showParents
    foreach ($wi in $otherWk) {
        if ($unifiedWorkItems.ContainsKey($wi.id) -eq $false) {
            Write-Verbose "     Adding WI $($wi) to unified set"
            $unifiedWorkItems.Add($wi.id, $wi)
        }
        else {
            Write-Verbose "     Skipping WI $($wi.id) as already in unified set"
        } 
    }
    $unifiedWorkItems
}

function Get-WorkItemDataFromChangeSets {
    param
    (
        $tfsUri,
        $teamproject,
        $changesets, 
        $usedefaultcreds,
        $maxItems
    )
    $wiArray = @()
    foreach ($cs in $changesets) {
        $jsondata = Get-Detail  -uri $cs._links.workItems.href -usedefaultcreds $usedefaultcreds
        foreach ($wi in  $jsondata.value ) {
            Add-Member -InputObject $wi -MemberType NoteProperty -Name url -Value "$($tfsUri)_apis/wit/workItems/$($wi.id)";
            $wiArray += $wi
        }
        
    }
    $wiData = @{
        count = $wiArray.length;
        value = $wiArray;
    }
    $wiData
}


function HasWorkItems { 
    param( 
        $builds, 
        $releases
    )
    $has = $false;
    foreach ( $b in $builds) { 
        if ($b.workitems.count -ne 0) {
            $has = $true;
        }
    }
    foreach ( $b in $releases) { 
        if ($b.workitems.count -ne 0) {
            $has = $true;
        }
    }
    $has
}