var buildTools = require('@devonian/build-tools')

var ctx = {}

var buildInstaller = () => buildTools.buildInstaller({
  cron: {
    removeAllEntries: true,
    removeEntriesWithComment: '',
    addEntries: [
      {
        effeciveUserName: '',
        frequency: { preset: 'EVERY_FOUR_HOURS' }, // cronText: ''
        command: '',
        comment: ''
      }
    ]
  },
  podman: {
    initialization: {
      removeAllNetworks: true,
      removeAllNonVolumeContainers: true,
      removeVolumeContainers: false,
      removeContainersByName: [],
      requireContainersByName: []
    },
    createContainers: [
      volumes: [],
      services: [{
        containerName: '',
        imageFile: '',
        exposeOnPort: 18000
      }]
    ],
    runContainers: {
      effectiveUserName: ''
      commandPath: '/opt/prg/run-containers.sh'
    }
  }
})

buildTools.createTempDir()
.then(d => ctx.tmpDir = d)
.then(() => monitorBuilder.build(ctx))
.then(r => ctx.monitorInfo = r)
.then(() => gatewayBuilder.build(ctx))
.then(r => ctx.gatewayInfo = r)
// the same for mariadb and fileserver
.then(() => buildInstaller())
.finally(r => buildTools.removeDir(ctx.tmpDir))
