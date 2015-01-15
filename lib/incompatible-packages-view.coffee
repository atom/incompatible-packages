{$$, ScrollView} = require 'atom-space-pen-views'
{Disposable} = require 'atom'
IncompatiblePackageView = require './incompatible-package-view'

module.exports =
class IncompatiblePackagesView extends ScrollView
  @content: ->
    @div class: 'tool-panel panel-bottom padded incompatible-packages native-key-bindings', tabindex: -1, =>
      @div class: 'padded', =>
        @div outlet: 'description'
        @div outlet: 'reloadArea', =>
          @p """
            If you think a package is listed here and should no longer be, click
            the button below to reload Atom and recheck all packages.
          """
          @button outlet: 'reloadButton', class: 'btn', 'Reload Atom And Recheck Packages'

  initialize: ({@uri}) ->
    @reloadArea.hide()

    if atom.packages.getActivePackages().length > 0
      @populateViews()
    else
      # Render on next tick so packages have been activated
      setImmediate => @populateViews()

    @reloadButton.on 'click', ->
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'incompatible-packages:reload-atom-and-recheck-packages')

  #TODO Remove both of these post 1.0
  onDidChangeTitle: -> new Disposable()
  onDidChangeModified: -> new Disposable()

  populateViews: ->
    incompatiblePackageCount = 0
    for pack in atom.packages.getLoadedPackages()
      if typeof pack.isCompatible is 'function' and not pack.isCompatible()
        incompatiblePackageCount++
        @append(new IncompatiblePackageView(pack))

    @addDescription(incompatiblePackageCount)

  addDescription: (incompatiblePackageCount) ->
    if incompatiblePackageCount > 0
      @reloadArea.show()
      @description.append $$ ->
        @p """
          The following packages could not be loaded because they contain native
          modules that aren't compatible with this version of Atom.
        """

        @p """
          Previous Atom versions shipped with Chrome 31 and Node 0.11.10 but
          Atom now ships with Chrome #{process.versions.chrome} and Node
          #{process.versions.node}.
        """

        @p """
          The packages listed should now ship versions of these native modules
          that are compatible with Node #{process.versions.node}.
        """

        @p """
          Updates for these packages may already be available that resolve
          this issue.
        """

        @p """
          If no update is available you may want to notify the package author
          that their package isn't supported in Atom #{atom.getVersion()}
          because of the Chrome #{process.versions.chrome} and Node
          #{process.versions.node} upgrade.
        """
    else
      @description.text 'All of your packages installed to ~/.atom.packages are compatible with this version of Atom.'

  serialize: ->
    deserializer: @constructor.name
    uri: @getURI()

  getURI: -> @uri

  getTitle: -> 'Incompatible Packages'

  getIconName: -> 'package'
