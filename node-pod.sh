#!/bin/bash
function match_pods_with_nodegroup {
    local namespace_filter=${1:-"--all-namespaces"}
    # Check if kubectl and jq are installed
    if ! command -v kubectl &> /dev/null || ! command -v jq &> /dev/null; then
        echo "Please ensure both kubectl and jq are installed to run this script."
        exit 1
    fi
    # Get nodes and their nodegroup_type labels
    echo "Fetching nodes with their nodegroup_type labels..."
    nodes=$(kubectl get nodes -o json | jq -r '.items[] | select(.metadata.labels.nodegroup_type) | "\(.metadata.name) \(.metadata.labels.nodegroup_type)"')
    # Header for the table
    printf "%-15s %-15s %-15s %-25s\n" "Namespace" "Nodegroup Type" "Status" "Pod"
    echo "--------------------------------------------------------------------------------------"
    while IFS= read -r line; do
        node=$(echo $line | awk '{print $1}')
        nodegroup_type=$(echo $line | awk '{print $2}')
        # Get pods running on the matched node
        if [[ "$namespace_filter" == "--all-namespaces" ]]; then
            kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=$node | awk -v nodegroup_type="$nodegroup_type" 'NR>1 {printf "%-15s %-15s %-15s %-25s\n", $1, nodegroup_type, $3, $2}'
        else
            kubectl get pods -n $namespace_filter -o wide --field-selector spec.nodeName=$node | awk -v nodegroup_type="$nodegroup_type" 'NR>1 {printf "%-15s %-15s %-15s %-25s\n", $3, nodegroup_type, $1 , $2}'
        fi
    done <<< "$nodes"
}

match_pods_with_nodegroup $1
