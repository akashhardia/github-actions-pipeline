# **CI/CD Pipeline Documentation**

This document provides a detailed guide on integrating and using the CI/CD pipeline for deploying a Rails application and Sidekiq workers, along with Slack notifications for deployment success or failure. The pipeline is built using GitHub Actions and supports ECS service deploymens to stg & prd environments.

---

## **Overview**

The pipeline automates:

- Running tests using Docker Compose.
- Building and pushing Docker images to Amazon Elastic Container Registry (ECR).
- Running database migrations.
- Deploying to Amazon ECS using task definitions.
- Sending Slack notifications about deployment status.

### **Key Features**

- Handles deployments for both staging (`stg`) and production (`prd`) environments.
- Uses conditional logic to ensure smooth environment-specific deployments.
- Integrates Slack notifications for monitoring deployment outcomes.

---

## **Prerequisites**
This pipeline requires few things as pre-requisites

### **AWS Resources**
- Amazon ECR registry is set up:
  - pst-gt-prd-rails
  - pst-gt-stg-rails
  - pst-gt-prd-nginx
  - pst-gt-stg-nginx

- ECS clusters, task definitions, and services are configured for your application and Sidekiq workers in both staging and production environments:
  - task dfn
    - pst-gt-prd
    - pst-gt-stg
    - pst-gt-prd-sidekiq  (also used for migrations)
    - pst-gt-stg-sidekiq  (also used for migrations)
  - cluster & their respective services
    - pst-gt-prd-cluster
    - pst-gt-stg-cluster

- Required subnets and security groups are available.

### **GitHub Secrets and Variables**

Add the following secrets and variables to your GitHub repository:

#### **Secrets**
- `AWS_ACCESS_KEY`: Your AWS Access Key ID.
- `AWS_SECRET_ACCESS_KEY`: Your AWS Secret Access Key.
- `SLACK_WEBHOOK`: Webhook URL for Slack notifications.
- `AWS_ECR_URL`: Amazon ECR repository URL.

#### **Variables**
- `REGISTRY_NAME`: Prefix for your ECR images. *for every environment*

### **Docker Configuration**
- Ensure your application has proper Dockerfiles for both `rails` and `nginx`.
- Provide a `docker-compose-test.yaml` file for running tests.

### **Environment Variables**
Update the environment variables in the workflow file to match your AWS setup:

```yaml
env:
  ECR_ACCOUNT_ID: <Your AWS Account ID>
  AWS_REGION: <AWS Region>
  STG_SG: <Staging Security Group>
  STG_SUBNET: <Staging Subnet>
  PRD_SG: <Production Security Group>
  PRD_SUBNET: <Production Subnet>
```


----

## **Pipeline Configuration**

### **Triggers**

The pipeline triggers on:
- Push events to `main`, `stg`, and `prd` branches.
- Pull requests to any branch.



### **Pipeline Jobs**

#### **1. Test**

**Purpose:** Ensures the application passes all tests using Docker Compose.

##### **Key Steps**
- Sets up Docker.
- Builds images using `docker-compose-test.yaml`.
- Launches necessary services (e.g., MySQL and Redis).
- Runs database migrations and tests.


#### **2. Build**

**Purpose:** Builds and pushes Docker images for `rails` and `nginx` services.
**Environment:** Staging or Production.

##### **Conditions**
- Executes only if tests succeed.
- Runs only on `stg` or `prd` branches.

##### **Key Steps**
- Builds images from respective Dockerfiles.
- Pushes images to Amazon ECR.



#### **3. Migrations**

**Purpose:** Runs database migrations using ECS Fargate tasks.
**Environment:** Staging or Production.

##### **Conditions**
- Executes only if the build succeeds.
- Runs only on `stg` or `prd` branches.
- selects the environments & resources dynamically based on branch.

##### **Key Steps**
- Updates the ECS task definition with the new image.
- Runs the task using `bundle exec rails db:migrate` using sidkkiq's task defn



#### **4. Deploy-Web**

**Purpose:** Deploys the web application to ECS.
**Environment:** Staging or Production.

##### **Conditions**
- Executes only if migrations succeed.
- Runs only on `stg` or `prd` branches.
- selects the environments & resources dynamically based on branch.

##### **Key Steps**
- Updates the ECS task definition with the new image.
- Deploys the rails service to the ECS cluster by deploying the docker container.

#### **5. Deploy-Sidekiq**

**Purpose:** Deploys the Sidekiq worker service to ECS.
**Environment:** Staging or Production.

##### **Conditions**
- Executes only if migrations succeed.
- Runs only on `stg` or `prd` branches.
- selects the environments & resources dynamically based on branch.

##### **Key Steps**
- Updates the ECS task definition with the new image.
- Deploys the sidekiq service to the ECS cluster by using sidekiq task dfn.
- runs command inside the container: bundle,exec,sidekiq,--environment,<environment-name>,-C,config/sidekiq.yml,-r,/app



#### **6. Notify-Success**

**Purpose:** Sends a Slack notification if the deployment is successful. Uses slack-notify.yaml workflow.

##### **Conditions**
- Executes only if both `deploy-web` and `deploy-sidekiq` succeed.




#### **7. Notify-Failure**

**Purpose:** Sends a Slack notification if the deployment fails. Uses slack-notify.yaml workflow.

##### **Conditions**
- Executes if either `deploy-web` or `deploy-sidekiq` fails.





### **Usage Instructions**

#### **Setup GitHub Repository**
- Copy the workflow YAML file to `.github/workflows/deploy.yaml` in your repository.
- Copy the slack workflow YAML file to `.github/workflows/slack-notify.yaml` in your repository.


#### **Update AWS Resources**
- Modify ECS cluster, service names, and security group/subnet values in the workflow file.

#### **Test Locally**
- Validate Dockerfiles and `docker-compose-test.yaml` locally.

#### **Integrate Secrets**
- Add required secrets (`AWS_ACCESS_KEY`, `AWS_SECRET_ACCESS_KEY`, `SLACK_WEBHOOK`, etc.) in GitHub.

#### **Validate Notifications**
- Ensure Slack notifications are properly configured and reachable.




### **Things to Keep in Mind**

#### **AWS Limits**
- Ensure your ECS cluster has sufficient resources for Fargate tasks.
- Monitor ECR storage usage.

#### **Slack Webhook**
- Test the webhook URL before integrating into the pipeline.

#### **Branch-Specific Configurations**
- Ensure branches like `stg` and `prd` align with your Git branching strategy.

#### **Timeouts**
- Adjust ECS task `wait-for-minutes` values based on application deployment times.
