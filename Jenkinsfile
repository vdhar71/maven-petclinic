pipeline {
    agent any
    tools {
        jfrog 'jfrog-cli'
    }
 
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
                        
                // Exec Maven commands
                jf '-v'
                jf 'c show'
                jf 'mvn-config --repo-resolve-releases libs-release --repo-resolve-snapshots libs-snapshots --repo-deploy-releases libs-release-local --repo-deploy-snapshots libs-snapshot-local'
                // Run Maven on a Unix agent. Resolve dependencies from JFrog Artifactory
                // defined in settings.xml 
                sh "./mvnw -s settings.xml package"
                
                // Publiish the build info.
                jf 'rt bp'

                
            }

            post {
                // If Maven was able to run the tests, even if some of the test
                // failed, record the test results and archive the jar file.
                success {
                    archiveArtifacts 'target/*.jar'
                    // Build the Docker image from the resulting jar
                    sh 'docker build -t vdhar/petclinic:1.0 .'
                    
                    sh 'docker save -o petclinic.tar vdhar/petclinic:1.0'
                    jf 'rt u petclinic.tar repo-local/'
                }
            }
        }
    }
}
