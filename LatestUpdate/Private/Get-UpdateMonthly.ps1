Function Get-UpdateMonthly {
    <#
        .SYNOPSIS
            Builds an object with the Windows 8.1/7 Monthly Update.
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $False, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Xml.XmlNode] $UpdateFeed,

        [Parameter(Mandatory = $False)]
        [System.Management.Automation.SwitchParameter] $Previous
    )

    # Filter object matching desired update type
    $updateList = New-Object -TypeName System.Collections.ArrayList
    ForEach ($item in $UpdateFeed.feed.entry) {
        If ($item.title -match $script:resourceStrings.SearchStrings.MonthlyRollup) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): matched item [$($item.title)]"
            $PSObject = [PSCustomObject] @{
                Title   = $item.title
                ID      = $item.id
                Updated = $item.updated
            }
            $updateList.Add($PSObject) | Out-Null
        }
    }

    # Filter and select the most current update
    If ($updateList.Count -ge 1) {
        $sortedUpdateList = New-Object -TypeName System.Collections.ArrayList
        ForEach ($update in $updateList) {
            $PSObject = [PSCustomObject] @{
                Title   = $update.title
                ID      = "KB{0}" -f ($update.id).Split(":")[2]
                Updated = ([DateTime]::Parse($update.updated))
            }
            $sortedUpdateList.Add($PSObject) | Out-Null
        }
        If ($Previous.IsPresent) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): selecting previous update"
            $latestUpdate = $sortedUpdateList | Sort-Object -Property Revision -Descending | Select-Object -First 2 | Select-Object -Last 1
        }
        Else {
            $latestUpdate = $sortedUpdateList | Sort-Object -Property Revision -Descending | Select-Object -First 1
        }
        If ($Previous.IsPresent) {
            Write-Verbose -Message "$($MyInvocation.MyCommand): selecting previous update"
            $latestUpdate = $sortedUpdateList | Sort-Object -Property Updated -Descending | Select-Object -First 2 | Select-Object -Last 1
        }
        Else {
            $latestUpdate = $sortedUpdateList | Sort-Object -Property Updated -Descending | Select-Object -First 1
        }
        Write-Verbose -Message "$($MyInvocation.MyCommand): selected item [$($latestUpdate.title)]"
    }

    # Return object to the pipeline
    Write-Output -InputObject $latestUpdate
}
