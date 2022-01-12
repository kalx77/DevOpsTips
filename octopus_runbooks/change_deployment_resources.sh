deployment=$(get_octopusvariable "deployment_to_restart")
namespace=$(get_octopusvariable "namespace")
tenant=$(get_octopusvariable "Octopus.Tentacle.CurrentDeployment.TargetedRoles")
cpu_limits=$(get_octopusvariable "cpu_limits")
memory_limits=$(get_octopusvariable "memory_limits")
cpu_requests=$(get_octopusvariable "cpu_requests")
memory_requests=$(get_octopusvariable "memory_requests")

if [[ "$tenant" == "$namespace" ]]; then

  if [[ -z $cpu_limits ]]; then
    cpu_limits=$(kubectl get deployment $deployment -n $namespace -o jsonpath="{.spec.template.spec.containers[].resources.limits.cpu}")
  else
    echo -e "Changing CPU limits to $cpu_limits"
  fi

  if [[ -z $memory_limits ]]; then
    memory_limits=$(kubectl get deployment $deployment -n $namespace -o jsonpath="{.spec.template.spec.containers[].resources.limits.memory}")
  else
    echo -e "Changing CPU limits to $memory_limits"
  fi

  if [[ -z $cpu_requests ]]; then
    cpu_requests=$(kubectl get deployment $deployment -n $namespace -o jsonpath="{.spec.template.spec.containers[].resources.requests.cpu}")
  else
    echo -e "Changing CPU limits to $cpu_requests"
  fi

  if [[ -z $memory_requests ]]; then
    memory_requests=$(kubectl get deployment $deployment -n $namespace -o jsonpath="{.spec.template.spec.containers[].resources.requests.memory}")
  else
    echo -e "Changing CPU limits to $memory_requests"
  fi

  echo -e "New parameters for deployment $deployment is:\nCPU limits: $cpu_limits\nMemory limits: $memory_limits\nCPU requests: $cpu_requests\nMemory requests: $memory_requests"
  kubectl set resources deployment $deployment -c $deployment \
          --limits=cpu=$cpu_limits,memory=$memory_limits \
          --requests=cpu=$cpu_requests,memory=$memory_requests
else
	echo "There is nothing to do here!:)"
fi
