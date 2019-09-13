pipeline {
  environment {
      modName = "RisingTides"
  }

  options {
        timeout(time: 15, unit: 'MINUTES')
        disableConcurrentBuilds()
  }

  agent { node { label 'master' } }
  stages {
    stage('Code Checkout'){
      steps {
        checkout([$class: 'GitSCM',
          branches: [[name: '*/${BRANCH_NAME}']],
          doGenerateSubmoduleConfigurations: false,
          extensions: [], gitTool: 'Default',
          submoduleCfg: [],
          userRemoteConfigs: [[credentialsId: 'github-abatewongc-via-access-token',
          url: 'https://github.com/abatewongc/rising_tides/']]]
        )
        bat '''
          set
        '''
        
      }
    }

    stage('Build Mod Project') {
      steps {
        bat '''
          @echo "Building Mod Project!"
          @echo %WORKSPACE%
          @powershell set-executionpolicy remotesigned
          powershell "./scripts/build_jenkins.ps1" -mod %modName% -srcDirectory "'%WORKSPACE%'"
        '''
      }
    }

    stage('Upload Release') {
      when { branch 'master' }
      steps {
        withCredentials([usernamePassword(credentialsId: 'github-abatewongc-via-access-token', passwordVariable: 'personal_access_token', usernameVariable: 'username')]) {
          bat '''
            python3 scripts/tagmaker.py %personal_access_token% --repo rising_tides --current_commit_hash %COMMIT_HASH% --workspace_directory '%WORKSPACE%' --artifact_name %modName%.zip --should_increment 0
            '''
        }
      }
    }
  }
}
