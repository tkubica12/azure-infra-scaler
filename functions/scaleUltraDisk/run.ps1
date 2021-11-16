using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

Write-Host "Changing Premium disk performance tier"

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}
$rg = $Request.Query.ResourceGroup
if (-not $name) {
    $name = $Request.Body.ResourceGroup
}
$DiskIOPSReadWrite = $Request.Query.DiskIOPSReadWrite
if (-not $DiskIOPSReadWrite) {
    $DiskIOPSReadWrite = $Request.Body.Tier
}
$DiskMBpsReadWrite = $Request.Query.DiskMBpsReadWrite
if (-not $DiskMBpsReadWrite) {
    $DiskMBpsReadWrite = $Request.Body.DiskMBpsReadWrite
}

Write-Host "Name: $name"
Write-Host "ResourceGroup: $rg"
Write-Host "DiskIOPSReadWrite: $DiskIOPSReadWrite"
Write-Host "DiskMBpsReadWrite: $DiskMBpsReadWrite"

$response = ""

if ($name -And $rg -And $DiskIOPSReadWrite -And $DiskMBpsReadWrite) {
    $disk = Get-AzDisk -ResourceGroupName $rg -DiskName $name -ErrorAction SilentlyContinue
    if ($disk) {
        Write-Host "Disk found"
        $diskUpdateConfig = New-AzDiskUpdateConfig -DiskIOPSReadWrite $DiskIOPSReadWrite -DiskMBpsReadWrite $DiskMBpsReadWrite
        $result = Update-AzDisk -DiskName $name -DiskUpdate $diskUpdateConfig -ResourceGroupName $rg -ErrorAction SilentlyContinue
        if ($result.ProvisioningState -Eq "Succeeded") {
            Write-Host "Disk updated"
            $statusCode = [HttpStatusCode]::OK
            $response = "OK"
        } else {
            Write-Host "Disk update failed"
            $statusCode = [HttpStatusCode]::BadRequest
            $response = (get-error).Exception.Message
        }
    } else { 
        $statusCode = [HttpStatusCode]::BadRequest
        $response = "Disk not found"
    }
} else {
    $response = "Please pass a name, resource group, DiskIOPSReadWrite and DiskMBpsReadWrite on the query string or in the request body"
    $statusCode = [HttpStatusCode]::BadRequest
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $statusCode
    Body = $response
})
