describe "incompatible packages view", ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('incompatible-packages')

  it "opens a pane item when incompatible-packages:view is dispatched", ->
    atom.commands.dispatch(atom.views.getView(atom.workspace), 'incompatible-packages:view')

    waitsFor ->
      atom.workspace.getActivePaneItem()
