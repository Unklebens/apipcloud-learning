pipeline {
    agent {
        dockerfile {
            filename 'Dockerfile'
            label 'dockerhost'
            args '-v /ssd/docker_backups/pve001:/backups:ro'
        }
        
    }
    parameters {
        string(name: 'ARCHIVE_NAME', defaultValue: '', description: 'Nom de l archive a uploader')
        }
    stages {
        }
        stage('Push to pcloud') {
            environment {
                PCLOUDCREDS = credentials('PCLOUDcreds')
            }
            steps {
                sh ''' PCLOUDUSER=${PCLOUDCREDS_USR} PCLOUDPASS=${PCLOUDCREDS_PSW} main.sh /backups/${ARCHIVE_NAME} '''
            }
        }
    }
