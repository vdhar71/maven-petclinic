# Vidyadhar version of Spring PetClinic Sample Application [![Build Status](https://github.com/spring-projects/spring-petclinic/actions/workflows/maven-build.yml/badge.svg)](https://github.com/spring-projects/spring-petclinic/actions/workflows/maven-build.yml)

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/spring-projects/spring-petclinic) [![Open in GitHub Workspaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=7517918)




## Understanding the Spring Petclinic application with a few diagrams
<a href="https://speakerdeck.com/michaelisvy/spring-petclinic-sample-application">See the presentation here</a>

## Running petclinic locally
Petclinic is a [Spring Boot](https://spring.io/guides/gs/spring-boot) application built using [Maven](https://spring.io/guides/gs/maven/) or [Gradle](https://spring.io/guides/gs/gradle/). You can build a Docker image file and run it from the command line (it should work just as well with Java 17 or newer):

The process of creating the Docker image from the source files is completely automated. The source code is pushed to the GitHub, then  picked up by the Jenkins pipeline via webhook notification. Jenkins then builds the artifacts and at the end creates a Docker image of the spring-petclinic application. Here is the flow:
Source code from local repo -> GitHub -> Jenkins pipeline -> Docker image

-----------------------------------------------------------------------------------------------------------------------
NOTE: The entire project was created on 2021 MacBook Pro M1 Chip Pro, 32GB RAM and 1TB storage
-----------------------------------------------------------------------------------------------------------------------


Following are the steps outlined of the entire process:

1. Getting the spring-petclinic and pushing it to your own Git repo.

```
git clone https://github.com/spring-projects/spring-petclinic.git
git init
git remote add origin https://github.com/<git-repo>/petclinic.git #New remote repo
git branch -M main #setting main 
git push -u origin main
git remote -v

```
2. Install Jenkins:
``` brew install jenkins-lts```
Edit the file ```/opt/homebrew/Cellar/jenkins-lts/2.401.2/homebrew.mxcl.jenkins-lts.plist``` and replace the line reading
```--httpPort=8080``` to ```--httpPort=8090``` This is to avoid conflict as the application runs on port 8080.
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
9. Next update settings.xml with Maven Artifactory plugin. You can refer: ```https://jfrog.com/help/r/jfrog-integrations-documentation/maven-artifactory-plugin```
10. Install "trivy" from Aqua Security For vulnerability scanning. Trivy is OSS and a very popular scanner.
11. Create a jenkins pipeline:
```pipeline {
    agent any
    tools {
        jfrog 'jfrog-cli'
    }
 
    stages {
        stage('Build') {
            steps {
                // Trivy scan before git checkout
                sh '/opt/homebrew/bin/trivy repo https://github.com/<repo>/petclinic.git --scanners vuln,secret,config,license --dependency-tree'
                
                // Get some code from a GitHub repository
                checkout scmGit(branches: [
                    [name: '*/main']
                    ], 
                    extensions: [cleanBeforeCheckout(deleteUntrackedNestedRepositories: true)], 
                    userRemoteConfigs: [
                        [url: 'https://github.com/<repo>/petclinic']
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
                    sh '/usr/local/bin/docker build -t <docker-repo>/petclinic:1.0 .'
                    
                    // Trivy scan on the final artifact: Docker image
                    sh '/opt/homebrew/bin/trivy image <docker-repo>/petclinic:1.0 --scanners vuln,secret,config,license --dependency-tree'
                    
                    sh '/usr/local/bin/docker save -o petclinic.tar <docker-repo>/petclinic:1.0'
                    jf 'rt u petclinic.tar repo-local/'
                }
            }
        }
    }```
12. **Running the spring-petclinic application**. Database needs to be up and running before running the spring-petclinic. There is a choice to use either MySQL or Postgres. Here in this example we are using MySQL.
```
docker run -e MYSQL_USER=petclinic -e MYSQL_PASSWORD=petclinic -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=petclinic -p 3306:3306 mysql:8.0
```
Ensure that the DB is ready to accept connections before executing the following command.

```
docker run -d -p 8080:8080 vdhar/petclinic:1.0
```

You can then access petclinic at http://localhost:8080/



## Test Applications

At development time we recommend you use the test applications set up as `main()` methods in `PetClinicIntegrationTests` (using the default H2 database and also adding Spring Boot devtools), `MySqlTestApplication` and `PostgresIntegrationTests`. These are set up so that you can run the apps in your IDE and get fast feedback, and also run the same classes as integration tests against the respective database. The MySql integration tests use Testcontainers to start the database in a Docker container, and the Postgres tests use Docker Compose to do the same thing.

## Compiling the CSS

There is a `petclinic.css` in `src/main/resources/static/resources/css`. It was generated from the `petclinic.scss` source, combined with the [Bootstrap](https://getbootstrap.com/) library. If you make changes to the `scss`, or upgrade Bootstrap, you will need to re-compile the CSS resources using the Maven profile "css", i.e. `./mvnw package -P css`. There is no build profile for Gradle to compile the CSS.

## Working with Petclinic in your IDE

### Prerequisites
The following items should be installed in your system:
* Java 17 or newer (full JDK, not a JRE).
* [git command line tool](https://help.github.com/articles/set-up-git)
* Your preferred IDE 
  * Eclipse with the m2e plugin. Note: when m2e is available, there is an m2 icon in `Help -> About` dialog. If m2e is
  not there, follow the install process [here](https://www.eclipse.org/m2e/)
  * [Spring Tools Suite](https://spring.io/tools) (STS)
  * [IntelliJ IDEA](https://www.jetbrains.com/idea/)
  * [VS Code](https://code.visualstudio.com)

### Steps:

1) On the command line run:
    ```
    git clone https://github.com/spring-projects/spring-petclinic.git
    ```
2) Inside Eclipse or STS:
    ```
    File -> Import -> Maven -> Existing Maven project
    ```

    Then either build on the command line `./mvnw generate-resources` or use the Eclipse launcher (right click on project and `Run As -> Maven install`) to generate the css. Run the application main method by right-clicking on it and choosing `Run As -> Java Application`.

3) Inside IntelliJ IDEA
    In the main menu, choose `File -> Open` and select the Petclinic [pom.xml](pom.xml). Click on the `Open` button.

    CSS files are generated from the Maven build. You can build them on the command line `./mvnw generate-resources` or right-click on the `spring-petclinic` project then `Maven -> Generates sources and Update Folders`.

    A run configuration named `PetClinicApplication` should have been created for you if you're using a recent Ultimate version. Otherwise, run the application by right-clicking on the `PetClinicApplication` main class and choosing `Run 'PetClinicApplication'`.

4) Navigate to Petclinic

    Visit [http://localhost:8080](http://localhost:8080) in your browser.


## Looking for something in particular?

|Spring Boot Configuration | Class or Java property files  |
|--------------------------|---|
|The Main Class | [PetClinicApplication](https://github.com/spring-projects/spring-petclinic/blob/main/src/main/java/org/springframework/samples/petclinic/PetClinicApplication.java) |
|Properties Files | [application.properties](https://github.com/spring-projects/spring-petclinic/blob/main/src/main/resources) |
|Caching | [CacheConfiguration](https://github.com/spring-projects/spring-petclinic/blob/main/src/main/java/org/springframework/samples/petclinic/system/CacheConfiguration.java) |

## Interesting Spring Petclinic branches and forks

The Spring Petclinic "main" branch in the [spring-projects](https://github.com/spring-projects/spring-petclinic)
GitHub org is the "canonical" implementation based on Spring Boot and Thymeleaf. There are
[quite a few forks](https://spring-petclinic.github.io/docs/forks.html) in the GitHub org
[spring-petclinic](https://github.com/spring-petclinic). If you are interested in using a different technology stack to implement the Pet Clinic, please join the community there.


## Interaction with other open source projects

One of the best parts about working on the Spring Petclinic application is that we have the opportunity to work in direct contact with many Open Source projects. We found bugs/suggested improvements on various topics such as Spring, Spring Data, Bean Validation and even Eclipse! In many cases, they've been fixed/implemented in just a few days.
Here is a list of them:

| Name | Issue |
|------|-------|
| Spring JDBC: simplify usage of NamedParameterJdbcTemplate | [SPR-10256](https://jira.springsource.org/browse/SPR-10256) and [SPR-10257](https://jira.springsource.org/browse/SPR-10257) |
| Bean Validation / Hibernate Validator: simplify Maven dependencies and backward compatibility |[HV-790](https://hibernate.atlassian.net/browse/HV-790) and [HV-792](https://hibernate.atlassian.net/browse/HV-792) |
| Spring Data: provide more flexibility when working with JPQL queries | [DATAJPA-292](https://jira.springsource.org/browse/DATAJPA-292) |


# Contributing

The [issue tracker](https://github.com/spring-projects/spring-petclinic/issues) is the preferred channel for bug reports, features requests and submitting pull requests.

For pull requests, editor preferences are available in the [editor config](.editorconfig) for easy use in common text editors. Read more and download plugins at <https://editorconfig.org>. If you have not previously done so, please fill out and submit the [Contributor License Agreement](https://cla.pivotal.io/sign/spring).

# License

The Spring PetClinic sample application is released under version 2.0 of the [Apache License](https://www.apache.org/licenses/LICENSE-2.0).

[spring-petclinic]: https://github.com/spring-projects/spring-petclinic
[spring-framework-petclinic]: https://github.com/spring-petclinic/spring-framework-petclinic
[spring-petclinic-angularjs]: https://github.com/spring-petclinic/spring-petclinic-angularjs 
[javaconfig branch]: https://github.com/spring-petclinic/spring-framework-petclinic/tree/javaconfig
[spring-petclinic-angular]: https://github.com/spring-petclinic/spring-petclinic-angular
[spring-petclinic-microservices]: https://github.com/spring-petclinic/spring-petclinic-microservices
[spring-petclinic-reactjs]: https://github.com/spring-petclinic/spring-petclinic-reactjs
[spring-petclinic-graphql]: https://github.com/spring-petclinic/spring-petclinic-graphql
[spring-petclinic-kotlin]: https://github.com/spring-petclinic/spring-petclinic-kotlin
[spring-petclinic-rest]: https://github.com/spring-petclinic/spring-petclinic-rest
