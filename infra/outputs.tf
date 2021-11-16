output "resizeVm" {
  value = "https://${module.scaler.functionUrl}/api/resizeVm?code=${module.scaler.functionKey}"
  sensitive = true
}

output "scalePremiumDisk" {
  value = "https://${module.scaler.functionUrl}/api/scalePremiumDisk?code=${module.scaler.functionKey}"
  sensitive = true
}

output "scaleUltraDisk" {
  value = "https://${module.scaler.functionUrl}/api/scaleUltraDisk?code=${module.scaler.functionKey}"
  sensitive = true
}