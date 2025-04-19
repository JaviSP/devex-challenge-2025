def call(Map config = [:]) {
  def requirementsFile = config.requirementsFile ?: 'requirements.txt'

  sh """
    #!/bin/bash

    // Install dependencies
    pip install -r ${requirementsFile}

    // Install pytest and coverage plugin
    pip install pytest pytest-cov
  """

}