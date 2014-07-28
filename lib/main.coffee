IncompatiblePackagesView = null

viewUri = 'atom://incompatible-packages'
createView = (state) ->
  IncompatiblePackagesView ?= require './incompatible-packages-view'
  new IncompatiblePackagesView(state)

atom.deserializers.add
  name: 'IncompatiblePackagesView'
  deserialize: (state) -> createView(state)

incompatiblePackagesStatusView = null

module.exports =
  activate: ->
    atom.workspace.registerOpener (filePath) ->
      createView(uri: viewUri) if filePath is viewUri

    atom.workspaceView.command 'incompatible-packages:view', -> atom.workspaceView.open(viewUri)

    atom.packages.once 'activated', ->
      if atom.workspaceView?.statusBar?
        incompatibleCount = 0
        for pack in atom.packages.getLoadedPackages()
          incompatibleCount++ unless pack.isCompatible()

        if incompatibleCount > 0
          IncompatiblePackagesStatusView = require './incompatible-packages-status-view'
          incompatiblePackagesStatusView ?= new IncompatiblePackagesStatusView(atom.workspaceView.statusBar, incompatibleCount)

  deactivate: ->
    incompatiblePackagesStatusView?.remove()
