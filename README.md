# cloudmart-infrastructure - Homol

on Ec2: ansible-playbook ansible/cloudmart_setup.yml -i 'localhost,' --connection=local -vvv
        ansible-playbook ansible/playbooks/main.yml -i 'localhost,' --connection=local -vvv


# Check pod logs
kubectl logs cloudmart-backend-bb5d549dc-4csgb
kubectl logs cloudmart-frontend-7f678d7d97-bx5zp

# Get detailed information about pods
kubectl describe pod cloudmart-backend-bb5d549dc-4csgb
