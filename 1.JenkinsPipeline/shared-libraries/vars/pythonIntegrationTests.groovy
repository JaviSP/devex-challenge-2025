def call(Map config [:]) {

  def envFile = config.envFile ?: '.env'

  withCredentials([
    vaultString(credentialsId: "${serviceName}-AKI", variable: 'AWS_ACCESS_KEY_ID'),
    vaultString(credentialsId: "${serviceName}-SAK", variable: 'AWS_SECRET_ACCESS_KEY'),
    vaultString(credentialsId: "${serviceName}-REGION", variable: 'AWS_REGION'),
  ]) {
    sh """
      #!/bin/bash

      // Run Integration tests in Staging environment
      ...
    """
  }

}