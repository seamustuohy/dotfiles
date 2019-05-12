Param(
        [Parameter(Mandatory=$true)]
        $ObjectToCheck
    )
# WTFIsThat

$ObjectToCheck.PSObject.Properties | ForEach-Object {
    $_.Name
    $_.Value
}
