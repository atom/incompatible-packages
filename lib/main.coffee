IncompatiblePackagesView = null

viewUri = 'atom://incompatible-packages'
createView = (state) ->
  IncompatiblePackagesView ?= require './incompatible-packages-view'
  new IncompatiblePackagesView(state)

atom.deserializers.add
  name: 'IncompatiblePackagesView'
  deserialize: (state) -> createView(state)

module.exports =
  activate: ->
    atom.workspace.registerOpener (filePath) ->
      createView(uri: viewUri) if filePath is viewUri

    atom.workspaceView.command 'incompatible-packages:view', -> atom.workspaceView.open(viewUri)
