environment=$(get_octopusvariable "Octopus.Environment.Name" | tr '[:upper:]' '[:lower:]')
namespace=$(get_octopusvariable "namespace")
tenant=$(get_octopusvariable "Octopus.Tentacle.CurrentDeployment.TargetedRoles")

if [[ "$tenant" == "$namespace" ]]; then
	if [[ "$tenant" == "scenarios-runtime" ]]; then

    deployments=$(kubectl get deployment -o custom-columns=:metadata.name | grep $tenant-$environment)

    for deployment in ${deployments[@]}
    do
    echo "Restart $deployment deployment"
    kubectl rollout restart deployment $deployment -n $namespace && kubectl rollout status deployment $deployment -n $namespace
    done

  else

    deployments=$(kubectl get deployment -o custom-columns=:metadata.name | grep $tenant)

    for deployment in ${deployments[@]}
    do
    echo "Restart $deployment deployment"
    kubectl rollout restart deployment $deployment -n $namespace && kubectl rollout status deployment $deployment -n $namespace
    done

  fi
else
	echo "There is nothing to do here!:)"
fi
