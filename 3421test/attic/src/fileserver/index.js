var buildTasks = require('@devonian/build-tasks')

buildTasks.createFileserverImage({
  standalone: true,
  filesDir: 'files'
})
.then(console.log)
.catch(console.error)
