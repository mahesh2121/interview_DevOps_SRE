Problem

 code checkout

 static code analysis: ESlint,SonarQube

 Unit testing

 Docker image build and push

 staging deployment

 Manual approval and production deployment

    Solution:

    1.Bloated Docker build context

    2.installing dependencies redundantly

    3.poor docker images management

    4.No parallel executation

    5.Manual deployment steps


Reduce the size of the docker build context:    

    Docker build context was unncessarily large due to unfiltered project directories we can use .dockerignore file to exclude certain files such as node_modules,logs etc.

keyfile:
    .dockerignore

    node_modules
    *.log
    dist
    coverage
    test-result

Dependency Caching

    Every stage was usingn npm install. i replaced with npm ci for repoducibility and activated caching in jenkins

    command

    npm ci --cache ~/.npm


improve docker image handing:


Preiusly the pipeline would rebuild and push docker images irrespective of changes.I added the logic to compare the hash of local and remote images doing a push only if the image changed.

updated logic:


    def remoteImageHash = sh(returnStdout: true, script: "docker inspect --format='{{.Id}}' $DOCKER_IMAGE:$DOCKER_TAG || echo ''").trim()
    def localImageHash = sh(returnStdout: true, script: "docker images --no-trunc -q $DOCKER_IMAGE:$DOCKER_TAG").trim()

    if (localImageHash != remoteImageHash) {
        sh 'docker push $DOCKER_IMAGE:$DOCKER_TAG'
    } else {
        echo "Image has not changed; skipping push."
    }


Run Static Analysis and Testing in Parallel

    I extended the Jenkins pipeline to make use of the parallel directive so that tasks like ESLint, SonarQube analysis, and unit tests could proceed simultaneously.

Updated Pipeline:

stage('Static Code Analysis') {
    parallel {
        stage('Frontend ESLint') {
            steps {
                sh 'npm run lint'
            }
        }
        stage('Backend SonarQube') {
            steps {
                withSonarQubeEnv() {
                    sh 'sonar-scanner'
                }
            }
        }
    }
}
Impact:
Reduced static analysis and testing time by 50%.


Automatic Backend Deployment
Manual updates to AWS ECS task definitions were time-consuming and error-prone. I automated this step using the AWS CLI.

Automated Script:

def taskDefinitionJson = """
{
    "family": "$ECS_TASK_DEFINITION_NAME",
    "containerDefinitions": [
        {
            "name": "backend",
            "image": "$DOCKER_IMAGE:$DOCKER_TAG",
            "memory": 512,
            "cpu": 256,
            "essential": true
        }
    ]
}
"""
sh "echo '${taskDefinitionJson}' > task-definition.json"
sh "aws ecs register-task-definition --cli-input-json file://task-definition.json --region $AWS_REGION"
sh "aws ecs update-service --cluster $ECS_CLUSTER_NAME --service $ECS_SERVICE_NAME --task-definition $ECS_TASK_DEFINITION_NAME --region $AWS_REGION"