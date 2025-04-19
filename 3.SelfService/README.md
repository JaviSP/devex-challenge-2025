# Self-Service Capabilities
The solution I propose is to build this particular self-service through GitHub Actions. 

GitHub Actions provides a tool that is familiar to the developers and easy to use. Thanks to the `workflow_dispatch` events, it offers a simple web form to input the necesary parameters needed to execute the Terraform module: S3 bucket name, AWS Account, versioning and encryption.

Note that, although this approach offers a quick and labour-saving result, it is not a tool that allows for easy scaling in number and complexity of self-service tasks.

## Overview
Essentially, the overview of the workflow consists of the following steps:
1. Validation of the user inputs.
2. Generate a folder with the bucket configuration and push it to the repository.
3. Perform a terraform plan and apply with the inputs.
4. Output the relevant information in the summary of the workflow run.

## Considerations
Following is a list of aspects that I consider the solution should comply.

### User management
The management of users is handled by GitHub. This workflow should be in a repository accesible by the group of developers that are allowed to create a S3 bucket.

If a bit complex management is needed, for example some developers may have access to create a bucket in Staging and others only in Production (or both envs), it could be addressed defining a group of users for each environment and check in the workflow if the user belongs to the group selected as input. 

More complex situations would probably complicate this solution considerably.

### Credentials management (access AWS envs)
Access to the AWS environments is easly configurable via [OpenID Connect (OIDC)](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services). This offers a secure way to access the AWS resources from the workflow.

The workflow will leverage the environment capabilities of GitHub repository, defining one for each AWS Account. This way the workflow will be able to access every AWS Account with just 1 implementation of the workflow.

### Terraform State
Despite the posibility of managing all S3 buckets in a single Terraform state is the most straightforward approach, I believe it will lead to conflicts and deadlocks. In addition, the state will grow steadily, making executions slower and slower and increasing the risk of corruption.

I believe that a strategy of maintaining small states is more appropriate to improve isolation and scalability, while maintaining more granular control that will facilitate recoveries and rollbacks.

To achieve this strategy I propose to use Terragrunt to invoke the Terraform module, because it allows to define the `backend` block dynamically. I propose to use a terraform state per bucket, but it is possible to manage an state per Account or even per project (in this case the project should be a new input of the workflow).

Finally, I consider that it is essential to have versioning and backups for each state, for which I propose that they will be stored in a specific S3 bucket for them, from where this maintenance can be carried out.

### Concurrency
To manage concurrent executions and avoid update the state simultanously, the State Locking option can be enabled in the `backend` block configuration.

In addition to this, the workflow will have the concurrency control configured, using the key `<aws-account>@<bucket-name>` as the concurrency `group`. This way, concurrent executions for the same bucket and AWS account will be avoided. Of course, the in progress execution should not be cancelled when a new one in the same group starts.

### Continuous Integration and Testing
The workflow will issue a terraform plan before the apply to minimize the probability of errors affecting the infrastructure.

### Recording and Audit
Leveraging the workflow run history, we can keep a record of who, when and what S3 bucket has been created/updated. This can also be achieved with the commit history of the proper S3 bucket configuration in the repository.

## Technical implementation

### Directory Structure

```
.github/
└── workflows/
    └── provision-s3.yml
terraform/
├── modules/
│   └── s3/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├──common/
│   └── common.tf
└── live/
    ├── staging/
    │   ├── bucket-abc/
    │   │   └── terragrunt.hcl
    │   └── env.hcl
    └── production/
        ├── bucket-123/
        │   └── terragrunt.hcl
        └── env.hcl
```

### Workflow Steps

1. **Trigger & Input Collection**: The workflow is triggered via `workflow_dispatch`, presenting a form for required parameters: S3 bucket name, AWS Account, versioning, and encryption.

2. **Concurrency Control**: The workflow uses the `concurrency` key with `<bucket-name>@<aws-account>` to prevent simultaneous executions of the same resource.

3. **Define environment**: In the job definition, set up the proper environment name based on the AWS account name.

4. **Checkout**: checkout repository

4. **User Validation**: The workflow checks if the user is authorized to provision a bucket in the selected environment, based on GitHub teams or repository permissions.

5. **Input Validation**: Inputs are validated for naming conventions, uniqueness, and compliance with AWS requirements using a validation script or action.

6. **Generate terragrunt configuration**: A `terraform/live/<aws-account>/<bucket-name>` folder is generated including a `terragrunt.hcl` with the provided parameters and committed in the repository. The details of the file are explanined in the Terragrunt section. This step can take advantange of use a file template.

7. **Configure AWS Credentials**: AWS Credentials will be configured using the official Amazon action [`aws-actions/configure-aws-credentials`](https://github.com/aws-actions/configure-aws-credentials). The Role and the Region can be defined as `variable`s within the proper GitHub environment.

8. **Terraform & Terragrunt installation**: use the existing actions to install both tools.

8. **Terraform execution**: Inside the newly created folder, the workflow runs a `terragrunt plan` to check everything is correct. If not, it will fail and return the relevant information to the user. If plan went ok, the workflow runs `terragrunt apply` to provision the S3 bucket.

9. **Output**: The workflow outputs the bucket details and status in the workflow summary.

### Terragrunt
The terragrunt configuration will defined as in the below structure with the following details:
- **common.tf**: will include all common configuration, for example the backend definition, that will parametrize the name of the state file with `<aws-account>-<bucket-name>.tfstate`. This file will include the necesary configuration from the `env.hcl` file.
- **env.hcl**: a file per each environment (AWS Account), that contains specific configuration of this environment (eg. account ID or region).
- **terragrunt.hcl**: for each S3 bucket, a terragrunt.hcl file will exist un the proper folder hierarchy. It is generated automatically in each workflow execution keeping the following structure:
  - `terraform` block to point to the `s3` terraform module
  - `include` block for the common file.
  - `inputs` block including the inputs values passed by the user in the workflow run.

### GitHub repository
The repository needs the following minimum configuration:
- Assigned user groups with the permissions to execute the workflow on demand. One group per AWS Account for more granular security.
- Assigned a user group with elevated permissions to be able to maintain the repository
- Assign a Service Account with permissions to write in the repository main branch. This user is going to be used to commit the `terragrunt.hcl` file. For this, we need to generate the proper token and save it as a secret in the repository.
- The repository will prevent any user to write in the main branch, except the Service Account user.