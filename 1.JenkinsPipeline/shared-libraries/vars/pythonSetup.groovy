def call(Map config = [:]) {
  def pythonVersion = config.pythonVersion ?: '3.12'
  def venvDir = config.venvDir ?: 'venv'

  sh """
    #!/bin/bash
    
    // Install python
    sudo apt-get update
    sudo apt-get install -y python${pythonVersion} python${pythonVersion}-venv python${pythonVersion}-pip
    python${pythonVersion} -m venv ${venvDir}

    // Create a virtual environment
    python${pythonVersion} -m venv ${venvDir}
    
    // Activate the virtual environment
    source ${venvDir}/bin/activate
  """
}