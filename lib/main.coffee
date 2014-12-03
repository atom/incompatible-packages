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
    atom.workspace.addOpener (filePath) ->
      createView(uri: viewUri) if filePath is viewUri

    atom.workspaceView.command 'incompatible-packages:view', -> atom.workspaceView.open(viewUri)

    atom.workspaceView.command 'incompatible-packages:clear-cache', ->
      for key, data of global.localStorage
        if key.indexOf('installed-packages:') is 0
          global.localStorage.removeItem(key)

    atom.workspaceView.command 'incompatible-packages:reload-atom-and-recheck-packages', ->
      atom.workspaceView.trigger 'incompatible-packages:clear-cache'
      atom.workspaceView.trigger 'window:reload'

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
