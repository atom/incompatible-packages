/** @babel */
/** @jsx etch.dom */

import {BufferedProcess} from 'atom'
import etch from 'etch'
import VIEW_URI from './view-uri'

export default class IncompatiblePackagesComponent {
  constructor (packageManager) {
    this.packageStatuses = new Map
    this.packageManager = packageManager
    this.loaded = false
    etch.createElement(this)

    if (this.packageManager.getActivePackages().length > 0) {
      this.populateIncompatiblePackages()
    } else {
      global.setImmediate(this.populateIncompatiblePackages.bind(this))
    }

    this.element.addEventListener('click', (event) => {
      if (event.target === this.refs.rebuildButton) {
        this.rebuildIncompatiblePackages()
      }
    })
  }

  render () {
    if (!this.loaded) {
      return <div className='incompatible-packages'>Loading...</div>
    }

    return (
      <div className='incompatible-packages padded native-key-bindings'>
        {this.renderDescription()}
        {this.renderIncompatiblePackageList()}
      </div>
    )
  }

  renderDescription () {
    if (this.incompatiblePackages.length > 0) {
      return (
        <div>
          <div className='alert alert-danger icon icon-bug'>
            Some installed packages could not be loaded because they contain native
            modules that were compiled for an earlier version of Atom.

            <button ref='rebuildButton' className='btn pull-right'>
              Rebuild Packages
            </button>
          </div>
        </div>
      )
    } else {
      return (
        <div className='alert alert-success icon icon-check'>
          None of your packages contain incompatible native modules.
        </div>
      )
    }
  }

  renderIncompatiblePackageList () {
    return (
      <div>{
        this.incompatiblePackages.map((pack) =>
          <div className={'incompatible-package ' + (this.packageStatuses.get(pack) || '')}>
            <h5>{pack.name} {pack.metadata.version}</h5>
            <ul>{
              pack.incompatibleModules.map((nativeModule) =>
                <li>
                  <div className='icon icon-file-binary'>
                    {nativeModule.name}@{nativeModule.version} – <span className='text-warning'>{nativeModule.error}</span>
                  </div>
                </li>
              )
            }</ul>
          </div>
        )
      }</div>
    )
  }

  populateIncompatiblePackages () {
    this.incompatiblePackages =
      this.packageManager
        .getLoadedPackages()
        .filter(pack => !pack.isCompatible())
    this.loaded = true
    etch.updateElement(this)
  }

  async rebuildIncompatiblePackages () {
    for (let pack of this.incompatiblePackages) {
      try {
        this.setPackageStatus(pack, 'rebuilding')
        await this.rebuildPackage(pack)
        this.setPackageStatus(pack, 'rebuild-succeeded')
      } catch (error) {
        this.setPackageStatus(pack, 'rebuild-failed')
      }
    }
  }

  rebuildPackage (pack) {
    return new Promise((resolve, reject) => {
      this.runRebuildProcess(pack.path, (result) => {
        if (result.code === 0) {
          resolve()
        } else {
          reject(result)
        }
      })
    })
  }

  runRebuildProcess (packagePath, cb) {
    let stderr = ''
    let stdout = ''
    new BufferedProcess({
      command: this.packageManager.getApmPath(),
      args: ['rebuild'],
      options: {cwd: packagePath},
      stderr: (output => stderr += output),
      stdout: (output => stdout += output),
      exit: (code => cb({code, stdout, stderr}))
    })
  }

  setPackageStatus (pack, status) {
    this.packageStatuses.set(pack, status)
    etch.updateElement(this)
  }

  getTitle () {
    return 'Incompatible Packages'
  }

  getURI () {
    return VIEW_URI
  }

  getIconName () {
    return 'package'
  }

  serialize () {
    return {deserializer: 'IncompatiblePackagesComponent'}
  }
}
