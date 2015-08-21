/** @babel */
/** @jsx etch.dom */

import {BufferedProcess} from 'atom'
import etch from 'etch'

import VIEW_URI from './view-uri'
const REBUILDING = 'rebuilding'
const REBUILD_FAILED = 'rebuild-failed'
const REBUILD_SUCCEEDED = 'rebuild-succeeded'

export default class IncompatiblePackagesComponent {
  constructor (packageManager) {
    this.rebuildStatuses = new Map
    this.rebuildFailureOutputs = new Map
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
        this.incompatiblePackages.map(this.renderIncompatiblePackage.bind(this))
      }</div>
    )
  }

  renderIncompatiblePackage (pack) {
    let rebuildStatus = this.rebuildStatuses.get(pack)

    return (
      <div className={'incompatible-package'}>
        {this.renderRebuildStatusIndicator(rebuildStatus)}
        <h4 className='heading'>
          {pack.name} {pack.metadata.version}
        </h4>
        {
          rebuildStatus
          ? this.renderRebuildOutput(pack)
          : this.renderIncompatibleModules(pack)
        }
      </div>
    )
  }

  renderRebuildStatusIndicator (rebuildStatus) {
    if (rebuildStatus === REBUILDING) {
      return (
        <div className='badge badge-info pull-right icon icon-gear'>
          Rebuilding
        </div>
      )
    } else if (rebuildStatus === REBUILD_SUCCEEDED) {
      return (
        <div className='badge badge-success pull-right icon icon-check'>
          Rebuild Succeeded
        </div>
      )
    } else if (rebuildStatus === REBUILD_FAILED) {
      return (
        <div className='badge badge-error pull-right icon icon-x'>
          Rebuild Failed
        </div>
      )
    }
  }

  renderRebuildOutput (pack) {
    if (this.rebuildStatuses.get(pack) === REBUILD_FAILED) {
      const {ansi_to_html} = require('ansi_up')
      return <pre innerHTML={ansi_to_html(this.rebuildFailureOutputs.get(pack))}></pre>
    } else {
      return ''
    }
  }

  renderIncompatibleModules (pack) {
    return (
      <ul>{
        pack.incompatibleModules.map((nativeModule) =>
          <li>
            <div className='icon icon-file-binary'>
              {nativeModule.name}@{nativeModule.version} – <span className='text-warning'>{nativeModule.error}</span>
            </div>
          </li>
        )
      }</ul>
    )
  }

  populateIncompatiblePackages () {
    this.incompatiblePackages =
      this.packageManager
        .getLoadedPackages()
        .filter(pack => !pack.isCompatible())

    for (let pack of this.incompatiblePackages) {
      let buildFailureOutput = pack.getBuildFailureOutput()
      if (buildFailureOutput) {
        this.setPackageStatus(pack, REBUILD_FAILED)
        this.setRebuildFailureOutput(pack, buildFailureOutput)
      }
    }

    this.loaded = true
    etch.updateElement(this)
  }

  async rebuildIncompatiblePackages () {
    for (let pack of this.incompatiblePackages) {
      this.setPackageStatus(pack, REBUILDING)
      let {code, stderr} = await pack.rebuild()
      if (code === 0) {
        this.setPackageStatus(pack, REBUILD_SUCCEEDED)
      } else {
        this.setRebuildFailureOutput(pack, stderr)
        this.setPackageStatus(pack, REBUILD_FAILED)
      }
    }
  }

  setPackageStatus (pack, status) {
    this.rebuildStatuses.set(pack, status)
    etch.updateElement(this)
  }

  setRebuildFailureOutput (pack, output) {
    this.rebuildFailureOutputs.set(pack, output)
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
