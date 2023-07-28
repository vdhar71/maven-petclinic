pipeline {
    agent any
    tools {
        jfrog 'jfrog-cli'
    }
 
    environment {
        dockerCredentials = 'dockerhub'
        PATH='/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin'
    }

    stages {
        stage('Build') {
            steps {
		// Login to Docker to enable trivy to download the DB.
		sh 'echo $PATH'
                sh 'env'
                // Docker login to use trivy
                withCredentials([usernamePassword(credentialsId: dockerCredentials, passwordVariable: 'password', usernameVariable: 'username')]) {
                        sh '/usr/local/bin/docker login -u $username -p $password'
                }
                // Trivy scan before git checkout
                sh '/opt/homebrew/bin/trivy repo https://github.com/vdhar71/petclinic.git --scanners vuln,secret,config,license --dependency-tree'
                
                // Checkout spring-petclinic code from the GitHub repository
                checkout scmGit(branches: [
                    [name: '*/main']
                    ], 
                    extensions: [cleanBeforeCheckout(deleteUntrackedNestedRepositories: true)], 
                    userRemoteConfigs: [
                        [url: 'https://github.com/vdhar71/petclinic']
                        ])
                        
                // Exec JF & Maven commands and build the app
                jf '-v'
                jf 'c show'
                jf 'mvn-config --repo-resolve-releases libs-release --repo-resolve-snapshots libs-snapshots --repo-deploy-releases libs-release-local --repo-deploy-snapshots libs-snapshot-local'
                // Check whether dependencies can be resolved
                sh './mvnw dependency:resolve'
                // Build petclinic app
                sh './mvnw package'
                
                // Trivy scan after app is built
                sh '/opt/homebrew/bin/trivy fs . --scanners vuln,secret,config,license --dependency-tree'
                
            }

            post {
                // If Maven was able to run the tests, even if some of the test
                // failed, record the test results and archive the jar file.
                success {
                    archiveArtifacts 'target/*.jar'
                    // Publish the build info.
                    jf 'rt bp'

                    // Build the Docker image from the resulting jar
                    sh '/usr/local/bin/docker build -t repo-local/petclinic:1.1 .'
                    
                    // Trivy scan on the final artifact: Docker image
                    //sh '/opt/homebrew/bin/trivy image repo-local/petclinic:1.1 --scanners vuln,secret,config,license --dependency-tree'
                    
                    // Push the image to JFrog Artifactory repo
                    sh 'docker push repo-local/petclinic:1.1'
                    
                    //sh '/usr/local/bin/docker save -o petclinic.tar vdhar/petclinic:1'
                    //jf 'rt u petclinic.tar repo-local/'
                }
            }
        }
    }
}
