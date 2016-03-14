_ = require 'lodash'

List         = require '../list'
LocalBranch  = require './local-branch'
RemoteBranch = require './remote-branch'
ErrorView    = require '../../views/error-view'

# Public: BranchList class that extends the {List} prototype.
class BranchList extends List
  initialize: (models, options) ->
    super
    @repo = options.repo

  # Public: Reload the branch list.
  reload: ({silent}={}) =>
    @repo.branches().then (branches) =>
      @reset()
      _.each branches, (branch) => @add new LocalBranch(branch, {'repo': @repo})
      @repo.remoteBranches().then (branches) =>
        _.each branches, (branch) => @add new RemoteBranch(branch, {'repo': @repo})
        @select(@selectedIndex)
        @trigger('repaint') unless silent
    .catch (error) -> new ErrorView(error)

  # Public: Return the local branches from the branch list.
  #
  # Returns the local branches as {Array}.
  local: =>
    @filter (branch) -> branch.local

  # Public: Return the remote branches from the branch list.
  #
  # Returns the remote branches as {Array}.
  remote: =>
    @filter (branch) -> branch.remote

module.exports = BranchList
