pipeline {
    agent { label 'dockerhost' }
    parameters {
        string(name: 'ARCHIVE_NAME', defaultValue: '', description: 'Nom de l archive a uploader')
    }
    stages {
        stage('Build image') {
            steps {
                sh 'docker build -t pclouduploader:v0 .'
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
                    pclouduploader:v0 \
                    /backups/${ARCHIVE_NAME}'''
            }
        }
        stage('Cleanup') {
            steps {
                sh 'docker image prune -f'
            }
        }
    }
}