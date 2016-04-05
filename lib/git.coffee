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

class AtomatiGitRepo
  constructor: (@promisedRepo, @atomRepo) ->

  onDidChangeStatus: (callback) ->
    @atomRepo.onDidChangeStatus callback

  getWorkingDirectory: ->
    @atomRepo.getWorkingDirectory()

  getReferences: ->
    @atomRepo.getReferences()

  refreshStatus: ->
    @atomRepo.refreshStatus()

  add: (file) ->
    @promisedRepo.add file

  branches: ->
    @promisedRepo.branches()

  checkout: (args...) ->
    @promisedRepo.checkout args...

  checkoutFile: (file) ->
    @promisedRepo.checkoutFile file

  cmd: (args...) ->
    @promisedRepo.cmd args...

  commit: (args...) ->
    @promisedRepo.commit args...

  getCommit: (args...) ->
    @promisedRepo.getCommit args...

  getDiff: (args...) ->
    @promisedRepo.getDiff args...

  remoteBranches: ->
    @promisedRepo.remoteBranches()

  revParse: (args...) ->
    @promisedRepo.revParse args...

  status: ->
    @promisedRepo.status()

  unstage: (file) ->
    @promisedRepo.unstage file


module.exports =
  defaultRepo: -> new Git(getPath())

  defaultAtomRepo: ->
    dirs = atom.project.getDirectories()
    atom.project.repositoryForDirectory dirs[0]

  curRepo: ->
    p = getCurAtomRepo()
    if !p?
      null
    else
      p.then (r) ->
        if r?
          promisedRepo = new Git(r.getWorkingDirectory())
          new AtomatiGitRepo(promisedRepo, r)
        else
          null
