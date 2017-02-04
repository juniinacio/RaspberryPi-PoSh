class Settings {
    static String gitUrl = 'https://github.com/juniinacio/RaspberryPi-PoSh.git'
    static String gitRepo = 'juniinacio/RaspberryPi-PoSh.git'
    static String moduleName = 'RaspberryPi-PoSh'
}

def posh(cmd) {
    sh 'sudo powershell -NonInteractive -NoProfile -Command "& ' + cmd + '"'
}

try {
    node('master') {
        currentBuild.displayName = "${Settings.moduleName} v1.0.0.${BUILD_NUMBER}"

        checkout changelog: true, poll: true, scm: [$class: 'GitSCM', branches: [[name: '*/dev']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'PreBuildMerge', options: [fastForwardMode: 'FF', mergeRemote: "${Settings.moduleName}", mergeTarget: 'master']]], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'GitHub', name: "${Settings.moduleName}", url: "https://github.com/${Settings.gitRepo}"]]]

        def pipeline = load("pipeline.groovy")

        stage ('Prepare =>') {
            parallel (
                'Stream 1' : {
                    node('centos7') {
                        stage ('CentOS 7') {
                            checkout changelog: true, poll: true, scm: [$class: 'GitSCM', branches: [[name: '*/dev']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'PreBuildMerge', options: [fastForwardMode: 'FF', mergeRemote: "${Settings.moduleName}", mergeTarget: 'master']]], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'GitHub', name: "${Settings.moduleName}", url: "https://github.com/${Settings.gitRepo}"]]]
                        }
                    }
                },
                'Stream 2' : {
                    node('ubuntu16') {
                        stage ('Ubuntu 16.04') {
                            checkout changelog: true, poll: true, scm: [$class: 'GitSCM', branches: [[name: '*/dev']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'PreBuildMerge', options: [fastForwardMode: 'FF', mergeRemote: "${Settings.moduleName}", mergeTarget: 'master']]], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'GitHub', name: "${Settings.moduleName}", url: "https://github.com/${Settings.gitRepo}"]]]
                        }
                    }
                },
                // 'Stream 3' : {
                //     node('ubuntu14') {
                //         stage ('Ubuntu 14.01') {
                //           checkout changelog: true, poll: true, scm: [$class: 'GitSCM', branches: [[name: '*/dev']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'PreBuildMerge', options: [fastForwardMode: 'FF', mergeRemote: "${Settings.moduleName}", mergeTarget: 'master']]], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'GitHub', name: "${Settings.moduleName}", url: "https://github.com/${Settings.gitRepo}"]]]
                //         }
                //     }
                // }
            )
        }

        stage ('Clean =>') {
            parallel (
                'Stream 1' : {
                    node('centos7') {
                        stage ('CentOS 7') {
                            posh 'Invoke-Build Clean'
                        }
                    }
                },
                'Stream 2' : {
                    node('ubuntu16') {
                        stage ('Ubuntu 16.04') {
                            posh 'Invoke-Build Clean'
                        }
                    }
                },
                // 'Stream 3' : {
                //     node('ubuntu14') {
                //         stage ('Ubuntu 14.01') {
                //             posh 'Invoke-Build Clean'
                //         }
                //     }
                // }
            )
        }

        stage ('Install =>') {
            parallel (
                'Stream 1' : {
                    node('centos7') {
                        stage ('CentOS 7') {
                            posh 'Invoke-Build Install'
                        }
                    }
                },
                'Stream 2' : {
                    node('ubuntu16') {
                        stage ('Ubuntu 16.04') {
                            posh 'Invoke-Build Install'
                        }
                    }
                },
                // 'Stream 3' : {
                //     node('ubuntu14') {
                //         stage ('Ubuntu 14.01') {
                //             posh 'Invoke-Build Install'
                //         }
                //     }
                // }
            )
        }

        stage ('Analyze =>') {
            parallel (
                'Stream 1' : {
                    node('centos7') {
                        stage ('CentOS 7') {
                            posh 'Invoke-Build Analyze'
                        }
                    }
                },
                'Stream 2' : {
                    node('ubuntu16') {
                        stage ('Ubuntu 16.04') {
                            posh 'Invoke-Build Analyze'
                        }
                    }
                },
                'Stream 3' : {
                    // node('ubuntu14') {
                    //     stage ('Ubuntu 14.01') {
                    //         posh 'Invoke-Build Analyze'
                    //     }
                    // }
                }
            )
        }

        stage ('Test =>') {
            parallel (
                'Stream 1' : {
                    node('centos7') {
                        stage ('CentOS 7') {
                            posh 'Invoke-Build Test'
                        }
                    }
                },
                'Stream 2' : {
                    node('ubuntu16') {
                        stage ('Ubuntu 16.04') {
                            posh 'Invoke-Build Test'
                        }
                    }
                },
                // 'Stream 3' : {
                //     node('ubuntu14') {
                //         stage ('Ubuntu 14.01') {
                //             posh 'Invoke-Build Test'
                //         }
                //     }
                // }
            )
        }

        // stage ('Archive =>') {
        //     parallel (
        //         'Stream 1' : {
        //             node('centos7') {
        //                 stage ('CentOS 7') {
        //                     posh 'Invoke-Build Archive'
        //                 }
        //             }
        //         },
        //         'Stream 2' : {
        //             node('ubuntu16') {
        //                 stage ('Ubuntu 16.04') {
        //                     posh 'Invoke-Build Archive'
        //                 }
        //             }
        //         },
        //         'Stream 3' : {
        //             node('ubuntu14') {
        //                 stage ('Ubuntu 14.01') {
        //                     posh 'Invoke-Build Archive'
        //                 }
        //             }
        //         }
        //     )
        // }

        stage ('Publish  =>') {
            // parallel (
            //     'Stream 1' : {
            //         node('centos7') {
            //             stage ('CentOS 7') {
            //                 posh 'Invoke-Build Publish'
            //             }
            //         }
            //     },
            //     'Stream 2' : {
            //         node('ubuntu16') {
            //             stage ('Ubuntu 16.04') {
            //                 posh 'Invoke-Build Publish'
            //             }
            //         }
            //     },
            //     'Stream 3' : {
            //         node('ubuntu14') {
            //             stage ('Ubuntu 14.01') {
            //                 posh 'Invoke-Build Publish'
            //             }
            //         }
            //     }
            // )

            // https://github.com/jenkinsci/git-plugin/blob/master/src/main/java/hudson/plugins/git/GitPublisher.java
            withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'GitHub', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD']]) {
                sh("git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${Settings.gitRepo} HEAD:master")
                sh("git tag -a v1.0.0.${BUILD_NUMBER} -f -m '${Settings.moduleName} v1.0.0.${BUILD_NUMBER}'")
                sh("git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${Settings.gitRepo} v1.0.0.${BUILD_NUMBER}")
            }
        }
    }
} catch (e) {
    currentBuild.result = "FAILED"
    throw e
} finally {
}