{$$, View} = require 'atom-space-pen-views'
_ = require 'underscore-plus'

module.exports =
class IncompatiblePackageView extends View
  @content: ->
    @div class: 'inset-panel', =>
      @div class: 'panel-heading', =>
        @span outlet: 'name'
        @span outlet: 'version'
        @span outlet: 'disabledLabel', class: 'text-info disabled-package', 'Disabled'
        @div class: 'btn-toolbar pull-right', =>
          @div class: 'btn-group', =>
            @button class: 'btn', outlet: 'updateButton', 'Check for Update'
            @button class: 'btn', outlet: 'issueButton', 'Report Issue'
            @button class: 'btn', outlet: 'disableButton', 'Disable Package'
      @div class: 'panel-body', =>
        @p 'Listed below are the incompatible native modules that this package depends on.'
        @ul class: 'list-tree', outlet: 'modules'

  initialize: (@pack) ->
    @updateButton.on 'click', ->
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'settings-view:install-packages')
      false

    @issueButton.on 'click', =>
      if repoUrl = @getRepositoryUrl()
        require('shell').openExternal("#{repoUrl}/issues")
      false

    @disabledLabel.hide()
    @disableButton.on 'click', =>
      atom.packages.disablePackage(@pack.name)
      @disabledLabel.show()
      false

    @name.text(_.undasherize(_.uncamelcase(@pack.name)))
    @version.text(" " + @pack.metadata.version)

    for nativeModule in @pack.incompatibleModules ? []
      @modules.append $$ ->
        @li class: 'list-nested-item', =>
          @div class: 'list-item', =>
            @span class: 'icon icon-file-binary', "#{nativeModule.name}@#{nativeModule.version}"
          @ul class: 'list-tree', =>
            @li class: 'list-nested-item', =>
              @div class: 'list-item', =>
                @span class: 'text-warning icon icon-bug', "Error message: #{nativeModule.error}"

  getRepositoryUrl: ->
    {repository} = @pack.metadata
    repoUrl = repository?.url ? repository ? ''
    repoUrl.replace(/\.git$/, '').replace(/\/+$/, '')
