Git = require 'promised-git'
DefaultRepo = null

getPath = ->
  if atom.project?.getRepositories()[0]
    atom.project.getRepositories()[0].getWorkingDirectory()
  else if atom.project
    atom.project.getPath()
  else
    __dirname

module.exports =
  defaultRepo: ->
    if not DefaultRepo?
      DefaultRepo = new Git(getPath())
    DefaultRepo

  defaultAtomRepo: -> atom.project.getRepositories()[0]
