def call(body) {
  def config = [:]
  body.resolveStrategy = Closure.DELEGATE_FIRST
  body.delegate = config
  body()

  def serviceName = config.serviceName ?: "${env.JOB_NAME}".split('/')[0]
  def pythonVersion = config.pythonVersion ?: '3.12'
  def requirementsFile = config.requirementsFile ?: 'requirements.txt'
  def venvDir = config.venvDir ?: 'venv'
  def unitTestGroups = config.unitTestGroups ?: ['unit']
  def s3Bucket = config.s3Bucket ?: 'Ebury-ci-executions'

  pipeline {
    agent {
      label 'ubuntu'
    }

    environment {
      SERVICE_NAME = "${serviceName}"
    }

    options {
      timestamps()
    }

    stages {

      stage('Unit Tests'){
        matrix {
          axes {
            axis {
              name 'TEST_GROUP'
              values unitTestGroups
            }
          }

          agent { 
            label 'ubuntu'
          }

          stages {
            stage('Unit Tests') {
              steps {
                script {
                  pythonSetup(pythonVersion: "${pythonVersion}")
                  pythonInstallRequirements()
                  pythonUnitTests()
                }
              }
            }
            post {
              always {
                script {
                  uploadToS3(
                    bucketName: "${s3Bucket}",
                    serviceName: "${serviceName}",
                    files: '**/*-unit-test-results.xml', '**/*-coverage.xml'
                  )
                }
              }
            }
          }
        }
      }

      stage('Staging') {
        stage('Deploy Staging') {
          steps {
            script {
              sharedUtils.deployToStaging(serviceName: "${env.SERVICE_NAME}")
            }
          }
        }
        stage('Integration Tests') {
          steps {
            script {
              pythonSetup(pythonVersion: "${pythonVersion}")
              pythonInstallRequirements()
              pythonIntegrationTests(envFile: '.env.staging')
            }
          }
        }

        stage('E2E Tests') {
          agent { 
            label 'ubuntu && seleniumGrid'
          }
          steps {
            script {
              pythonE2ETests(envFile: '.env.e2e')
            }
          }
        }
      }
    }

    post {
      success {
        echo 'Pipeline succeeded'
      }
      failure {
        echo 'Pipeline failed'
      }
      always {
        cleanWs()
      }
    }
  }
  }