# Scaling Azure infra resources using Azure Functions
This repo contains example code for scaling VM size, PremiumSSD performance tier and UltraSSD IOPS and throughput. It is to be used by VMs to scale-up before large batch operation and scale-down when job is complete. Reasons to provide this as Azure Function external to VM rather than calling Azure API directly for VM:
- Ability to isolate VM from Internet (no public outbound - Azure Function can be called via Private Link)
- Separate logging and governance of such operations
- No need for direct RBAC to Azure from VM (code in VM is not fully trusted)

# Deployment
Create archive with functions code.

```bash
cd functions
zip -r ../infra/functions.zip .
```

Deploy demo. Deployment of Azure Functions is done via scaler module for simple reuse.

```bash
cd infra
terraform init
terraform plan
terraform apply -auto-approve
```

Test

```bash
# Resize VM
curl "$(terraform output -raw resizeVm)&name=test-machine&resourcegroup=scale-test-rg&size=Standard_D8s_v3"

# Change PremiumSSD performance tier
curl "$(terraform output -raw scalePremiumDisk)&name=premium-disk1&resourcegroup=scale-test-rg&tier=P40"
curl "$(terraform output -raw scalePremiumDisk)&name=premium-disk2&resourcegroup=scale-test-rg&tier=P40"

# Change UltraSSD IOPS and throughput
curl "$(terraform output -raw scaleUltraDisk)&name=ultra-disk1&resourcegroup=scale-test-rg&DiskIOPSReadWrite=2000&DiskMBpsReadWrite=150"
curl "$(terraform output -raw scaleUltraDisk)&name=ultra-disk2&resourcegroup=scale-test-rg&DiskIOPSReadWrite=2000&DiskMBpsReadWrite=150"

```

Destroy

```bash
terraform destroy -auto-approve
```

<a href="README.md" download="README.md">test</a>
