Infrastructure Setup:

VPC with public subnets

Internet Gateway & routing

Security Group for ALB

Deployment:

ECS Cluster creation

Task definition using Docker Hub image (baddamharika/strapi-app:v3)

Fargate service with ALB integration

Access:

Application Load Balancer provides public access to Strapi admin.
