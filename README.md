# ContainerWatch

A containerized monitoring and logging stack (Prometheus, Grafana, Node Exporter,
cAdvisor, Alertmanager) that observes a sample Flask application, deployed on AWS
with Terraform, Docker Compose, GitHub Actions CI/CD and Amazon CloudWatch Logs.

ITC583 Cloud Computing — Final Project · Individual project · Region: us-east-1

---

## 1. Repository layout

```
containerwatch/
├── app/                              # Flask sample application
│   ├── app.py                        # instrumented endpoints + /metrics
│   ├── requirements.txt
│   └── Dockerfile
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus.yml            # scrape + alerting configuration
│   │   └── alerts.yml                # 6 alert rules
│   ├── alertmanager/
│   │   └── alertmanager.yml          # routing, grouping, inhibition
│   └── grafana/
│       ├── provisioning/
│       │   ├── datasources/prometheus.yml
│       │   └── dashboards/dashboard.yml
│       └── dashboards/containerwatch-overview.json
├── terraform/
│   ├── main.tf                       # VPC, subnet, IGW, SG, EC2
│   ├── iam.tf                        # role, policy, instance profile
│   ├── logs.tf                       # CloudWatch log group
│   ├── variables.tf / outputs.tf
│   ├── user_data.sh                  # instance bootstrap
│   └── terraform.tfvars.example
├── .github/workflows/deploy.yml      # CI/CD pipeline
├── docker-compose.yml                # six-service stack (CloudWatch logging)
├── docker-compose.local.yml          # local override (json-file logging)
├── .gitignore
└── README.md
```

## 2. Local execution (no AWS account required)

The default Compose file uses the `awslogs` driver, which needs AWS credentials.
For a workstation run, add the local override, which switches to `json-file`
logging and also publishes Prometheus and Alertmanager on localhost:

```bash
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d --build
```

| Service            | Local URL                |
|--------------------|--------------------------|
| Sample application | http://localhost:8000    |
| Grafana            | http://localhost:3000    |
| Prometheus         | http://localhost:9090    |
| Alertmanager       | http://localhost:9093    |

Stop with `docker compose -f docker-compose.yml -f docker-compose.local.yml down -v`.

## 3. AWS deployment

Prerequisites: an AWS account with credentials configured, Terraform >= 1.6, an
existing EC2 key pair, and a public GitHub repository containing this code.

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# set admin_cidr (your public IP /32), key_name and repo_url
cd terraform
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Terraform creates the VPC, public subnet, internet gateway, route table,
security group, IAM role and instance profile, CloudWatch log group and the EC2
instance. `user_data.sh` then installs Docker and the Compose v2 plugin, clones
the repository, writes `.env` (region, log group, generated Grafana password)
and starts the stack. Allow about three minutes after `apply` before the URLs
respond.

Retrieve the generated Grafana password from the instance:

```bash
ssh ec2-user@$(terraform output -raw public_ip) "sudo grep GF_ADMIN_PASSWORD /opt/containerwatch/.env"
```

## 4. CI/CD configuration

Add two repository secrets under Settings → Secrets and variables → Actions:

| Secret        | Value                                                        |
|---------------|--------------------------------------------------------------|
| `EC2_HOST`    | `terraform output -raw public_ip`                             |
| `EC2_SSH_KEY` | Private key of the key pair named in `key_name` (full PEM)    |

Every push and pull request runs the `validate` job (`terraform fmt/init/validate`,
`docker compose config`, `promtool check config`, `promtool check rules`,
`amtool check-config`, dashboard JSON parsing). Only pushes to `main` that pass
validation run the `deploy` job, which pulls and rebuilds the stack over SSH.

## 5. Testing the alerts

```bash
# generate load and errors for the dashboards and latency alerts
hey -z 120s -c 20 http://<public-ip>:8000/work
# or, without hey installed
while true; do curl -s -o /dev/null http://<public-ip>:8000/work; done

# trigger TargetDown: stop the monitored container and wait one minute
ssh ec2-user@<public-ip> "cd /opt/containerwatch && docker compose stop sample-app"

# Prometheus and Alertmanager are internal-only; reach them with an SSH tunnel
ssh -L 9090:localhost:9090 -L 9093:localhost:9093 ec2-user@<public-ip>
```

Restart the container with `docker compose start sample-app`.

## 6. Teardown

```bash
cd terraform && terraform destroy -auto-approve
```
