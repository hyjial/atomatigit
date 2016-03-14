Git = require 'promised-git'

getPath = ->
  if atom.project?.getRepositories()[0]
    atom.project.getRepositories()[0].getWorkingDirectory()
  else if atom.project
    atom.project.getPath()
  else
    __dirname

module.exports =
  defaultRepo: -> new Git(getPath())

  defaultAtomRepo: ->
    dirs = atom.project.getDirectories()
    console.log dirs
    atom.project.repositoryForDirectory dirs[0]
