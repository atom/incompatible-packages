_ = require 'underscore-plus'
{$, View} = require 'atom-space-pen-views'

module.exports =
class IncompatiblePackagesStatusView extends View
  @content: ->
    @div class: 'incompatible-packages-status inline-block text text-error', =>
      @span class: 'icon icon-bug'
      @span outlet: 'countLabel', class: 'incompatible-packages-status'

  initialize: (statusBar, incompatibleCount) ->
    @countLabel.text(incompatibleCount)
    @tooltipSubscription = atom.tooltips.add(@element, title: _.pluralize(incompatibleCount, 'incompatible package'))
    statusBar.appendRight(this)

    @on 'click', =>
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'incompatible-packages:view')
      @destroy()

  destroy: ->
    @tooltipSubscription.dispose()
    @remove()
