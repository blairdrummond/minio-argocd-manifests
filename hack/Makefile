VAULT_SERVICE_ACCOUNT_NAME := vault-sa


# Handy
OKBLUE := '\033[94m'
OKCYAN := '\033[96m'
OKGREEN := '\033[92m'
WARNING := '\033[93m'
FAIL := '\033[91m'
ENDC := '\033[0m'
BOLD := '\033[1m'



argo-get-pass:
	@printf $(OKGREEN)
	@printf $(BOLD)
	@echo "ArgoCD Login"
	@echo "=========================="
	@echo "ArgoCD Username is: admin"
	@printf "ArgoCD Password is: %s\n" $$(kubectl -n argocd \
		get secret argocd-initial-admin-secret \
		-o jsonpath="{.data.password}" | base64 -d)
	@echo "=========================="
	@printf $(ENDC)


profile-crd:
	kubectl apply -f kubeflow.org_profiles.yaml

helm:
	helm repo add hashicorp https://helm.releases.hashicorp.com
	helm repo add statcan https://statcan.github.io/charts

vault: helm
	kubectl create namespace vault-system || true
	kubectl label  namespace vault-system istio-injection=enabled --overwrite || true
	helm install -n vault-system -f vault-values.yaml vault hashicorp/vault

vault-minio:
	export VAULT_ADDR=http://localhost:8200; \
	CREDS_FILE=$$(find . -name 'vault-cluster-vault*.json'); \
	echo "$$CREDS_FILE"; \
	vault login token=$$(jq -r '.root_token' "$$CREDS_FILE"); \
	vault plugin register -sha256=$$(kubectl exec -n vault-system vault-0 sha256sum /plugins/vault-plugin-secrets-minio | awk '{print $$1}') \
		secret vault-plugin-secrets-minio

configure-vault-kubernetes:
	CREDS_FILE=$$(find . -name 'vault-cluster-vault*.json'); \
	echo "$$CREDS_FILE"; \
	export VAULT_ADDR=http://localhost:8200; \
	vault login token=$$(jq -r '.root_token' "$$CREDS_FILE"); \
	vault auth enable kubernetes; \
	echo "Configure Vault with the service account jwt"; \
	export VAULT_SA_NAME=$$(kubectl -n default get sa $(VAULT_SERVICE_ACCOUNT_NAME) -o jsonpath="{.secrets[*]['name']}"); \
	export SA_JWT_TOKEN=$$(kubectl -n default get secret $$VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo); \
	export SA_CA_CRT=$$(kubectl -n default get secret $$VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo); \
	export K8S_HOST=https://kubernetes.default.svc.cluster.local; \
	vault write auth/kubernetes/config \
		issuer="https://kubernetes.default.svc.cluster.local" \
		token_reviewer_jwt="$$SA_JWT_TOKEN" \
		kubernetes_host=$$K8S_HOST \
		kubernetes_ca_cert="$$SA_CA_CRT" || true

	export VAULT_ADDR=http://localhost:8200; \
	vault write auth/kubernetes/role/argocd \
		bound_service_account_names=$(VAULT_SERVICE_ACCOUNT_NAME) \
		bound_service_account_namespaces=argocd \
		policies=argocd \
		ttl=1h

	export VAULT_ADDR=http://localhost:8200; \
	vault policy write argocd argocd-policy.hcl

	export VAULT_ADDR=http://localhost:8200; \
	CREDS_FILE=$$(find . -name 'vault-cluster-vault*.json'); \
	vault login token=$$(jq -r '.root_token' "$$CREDS_FILE"); \
	vault secrets enable -version=2 -path=argocd kv || true

	export VAULT_ADDR=http://localhost:8200; \
	vault kv put argocd/my-secret my-value=supersecret



vault-port-forward:
	kubectl port-forward -n vault-system svc/vault-ui 8200:8200
