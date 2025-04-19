# 1. Jenkins Pipeline

This pipeline provides a standardized way to build, test and deploy Python services at Ebury. It leverages shared libraries to promote code reuse and maintainability across different Python projects.

## Features

- Python environment setup and dependency management
- Parallel unit test execution with configurable test groups
- Test results and coverage reporting to S3
- Staging deployment and integration testing
- End-to-end testing with Selenium Grid
- Credential management via HashiCorp Vault

## Usage

To use this pipeline in your Python project:

1. Add a `Jenkinsfile` to your repository root:

   ```groovy
   @Library('eburySharedLibrary@v1') _

   pythonServicePipeline {
       serviceName = 'your-service-name'
       pythonVersion = '3.12'  // Optional, defaults to 3.12
       unitTestGroups = ['unit1', 'unit2']  // Optional, defaults to ['unit']
       requirementsFile = 'requirements.txt'  // Optional, defaults to 'requirements.txt'
       venvDir = 'venv'  // Optional, defaults to 'venv'
       s3Bucket = 'Ebury-ci-executions'  // Optional, defaults to 'Ebury-ci-executions'
   }
   ```

2. Ensure your project has:
   - `requirements.txt` file listing dependencies
   - Tests organized in directories matching `unitTestGroups` under `tests/`
   - `.env.staging` and `.env.e2e` files for environment-specific configs

# GitHub Actions migration
The way I defined the pipeline facilitates a easy migration to GitHub Action. 

The `pythonServicePipeline.groovy` that defined the pipeline could be impemented as a Shared Workflow, that will be called for each repository from a simple workflow (like the Jenkinsfile does). Then, very Stage in the Shared Libraries can be matched to a job in GitHub Actions, even the matrix for the Unit Testing is easily comparable.

For every step in Shared Library I choose a Shell script implementation because this allow to fast copy to `run` actions in a first iteration of the migration.

# Adapting the pipeline to other services
I would like to present a more robust solution in order to be able to adapt to various services, for example in different languages or projects with particularities.

A solution I developed in the past consisted in abstracting the pipeline with Groovy code leveraging the Object Oriented capabilities of the language. This way, I defined the pipeline with several steps like build, tests, deploy... each of them as an abstract class and then implement those classes with the characteristics of each language (like build using Maven for Java projects). Every class define a pre-action and post-action function to be executed right before or after the action in case any project needs some customization, for example download a configuration, generate a custom report...

Everything is condensed in a very simple Jenkinsfile that the developers can manage easily defining just then language of the project and some any other customizations.