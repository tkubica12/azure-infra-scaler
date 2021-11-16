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
if (-not $rg) {
    $rg = $Request.Body.ResourceGroup
}
$tier = $Request.Query.Tier
if (-not $tier) {
    $tier = $Request.Body.Tier
}

Write-Host "Name: $name"
Write-Host "ResourceGroup: $rg"
Write-Host "Tier: $tier"

$response = ""

if ($name -And $rg -And $tier) {
    $disk = Get-AzDisk -ResourceGroupName $rg -DiskName $name -ErrorAction SilentlyContinue
    if ($disk) {
        Write-Host "Disk found"
        $diskUpdateConfig = New-AzDiskUpdateConfig -Tier $tier
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
    $response = "Please pass a name, resource group and tier on the query string or in the request body"
    $statusCode = [HttpStatusCode]::BadRequest
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $statusCode
    Body = $response
})
