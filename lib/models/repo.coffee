_       = require 'lodash'
fs      = require 'fs'
path    = require 'path'
{Model} = require 'backbone'
{CompositeDisposable} = require 'atom'

ErrorView                   = require '../views/error-view'
OutputView                  = require '../views/output-view'
git                         = require '../git'
{FileList}                  = require './files'
{CurrentBranch, BranchList} = require './branches'
{CommitList}                = require './commits'
Promise                     = git.defaultRepo().Promise

# Public: Offers access to core functionality regarding the git repository.
class Repo extends Model
  # Public: Constructor
  initialize: (repo, atomRepo)->
    @atomRepo = atomRepo
    @repo = repo

    @fileList      = new FileList [], {'repo': @repo}
    @branchList    = new BranchList [], {'repo': @repo}
    @commitList    = new CommitList [], {'repo': @repo, 'atomRepo': @atomRepo}
    @currentBranch = new CurrentBranch(@headRefsCount() > 0, {'repo': @repo})

    @subscriptions = new CompositeDisposable
    @listenTo @branchList, 'repaint', =>
      @commitList.reload()
      @currentBranch.reload()

    @subscriptions.add(atomRepo.onDidChangeStatus(@reload)) if atomRepo?

  destroy: =>
    @stopListening()
    @subscriptions.dispose()

  # Public: Forces a reload on the repository.
  reload: =>
    promises = [@fileList.reload()]
    if @headRefsCount() > 0
      promises.push @branchList.reload()
      promises.push @commitList.reload()
      promises.push @currentBranch.reload()
    Promise.all(promises)

  # Public: Returns the active selection.
  #
  # Returns the active selection as {Object}.
  selection: =>
    @activeList.selection()

  leaf: =>
    @activeList.leaf()

  getRepoName: ->
    @atomRepo.getWorkingDirectory()

  # Internal: The commit message file path.
  #
  # Returns the commit message file path as {String}.
  commitMessagePath: ->
    path.join(
      @atomRepo?.getWorkingDirectory(),
      '/.git/COMMIT_EDITMSG_ATOMATIGIT'
    )

  headRefsCount: ->
    @atomRepo?.getReferences()?.heads?.length ? 0

  fetch: ->
    @repo.cmd 'fetch'
    .catch (error) -> new ErrorView(error)
    .done =>
      @trigger('update')

  # checkoutBranch: =>
  #   @branchList.checkoutBranch

  stash: ->
    @repo.cmd 'stash'
    .catch (error) -> new ErrorView(error)
    .done =>
      @trigger('update')

  stashPop: ->
    @repo.cmd 'stash pop'
    .catch (error) -> new ErrorView(error)
    .done =>
      @trigger('update')

  # Internal: Initiate a new commit.
  initiateCommit: =>
    preCommitHook = atom.config.get('atomatigit.pre_commit_hook')
    if preCommitHook?.length > 0
      atom.commands.dispatch(atom.views.getView(atom.workspace), preCommitHook)

    fs.writeFileSync(@commitMessagePath(), @commitMessage())

    editorPromise = atom.workspace.open(@commitMessagePath(), {activatePane: true})
    editorPromise.then (editor) =>
      editor.setGrammar atom.grammars.grammarForScopeName('text.git-commit')
      editor.setCursorBufferPosition [0, 0]
      editor.onDidSave @completeCommit

  # Internal: Writes the commit message template to the message file.
  #
  # editor - The editor the file is open in as {Object}.
  commitMessage: =>
    message = '\n' + """
      # Please enter the commit message for your changes. Lines starting
      # with '#' will be ignored, and an empty message aborts the commit.
      # On branch #{@currentBranch.localName()}\n
    """

    filesStaged = @fileList.staged()
    filesUnstaged = @fileList.unstaged()
    filesUntracked = @fileList.untracked()

    message += '#\n# Changes to be committed:\n' if filesStaged.length >= 1
    _.each filesStaged, (file) -> message += file.commitMessage()

    message += '#\n# Changes not staged for commit:\n' if filesUnstaged.length >= 1
    _.each filesUnstaged, (file) -> message += file.commitMessage()

    message += '#\n# Untracked files:\n' if filesUntracked.length >= 1
    _.each filesUntracked, (file) -> message += file.commitMessage()

    return message

  # Internal: Destroys the active EditorView and deletes our temporary commit
  #           message file.
  cleanupCommitMessageFile: =>
    if atom.workspace.getActivePane().getItems().length > 1
      atom.workspace.destroyActivePaneItem()
    else
      atom.workspace.destroyActivePane()
    try fs.unlinkSync @commitMessagePath()
    @atomRepo?.refreshStatus?()

  # Internal: Commit the changes.
  completeCommit: =>
    @repo.commit @commitMessagePath()
    .then @reload
    .then =>
      @trigger('complete')
    .catch (error) -> new ErrorView(error)
    .finally @cleanupCommitMessageFile

  # Public: Initiate the creation of a new branch.
  initiateCreateBranch: =>
    @trigger 'needInput',
      message: 'Branch name'
      callback: (name) ->
        @repo.cmd "checkout -b #{name}"
        .catch (error) -> new ErrorView(error)
        .done =>
          @trigger('complete')

  # Public: Initiate a user defined git command.
  initiateGitCommand: =>
    @trigger 'needInput',
      message: 'Git command'
      callback: (command) =>
        git.defaultRepo().cmd command
        .then (output) -> new OutputView(output)
        .catch (error) -> new ErrorView(error)
        .done =>
          @trigger('complete')

  # Public: Push the repository to the remote.
  push: =>
    @currentBranch.push()

module.exports = Repo
