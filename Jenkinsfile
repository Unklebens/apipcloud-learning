pipeline {
    agent { label 'dockerhost' }
    // parameters {
    //     string(name: 'PATH', defaultValue: '', description: 'Chemin de l archive avec extension a uploader')
    // }
    stages {
        stage('Build image') {
            steps {
                sh 'docker build -t pclouduploader:v2 .'
            }
        }
        stage('Push to pcloud') {
            environment {
                PCLOUDCREDS = credentials('PCLOUDcreds')
            }
            steps {
                sh '''docker run --rm \
                    -e PCLOUDUSER=${PCLOUDCREDS_USR} \
                    -e PCLOUDPASS=${PCLOUDCREDS_PSW} \
                    -v /ssd/docker_backups/pve001:/backups:ro \
                    pclouduploader:v2 \
                    /backups'''
            }
        }
        stage('Cleanup') {
            steps {
                sh 'docker image prune -f'
            }
        }
    }
}
