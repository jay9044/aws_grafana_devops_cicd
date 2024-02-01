# Project Aim

To deploy Grafana and Prometheus to an arbitrary amount of EC2 instances using a Gitops CICD workflow that utilizes Terraform, Jenkins, and Ansible. And hopefully, stay within the AWS free tier ;) 

# Terraform
With DRY concepts in mind, I am using Terraform to deploy AWS resources using best practices.

# Ansible
Used to perform configuration management on EC2 instances to install the software needed, i.e. to deploy Jenkins onto EC2 instances.

# Jenkins
Deploy deployments created in Terraform and Ansible in a controlled way that allows me to manage errors and issues that may arise during the deployment process. All triggered from a git push, of course.
