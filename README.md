# cloudmart-infrastructure

ansible-playbook ansible/playbooks/cloudmart_setup.yml -i 'localhost,' --connection=local -e "ansible_python_interpreter=/usr/bin/python3" -e "@ansible/group_vars/combined.yml"

on Ec2:
ansible-playbook ansible/cloudmart_setup.yml -i 'localhost,' --connection=local
