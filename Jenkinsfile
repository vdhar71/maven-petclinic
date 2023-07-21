pipeline {
  agent any

  stages {
    stage('Build') {
      steps {
        // Get some code from a GitHub repository
        checkout scmGit(branches: [
            [name: '*/main']
          ],
          extensions: [cleanBeforeCheckout(deleteUntrackedNestedRepositories: true)],
          userRemoteConfigs: [
            [url: 'https://github.com/vdhar71/petclinic']
          ])

        // Run Maven on a Unix agent.
        sh "./mvnw package"

        // bat "mvn -Dmaven.test.failure.ignore=true clean package"
      }

      post {
        // If Maven was able to run the tests, even if some of the test
        // failed, record the test results and archive the jar file.
        success {
          archiveArtifacts 'target/*.jar'
        }
      }
    }
  }
}
