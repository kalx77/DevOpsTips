deployment=$(get_octopusvariable "deployment_to_restart")
replicas=$(get_octopusvariable "new_replicas_number")
namespace=$(get_octopusvariable "namespace")
tenant=$(get_octopusvariable "Octopus.Tentacle.CurrentDeployment.TargetedRoles")
if [[ "$tenant" == "$namespace" ]]; then
	kubectl scale --replicas=$replicas deployment $deployment -n $namespace
else
	echo "There is nothing to do here!:)"
fi
