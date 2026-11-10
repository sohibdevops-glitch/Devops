# Get all pods in all namespaces in JSON format
Write-Output "Fetching all pods"
$rawJson = kubectl get pods --all-namespaces -o json
$podsJson = $rawJson | ConvertFrom-Json

Write-Output "Fetched all pods"
# Loop through each pod and extract ownerReferences

Write-Output "These are the orphan pods"
Write-Output "==============================="
foreach ($pod in $podsJson.items) {

    $namespace = $pod.metadata.namespace
    $podName = $pod.metadata.name
    $ownerRefs = $pod.metadata.ownerReferences

    if(-not $ownerRefs -or $ownerRefs.Count -eq 0){
        Write-Output "Namespace: $namespace, Pod: $podName, Owner: None (Orphan)"
    }
}

Write-Output "==============================="
Write-Output "End of the orphan pods"
