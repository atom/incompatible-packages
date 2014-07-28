_ = require 'underscore-plus'
{View} = require 'atom'

module.exports =
class IncompatiblePackagesStatusView extends View
  @content: ->
    @div class: 'inline-block text text-error', =>
      @span class: 'icon icon-bug'
      @span outlet: 'countLabel', class: 'incompatible-packages-status'

  initialize: (statusBar, incompatibleCount) ->
    @countLabel.text(incompatibleCount)
    @setTooltip(_.pluralize(incompatibleCount, 'incompatible package'))
    statusBar.appendRight(this)

    @subscribe this, 'click', =>
      @trigger('incompatible-packages:view')
      @destroyTooltip()
      @remove()
