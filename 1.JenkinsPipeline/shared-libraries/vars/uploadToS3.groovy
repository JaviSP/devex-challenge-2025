def call(Map config = [:]) {
  def bucketName = config.bucketName
  def serviceName = config.serviceName
  def files = config.files

  withCredentials([
    vaultString(credentialsId: "${serviceName}-AKI", variable: 'AWS_ACCESS_KEY_ID'),
    vaultString(credentialsId: "${serviceName}-SAK", variable: 'AWS_SECRET_ACCESS_KEY'),
    vaultString(credentialsId: "${serviceName}-REGION", variable: 'AWS_REGION'),
  ]) {
    sh """
      #!/bin/bash

      // Copy the specified files to a temporary directory
      cp ${files.join(" ")} ${WORKSPACE}/tmp-folder/

      # Upload the specified file to the S3 bucket
      aws s3 cp ${WORKSPACE}/tmp-folder/ s3://${bucketName}/${serviceName}/${BUILD_TAG}/ --recursive

      // Delete the temporary directory
      rm -rf ${WORKSPACE}/tmp-folder/
    """
  }
}