{$$, ScrollView} = require 'atom'
IncompatiblePackageView = require './incompatible-package-view'

module.exports =
class IncompatiblePackagesView extends ScrollView
  @content: ->
    @div class: 'tool-panel panel-bottom padded incompatible-packages native-key-bindings', tabindex: -1, =>
      @div class: 'padded', =>
        @div outlet: 'description'

  initialize: ({@uri}) ->
    if atom.packages.getActivePackages().length > 0
      @populateViews()
    else
      # Render on next tick so packages have been activated
      setImmediate => @populateViews()

  populateViews: ->
    incompatiblePackageCount = 0
    for pack in atom.packages.getLoadedPackages()
      if typeof pack.isCompatible is 'function' and not pack.isCompatible()
        incompatiblePackageCount++
        @append(new IncompatiblePackageView(pack))

    @addDescription(incompatiblePackageCount)

  addDescription: (incompatiblePackageCount) ->
    if incompatiblePackageCount > 0
      @description.append $$ ->
        @p """
          The following packages could not be loaded because they contain native
          modules that aren't compatible with this version of Atom.
        """

        @p """
          Previous Atom versions shipped with Chrome 32 and node 0.11.10 but
          Atom now ships with Chrome 35 and node 0.11.13.
        """

        @p """
          These packages should now ship versions of these native modules that
          are compatible with node 0.11.13.
        """

        @p """
          Updates for these packages may already be available that resolve
          this issue.
        """

        @p """
          If no update is available you may want to notify the package author
          that their package isn't supported in Atom #{atom.getVersion()}
          because of the Chrome 35 and node 0.11.13 upgrade.
        """
    else
      @description.text 'All of your packages installed to ~/.atom.packages are compatible with this version of Atom.'

  serialize: ->
    deserializer: @constructor.name
    uri: @getUri()

  getUri: -> @uri

  getTitle: -> 'Incompatible Packages'

  getIconName: -> 'package'
