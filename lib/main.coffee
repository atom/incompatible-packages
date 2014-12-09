IncompatiblePackagesView = null

viewUri = 'atom://incompatible-packages'
createView = (state) ->
  IncompatiblePackagesView ?= require './incompatible-packages-view'
  new IncompatiblePackagesView(state)

atom.deserializers.add
  name: 'IncompatiblePackagesView'
  deserialize: (state) -> createView(state)

incompatiblePackagesStatusView = null
openerSubscription = null
workspaceSubscription = null

module.exports =
  activate: ->
    openerSubscription = atom.workspace.addOpener (filePath) ->
      createView(uri: viewUri) if filePath is viewUri

    workspaceSubscription = atom.commands.add 'atom-workspace',
      'incompatible-packages:view': ->
        atom.workspace.open(viewUri)

      'incompatible-packages:clear-cache': ->
        for key, data of global.localStorage
          if key.indexOf('installed-packages:') is 0
            global.localStorage.removeItem(key)

      'incompatible-packages:reload-atom-and-recheck-packages': ->
        workspaceView = atom.views.getView(atom.workspace)
        workspaceView.trigger 'incompatible-packages:clear-cache'
        workspaceView.trigger 'window:reload'

    if statusBar = document.querySelector('status-bar')
      createStatusBarView(statusBar)
    else
      atom.packages.onDidActivateAll ->
        statusBar = document.querySelector('status-bar')
        createStatusBarView(statusBar) if statusBar?

  deactivate: ->
    incompatiblePackagesStatusView?.remove()
    incompatiblePackagesStatusView = null

    openerSubscription?.dispose()
    openerSubscription = null

    workspaceSubscription?.dispose()
    workspaceSubscription = null

createStatusBarView = (statusBar) ->
  incompatibleCount = 0
  for pack in atom.packages.getLoadedPackages()
    incompatibleCount++ unless pack.isCompatible()

  if incompatibleCount > -1
    IncompatiblePackagesStatusView = require './incompatible-packages-status-view'
    incompatiblePackagesStatusView ?= new IncompatiblePackagesStatusView(statusBar, incompatibleCount)
