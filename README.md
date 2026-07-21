# ContainerWatch

ContainerWatch is a containerized monitoring and centralized logging stack deployed on Amazon Web Services. It monitors a sample Flask web application with Prometheus, visualizes metrics in Grafana, routes alerts through Alertmanager, collects host and container metrics with Node Exporter and cAdvisor, and sends container logs to Amazon CloudWatch Logs.

## Project components

- Flask and gunicorn sample application
- Docker and Docker Compose
- Prometheus
- Grafana
- Alertmanager
- Node Exporter
- cAdvisor
- Amazon EC2, VPC, IAM, and CloudWatch Logs
- Terraform Infrastructure as Code
- GitHub Actions CI/CD

## Repository structure

```text
containerwatch/
├── app/
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
├── monitoring/
│   ├── prometheus/
│   ├── alertmanager/
│   └── grafana/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── user_data.sh
│   └── terraform.tfvars.example
├── .github/workflows/deploy.yml
├── docker-compose.yml
└── README.md
```

## Quick deployment

1. Install Git, Docker, AWS CLI, and Terraform.
2. Create a public GitHub repository and upload this project.
3. Configure AWS credentials with `aws configure`.
4. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars`.
5. Set `admin_cidr` to your public IP followed by `/32`.
6. Set `repo_url` to your GitHub repository clone URL.
7. Run:

```bash
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

8. Open the application and Grafana URLs shown by Terraform.
9. Generate traffic by visiting `/work` repeatedly.
10. Test alerting by stopping the sample application container.
11. Verify logs in the CloudWatch log group `/containerwatch/containers`.
12. After grading, run `terraform destroy` to avoid continuing AWS charges.

## Security notes

- Never commit AWS credentials, `.env`, private SSH keys, Terraform state, or passwords.
- Restrict SSH and Grafana to your own `/32` public IP.
- Change the Grafana administrator password immediately after deployment.
- Destroy cloud resources after the project is graded.
