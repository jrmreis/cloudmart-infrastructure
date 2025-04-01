[workstation]
${workstation_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/id_rsa

[all:vars]
backend_ecr_repo=${backend_ecr_repo}
frontend_ecr_repo=${frontend_ecr_repo}
