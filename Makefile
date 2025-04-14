.PHONY: lint deploy-homol deploy-staging deploy-prod

lint:
	ansible-lint

deploy-homol:
	ansible-playbook -i ansible/inventory/homol.ini ansible/playbooks/cloudmart_setup.yml

deploy-staging:
	ansible-playbook -i ansible/inventory/staging.ini ansible/playbooks/cloudmart_setup.yml

deploy-prod:
	ansible-playbook -i ansible/inventory/production.ini ansible/playbooks/cloudmart_setup.yml

deploy-tagged:
	ansible-playbook -i ansible/inventory/$(ENV).ini ansible/playbooks/cloudmart_setup.yml --tags $(TAGS)
