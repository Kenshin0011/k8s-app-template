CHART_DIR := chart
RELEASE := my-app
NAMESPACE := my-app

.PHONY: lint template install uninstall

lint:
	helm lint $(CHART_DIR)

template:
	helm template $(RELEASE) $(CHART_DIR) --namespace $(NAMESPACE)

install:
	helm upgrade --install $(RELEASE) $(CHART_DIR) --namespace $(NAMESPACE) --create-namespace

uninstall:
	helm uninstall $(RELEASE) --namespace $(NAMESPACE)
