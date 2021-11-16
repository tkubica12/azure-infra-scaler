using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

Write-Host "Resizing VM"

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}
$rg = $Request.Query.ResourceGroup
if (-not $rg) {
    $rg = $Request.Body.ResourceGroup
}
$size = $Request.Query.Size
if (-not $size) {
    $size = $Request.Body.Size
}

Write-Host "Name: $name"
Write-Host "ResourceGroup: $rg"
Write-Host "Size: $size"

$response = ""

if ($name -And $rg -And $size) {
    $vm = Get-AzVM -ResourceGroupName $rg -VMName $name -ErrorAction SilentlyContinue
    if ($vm) {
        Write-Host "VM found"
        $vm.HardwareProfile.VmSize = $size
        $result = Update-AzVM -VM $vm -ResourceGroupName $rg -ErrorAction SilentlyContinue
        if ($result.IsSuccessStatusCode) {
            Write-Host "VM updated"
            $statusCode = [HttpStatusCode]::OK
            $response = "OK"
        } else {
            Write-Host "VM update failed"
            $statusCode = [HttpStatusCode]::BadRequest
            $response = (get-error).Exception.Message
        }
    } else { 
        $statusCode = [HttpStatusCode]::BadRequest
        $response = "VM not found"
    }
} else {
    $response = "Please pass a name, resource group and size on the query string or in the request body"
    $statusCode = [HttpStatusCode]::BadRequest
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $statusCode
    Body = $response
})
