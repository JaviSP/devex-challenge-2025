def call(Map config [:]) {

  sh """
    #!/bin/bash

    // Run Unit tests of the specified group, reporting JUnit results and coverage in XML format
    pytest --junitxml=${TEST_GROUP}-unit-test-results.xml --cov=. --cov-report=xml:${TEST_GROUP}-coverage.xml tests/${TEST_GROUP}
  """

}