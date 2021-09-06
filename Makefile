
# For local use
install-images:
	az acr login --name k8scc01covidacr
	yq -j e '.images[]' kustomization.yaml | \
		jq -r '@text "\(.newName):\(.newTag)"' | \
		xargs -I{} docker pull {}

	yq -j e '.images[]' kustomization.yaml | \
		jq -r '@text "\(.newName):\(.newTag)"' | \
		xargs -I{} kind load docker-image {} --name argoflow
