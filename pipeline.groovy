def lastSuccessfulBuild(passedBuilds, build) {
  if ((build != null) && (build.result != 'SUCCESS')) {
      passedBuilds.add(build)
      lastSuccessfulBuild(passedBuilds, build.getPreviousBuild())
   }
}

def updateChangelog() {
    def changeLog = sh(returnStdout: true, script: 'tail -n +2 CHANGELOG.md | awk "{print $1}"').trim()
    def passedBuilds = []
    def date = new Date().format( 'yyyy-MM-dd' )

    lastSuccessfulBuild(passedBuilds, currentBuild);

    def changeLogEntries = getChangeLogEntries(passedBuilds)
    if (changeLogEntries) {
        sh("echo '## Changelog' > CHANGELOG.md")
        sh("echo '' >> CHANGELOG.md")
        sh("echo '## ${Settings.moduleName} v1.0.0.${BUILD_NUMBER} ${date}' >> CHANGELOG.md")
        sh("echo '${changeLogEntries}' >> CHANGELOG.md")
        sh("echo '${changeLog}' >> CHANGELOG.md")
        sh("git commit -am 'Update changelog'")
    }
}

def updateModule () {
    sh("sed -r -i 's/1.0.0.[0-9]+/1.0.0.${BUILD_NUMBER}/g' RaspberryPi-PoSh/RaspberryPi-PoSh.psd1")
    sh("git commit -am 'Update version'")
}

@NonCPS
def getChangeLogEntries(passedBuilds) {
    def log = ""
    for (int x = 0; x < passedBuilds.size(); x++) {
        def currentBuild = passedBuilds[x];
        def changeLogSets = currentBuild.rawBuild.changeSets
        for (int i = 0; i < changeLogSets.size(); i++) {
            def entries = changeLogSets[i].items
            for (int j = 0; j < entries.length; j++) {
                def entry = entries[j]
                log += " - ${entry.msg} \n"
            }
        }
    }
    return log;
}

return this;