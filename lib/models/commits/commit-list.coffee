_ = require 'lodash'
List   = require '../list'
Commit = require './commit'
ErrorView = require '../../views/error-view'

class CommitList extends List
  model: Commit

  initialize: (models, options) ->
    super
    @atomatiGitRepo = options.atomatiGitRepo

  # Public: Reload the commit list.
  #
  # branch - The branch to reload the commits for as {Branch}.
  reload: (@branch, options={}) =>
    [@branch, options] = [null, @branch] if _.isPlainObject(@branch)
    @atomatiGitRepo.log(@branch?.head() ? 'HEAD')
    .then (commits) =>
      @reset _.map(commits, (commit) -> new Commit(commit, @atomatiGitRepo))
      @trigger('repaint') unless options.silent
      @select @selectedIndex
    .catch (error) -> new ErrorView(error)

module.exports = CommitList
