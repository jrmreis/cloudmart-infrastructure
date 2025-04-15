# CloudMart Ansible Project

Ansible automation for deploying the CloudMart application infrastructure.
on Ec2:
ansible-playbook ansible/cloudmart_setup.yml -i 'localhost,' --connection=local

ansible-playbook ansible/playbooks/cloudmart_setup.yml -i 'localhost,' --connection=local --extra-vars "@ansible/group_vars/all.yml"

ansible-playbook ansible/playbooks/cloudmart_setup.yml -i 'localhost,' --connection=local --extra-vars "@ansible/group_vars/all.yml" -e "ansible_python_interpreter=/usr/bin/python3"



## Project Structure

- `ansible/playbooks/`: Playbook files
- `ansible/roles/`: Role definitions
- `ansible/group_vars/`: Group variables
- `ansible/inventory/`: Environment-specific inventories

## Prerequisites

1. Install required collections:

```bash
ansible-galaxy collection install -r ansible/collections/requirements.yml


# Only run Docker setup
ansible-playbook -i ansible/inventory/homol.ini ansible/playbooks/cloudmart_setup.yml --tags docker

Run specific tasks only:
You can use tags to run only specific parts of the playbook:


# Only run application deployment
ansible-playbook -i ansible/inventory/homol.ini ansible/playbooks/cloudmart_setup.yml --tags application

# Run multiple tagged tasks
ansible-playbook -i ansible/inventory/homol.ini ansible/playbooks/cloudmart_setup.yml --tags "docker,application"

# Only run Docker setup
ansible-playbook -i ansible/inventory/homol.ini ansible/playbooks/cloudmart_setup.yml --tags docker

# Only run application deployment
ansible-playbook -i ansible/inventory/homol.ini ansible/playbooks/cloudmart_setup.yml --tags application

# Run multiple tagged tasks
ansible-playbook -i ansible/inventory/homol.ini ansible/playbooks/cloudmart_setup.yml --tags "docker,application"

----

# Run a syntax check
ansible-playbook -i ansible/inventory/homol.ini ansible/playbooks/cloudmart_setup.yml --syntax-check

# Run the playbook in dry-run mode
ansible-playbook -i ansible/inventory/homol.ini ansible/playbooks/cloudmart_setup.yml --check
