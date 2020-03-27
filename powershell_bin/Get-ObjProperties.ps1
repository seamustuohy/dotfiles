# WTFIsThat
Param(
        [Parameter(Mandatory=$true)]
        $ObjectToCheck
    )

$ObjectToCheck.PSObject.Properties | ForEach-Object {
    $_.Name
    $_.Value
}
