hpa_name=$(get_octopusvariable "hpa_name")
max_replicas=$(get_octopusvariable "max_replicas")
namespace=$(get_octopusvariable "namespace")
tenant=$(get_octopusvariable "Octopus.Tentacle.CurrentDeployment.TargetedRoles")

cat <<EOF >> change.json
{
  "spec": {
  "maxReplicas": $max_replicas
  }
}
EOF

if [[ "$tenant" == "$namespace" ]]; then
  echo "Change number of maximal replicas for HPA $hpa_name to $max_replicas"
  kubectl patch hpa $hpa_name -p  "$(cat change.json)" -n $namespace
  rm change.json
else
  echo "There is nothing to do here!:)"
fi
