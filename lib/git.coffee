Git = require 'promised-git'

getCurAtomRepo = ->
  ed = atom.workspace.getActiveTextEditor()
  if ed?
    path = ed.getPath()
    dirs = atom.project.getDirectories()
    dir = dirs.find (d) -> d.contains path
    if dir?
       atom.project.repositoryForDirectory(dir)

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
    atom.project.repositoryForDirectory dirs[0]

  curRepo: ->
    noRepo =
      atomRepo: null
      repo: null
    p = getCurAtomRepo()
    if !p?
      null
    else
      p.then (r) ->
        if r?
          atomRepo: r
          repo: new Git(r.getWorkingDirectory())
        else
          noRepo
