$MyjsonUrlParameters= @{
    Root   = "https://api.myjson.com/" # Myjson URL root parameter
    Path   = "bins/"                   # Myjson URL path parameter
    Pretty = "?pretty=1"               # Myjson URL argument to prettify data
}
<#
.Synopsis
    Generate myjson url
.DESCRIPTION
    Generates myjson url string from default string parts and/or provided Id
.EXAMPLE
    Join-MyjsonUrlString -StringContainingId "a1a1a1a1"
.EXAMPLE
    Join-MyjsonUrlString
.INPUTS
    Id of the myjson file
.OUTPUTS
    URL
#>
function Join-MyjsonUrlString {
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # Myjson file id
        [Parameter(ValueFromPipeline = $true)]
        [Alias("Id")]
        [string]
        $StringContainingId
    )
    $UrlString = $MyjsonUrlParameters.Root + $MyjsonUrlParameters.Path + $StringContainingId
    return $UrlString
}
<#
.Synopsis
    Extract myjson Id from string
.DESCRIPTION
    Tries to extract myjson Id from the provided string
.EXAMPLE
    Get-MyjsonIdFromString -StringContainingId "https://api.myjson.com/bins/a1a1a1a1"
.EXAMPLE
    Get-MyjsonIdFromString -StringContainingId "a1a1a1a1"
.INPUTS
    Myjson file url
.INPUTS
    Myjson file id
.OUTPUTS
    Myjson file id
#>
function Get-MyjsonIdFromString {
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # Myjson file url/id
        [Parameter(Mandatory = $true, 
                   ValueFromPipeline = $true)]
        [Alias("Url","Id")]
        [string]
        $StringContainingId
    )
    # Clean the string and lowercase
    $StringContainingId = $StringContainingId.Trim().ToLower()
    # Trim $this.Root from the string's start
    if ($StringContainingId.StartsWith($MyjsonUrlParameters.Root)) {
        $StringContainingId = $StringContainingId.Replace($MyjsonUrlParameters.Root, '')
    }
    # Trim $this.Path from the string's start
    if ($StringContainingId.StartsWith($MyjsonUrlParameters.Path)) {
        $StringContainingId = $StringContainingId.Replace($MyjsonUrlParameters.Path, '')
    }
    # Trim "?pretty=1" from the string's end
    if ($StringContainingId.EndsWith($MyjsonUrlParameters.Pretty)) {
        $StringContainingId = $StringContainingId.Replace($MyjsonUrlParameters.Pretty, '')
    }
    # Trim "/" from the string's start/end
    if ($StringContainingId.StartsWith('/') -or $StringContainingId.EndsWith('/')) {
        $StringContainingId = $StringContainingId.Trim('/')
    }
    return $StringContainingId
}
<#
.Synopsis
    Convert object to myjson file
.DESCRIPTION
    Converts an object to json and compresses to prepare for uploading
.EXAMPLE
    ConvertTo-Myjson -InputObject @{"key"="value"}
.INPUTS
    Any valid object with less than 100 layers
.OUTPUTS
    Id of the created myjson file
#>
function ConvertTo-Myjson {
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # Object to convert
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true)]
        $InputObject
    )
    $MyjsonId = ConvertTo-Json -InputObject $InputObject -Depth 100 -Compress
    return $MyjsonId
}
<#
.Synopsis
    Get myjson file
.DESCRIPTION
    Downloads myjson file and deserialises it to an object
.EXAMPLE
    Get-Myjson -Id "https://api.myjson.com/bins/a1a1a1a1"
.EXAMPLE
    Get-Myjson -Id "a1a1a1a1"
.INPUTS
    Id/Url of the myjson file
.OUTPUTS
    myjson file deserialised to pscustomobject
#>
function Get-Myjson {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    Param
    (
        # Myjson file url/id
        [Parameter(Mandatory = $true, 
                   ValueFromPipeline = $true)]
        [Alias("Url")]
        [string]
        $Id
    )
    $Id = Get-MyjsonIdFromString -StringContainingId $Id
    $Url = Join-MyjsonUrlString -StringContainingId $Id
    $outputObject = Invoke-RestMethod -Uri $Url -Method Get
    return $outputObject
}
<#
.Synopsis
    Update myjson file
.DESCRIPTION
    Updates exsisting myjson file wtih a provided object 
.EXAMPLE
    Set-Myjson -Id "https://api.myjson.com/bins/a1a1a1a1" -InputObject @{"key"="value"}
.EXAMPLE
    Set-Myjson -Id "a1a1a1a1" -InputObject @{"key"="value"}
.INPUTS
    Id/Url of the myjson file
.INPUTS
    Object to upload
#>
function Set-Myjson {
    [CmdletBinding()]
    Param
    (
        # Myjson file url/id
        [Parameter(Mandatory = $true)]
        [Alias("Url")]
        [string]
        $Id,
        # Object to upload
        [Parameter(Mandatory = $true, 
                   ValueFromPipeline = $true)]
        $InputObject
    )
    $Id = Get-MyjsonIdFromString -StringContainingId $Id
    $Url = Join-MyjsonUrlString -StringContainingId $Id
    $InputObject = ConvertTo-Myjson -InputObject $InputObject
    Invoke-RestMethod -Uri $Url -Method Put -ContentType application/json -Body $InputObject | Out-Null
}
<#
.Synopsis
    Create new myjson file
.DESCRIPTION
    Creates new myjson file from the provided object or creates empty if not provided
.EXAMPLE
    New-Myjson -InputObject @{"key"="value"}
.EXAMPLE
    New-Myjson
.INPUTS
    Object to upload
.OUTPUTS
    Id of the created myjson file
#>
function New-Myjson {
    [CmdletBinding()]
    [OutputType([string])]
    Param(
        # Object to upload
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )
    # If object was not provided initiate empty object
    if (-not $InputObject) {
        $InputObject = New-Object -TypeName pscustomobject
    }
    $InputObject = ConvertTo-Myjson -InputObject $InputObject
    $Url = Join-MyjsonUrlString
    $UriObject = Invoke-RestMethod -Uri $Url -Method Post -ContentType application/json -Body $InputObject
    $Url = Get-MyjsonIdFromString -StringContainingId $UriObject.uri
    return $Url
}