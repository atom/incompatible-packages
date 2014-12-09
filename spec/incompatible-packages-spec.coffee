fs = require 'fs-plus'
path = require 'path'
{$} = require 'atom-space-pen-views'

describe "incompatible packages view", ->
  beforeEach ->
    jasmine.attachToDOM(atom.views.getView(atom.workspace))

    packagePath = path.join(__dirname, 'fixtures', 'incompatible-package')
    fs.writeFileSync(path.join(packagePath, 'node_modules', 'bad', 'build', 'Release', 'bad.node'), 'this is not a valid native module')
    atom.packages.loadPackage(packagePath)

    waitsForPromise ->
      atom.packages.activatePackage('status-bar')

    waitsForPromise ->
      atom.packages.activatePackage('incompatible-packages')

  it "opens a pane item when incompatible-packages:view is dispatched", ->
    expect(atom.workspace.getActivePaneItem()).toBeFalsy()

    atom.commands.dispatch(atom.views.getView(atom.workspace), 'incompatible-packages:view')

    waitsFor ->
      atom.workspace.getActivePaneItem()

  describe "when the status bar entry is clicked", ->
    it "opens the pane item", ->
      expect(atom.workspace.getActivePaneItem()).toBeFalsy()

      $('.incompatible-packages-status').click()

      waitsFor ->
        atom.workspace.getActivePaneItem()

      runs ->
        expect($('.incompatible-packages-status').length).toBe 0
