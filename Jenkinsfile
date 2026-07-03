pipeline {
    agent { label 'dockerhost' }
    parameters {
        string(name: 'LOCAL_PATH', defaultValue: '', description: 'Chemin du dossier local a synchroniser')
        string(name: 'FOLDERID', defaultValue: '', description: 'ID du dossier a remote')
        string(name: 'RETENTION_DAYS', defaultValue: '', description: 'Nombre de jours de conservation')
    }
    stages {
        stage('Build image') {
            steps {
                sh 'docker build -t pclouduploader:"${BUILD_TAG}" .'
            }
        }
        stage('Push to pcloud') {
            environment {
                PCLOUDCREDS = credentials('PCLOUDcreds')
                FOLDERID = "${params.FOLDERID}"
                RETENTION_DAYS = "${params.RETENTION_DAYS}"
                LOCAL_PATH = "${params.LOCAL_PATH}"
            }
            steps {
                sh '''docker run --rm \
                    -e PCLOUDUSER="${PCLOUDCREDS_USR}" \
                    -e PCLOUDPASS="${PCLOUDCREDS_PSW}" \
                    -e FOLDERID="${FOLDERID}" \
                    -e RETENTION_DAYS="${RETENTION_DAYS}" \
                    -v "${LOCAL_PATH}":/backups:ro \
                    pclouduploader:"${BUILD_TAG}" \
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
