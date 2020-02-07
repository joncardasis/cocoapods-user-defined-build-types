# List of depdendencies and their transitive depdendencies' names.
def transitive_dependencies(all_pods, pod_names)
  hash = Hash[all_pods.map {|key| [key.name, key.dependent_targets]}]
  dependencies = pod_names
  pod_names.each do |pod_name|
    hash[pod_name].each do |subpod|
      dependencies.push(subpod.name) if !dependencies.include?(subpod.name)
    end
  end
  dependencies
end 