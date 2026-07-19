pipeline {
    agent { label 'dockerhost' }
    parameters {
        string(name: 'LOCAL_PATH', defaultValue: '', description: 'Chemin du dossier local a synchroniser')
        string(name: 'FOLDERID', defaultValue: '', description: 'ID du dossier a remote')
        string(name: 'RETENTION_DAYS', defaultValue: '', description: 'Nombre de jours de conservation')
        choice choices: ['PCLOUDcreds', 'PCLOUDcreds_fkds'], description: 'account on which the upload will happen', name: 'PCLOUD_ACCOUNT'
    }
    stages {
        stage('Build image') {
            steps {
                sh 'docker build -t pclouduploader:"${BUILD_NUMBER}" .'
            }
        }
        stage('Push to pcloud') {
            environment {
                PCLOUDCREDS = credentials("${params.PCLOUD_ACCOUNT}")
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
                    pclouduploader:"${BUILD_NUMBER}" \
                    /backups'''
            }
        }
        stage('Cleanup') {
            steps {
                sh '''
                docker image ls --format "{{.Repository}}:{{.Tag}}" | grep "^pclouduploader:" | xargs -r docker image rm
                '''
            }
        }
    }
}
