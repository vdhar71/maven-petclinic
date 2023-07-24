# Vidyadhar version of Spring PetClinic Sample Application [Maven] [![Build Status](https://github.com/spring-projects/spring-petclinic/actions/workflows/maven-build.yml/badge.svg)](https://github.com/spring-projects/spring-petclinic/actions/workflows/maven-build.yml)

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/spring-projects/spring-petclinic) [![Open in GitHub Workspaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=7517918)




## Understanding the Spring Petclinic application with a few diagrams
<a href="https://speakerdeck.com/michaelisvy/spring-petclinic-sample-application">See the presentation here</a>

## Running petclinic locally
Petclinic is a [Spring Boot](https://spring.io/guides/gs/spring-boot) application built using [Maven](https://spring.io/guides/gs/maven/) or [Gradle](https://spring.io/guides/gs/gradle/). You can build a Docker image file and run it from the command line (it should work just as well with Java 17 or newer):

The process of creating the Docker image from the source files is completely automated. The source code is pushed to the GitHub, then  picked up by the Jenkins pipeline via webhook notification. Jenkins then builds the artifacts and at the end creates a Docker image of the spring-petclinic application. Here is the flow:
Source code from local repo -> GitHub -> Jenkins pipeline -> Docker image

-----------------------------------------------------------------------------------------------------------------------
NOTE: The entire project was created on 2021 MacBook Pro M1 Chip Pro, 32GB RAM and 1TB storage 
running macOS Ventura 13.5
-----------------------------------------------------------------------------------------------------------------------


Following are the steps outlined of the entire process:

1. Getting the spring-petclinic and pushing it to your own Git repo.

```
git clone https://github.com/spring-projects/spring-petclinic.git
git init
git remote add origin https://github.com/<git-repo>/petclinic.git
git branch -M main #setting main 
git push -u origin main
git remote -v

```
2. Install Jenkins:
``` brew install jenkins-lts```
Edit the file ```/opt/homebrew/Cellar/jenkins-lts/2.401.2/homebrew.mxcl.jenkins-lts.plist``` and replace the line reading
```--httpPort=8080``` to ```--httpPort=8090``` This is to avoid conflict as the application also runs on port 8080.
3. Start jenkins using ```brew services start jenkins-lts```. Now you will be able to access jenkins from the browser using ```https://localhost:8090```.
4. Install the following plugins from the Manage Jenkins -> Plugins:
JFrog
Docker
Maven
Git
5. In order to initiate automated builds upon source code push to the main, jenkins needs to be available over internet. So install ngrok and run ```ngrok http 8090```. This is enable jenkins to be accessible over the internet.
6. On Git, configure webhook for the project under settings. Specify ```<ngrok-name/github-webhook/>``` and relevant permissions, example: push
7. Create JFrog cloud account (free trial) and a Maven project. This will automatically create default local, remote and virtual repositories. This will be used to resolve Maven dependencies.
8. Select Maven repo and ```Generate Token & create instructions``` using "Set Me Up". Follow the instructions and create "settings.xml". Copy the XML code from "Deploy" section and update the pom.xml
9. Next update pom.xml with Maven Artifactory plugin. You can refer: ```https://jfrog.com/help/r/jfrog-integrations-documentation/maven-artifactory-plugin```
10. Install "trivy" from Aqua Security For vulnerability scanning. Trivy is OSS and a very popular scanner.
11. Create a jenkins pipeline:
```
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
                // Check whether dependencies are pulled from JFrog Artifactory
                sh './mvnw -s settings.xml dependency:list'
                // Build petclinic app
                sh './mvnw -s settings.xml package'
                
                // Trivy scan after app is built
                sh '/opt/homebrew/bin/trivy fs . --scanners vuln,secret,config,license --dependency-tree'
                
                // Publish the build info.
                jf 'rt bp'

                
            }

            post {
                // If Maven was able to run the tests, even if some of the test
                // failed, record the test results and archive the jar file.
                success {
                    archiveArtifacts 'target/*.jar'
                    // Build the Docker image from the resulting jar
                    sh '/usr/local/bin/docker build -t vdhar/petclinic:1.0 .'
                    
                    // Trivy scan on the final artifact: Docker image
                    sh '/opt/homebrew/bin/trivy image vdhar/petclinic:1.0 --scanners vuln,secret,config,license --dependency-tree'
                    
                    sh '/usr/local/bin/docker save -o petclinic.tar vdhar/petclinic:1.0'
                    jf 'rt u petclinic.tar repo-local/'
                }
            }
        }
    }
}
```
12. Running the spring-petclinic application. Database needs to be up and running before running the spring-petclinic. There is a choice to use either MySQL or Postgres. Here in this example we are using MySQL.

```
docker run -e MYSQL_USER=petclinic -e MYSQL_PASSWORD=petclinic -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=petclinic -p 3306:3306 mysql:8.0
```

Ensure that the DB is ready to accept connections before executing the following command.

```
docker run -d -p 8080:8080 vdhar/petclinic:1.0
```

Visit [http://localhost:8080](http://localhost:8080) in your browser.
