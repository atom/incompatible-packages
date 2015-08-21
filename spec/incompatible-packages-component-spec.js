/** @babel */

import etch from 'etch'
import IncompatiblePackagesComponent from '../lib/incompatible-packages-component'

describe('IncompatiblePackagesComponent', () => {
  let packages

  beforeEach(() => {
    packages = [
      {
        name: 'incompatible-1',
        isCompatible: () => false,
        path: '/Users/joe/.atom/packages/incompatible-1',
        metadata: {
          repository: 'https://github.com/atom/incompatible-1',
          version: '1.0.0'
        },
        incompatibleModules: [
          {name: 'x', version: '1.0.0', error: 'Expected version X, got Y'},
          {name: 'y', version: '1.0.0', error: 'Expected version X, got Z'}
        ],
      },
      {
        name: 'incompatible-2',
        isCompatible: () => false,
        path: '/Users/joe/.atom/packages/incompatible-2',
        metadata: {
          repository: 'https://github.com/atom/incompatible-2',
          version: '1.0.0'
        },
        incompatibleModules: [
          {name: 'z', version: '1.0.0', error: 'Expected version X, got Y'}
        ],
      },
      {
        name: 'compatible',
        isCompatible: () => true,
        path: '/Users/joe/.atom/packages/b',
        metadata: {
          repository: 'https://github.com/atom/b',
          version: '1.0.0'
        },
        incompatibleModules: []
      }
    ]
  })

  describe('when packages have not finished loading', () => {
    it('delays rendering incompatible packages until the end of the tick', () => {
      waitsForPromise(async () => {
        let component =
          new IncompatiblePackagesComponent({
            getActivePackages: () => [],
            getLoadedPackages: () => packages
          })
        let {element} = component

        expect(element.querySelectorAll('.incompatible-package').length).toEqual(0)

        await new Promise(global.setImmediate)
        await new Promise(global.requestAnimationFrame)

        expect(element.querySelectorAll('.incompatible-package').length).toBeGreaterThan(0)
      })
    })
  })

  describe('when there are no incompatible packages', () => {
    it('does not render incompatible packages or the rebuild button', () => {
      waitsForPromise(async () => {
        expect(packages[2].isCompatible()).toBe(true)
        let compatiblePackages = [packages[2]]

        let component =
          new IncompatiblePackagesComponent({
            getActivePackages: () => compatiblePackages,
            getLoadedPackages: () => compatiblePackages
          })
        let {element} = component

        await new Promise(global.requestAnimationFrame)

        expect(element.querySelectorAll('.incompatible-package').length).toBe(0)
        expect(element.querySelector('button')).toBeNull()
      })
    })
  })

  describe('when there are incompatible packages', () => {
    it('renders incompatible packages and the rebuild button', () => {
      waitsForPromise(async () => {
        let component =
          new IncompatiblePackagesComponent({
            getActivePackages: () => packages,
            getLoadedPackages: () => packages
          })
        let {element} = component

        await new Promise(global.requestAnimationFrame)

        expect(element.querySelectorAll('.incompatible-package').length).toEqual(2)
        expect(element.querySelector('button')).not.toBeNull()
      })
    })

    describe('when the rebuild button is clicked', () => {
      it('rebuilds every incompatible package, updating each package\'s view with status', () => {
        waitsForPromise(async () => {
          let component =
            new IncompatiblePackagesComponent({
              getActivePackages: () => packages,
              getLoadedPackages: () => packages
            })
          let {element} = component
          jasmine.attachToDOM(element)

          await new Promise(global.requestAnimationFrame)

          rebuildCalls = []
          spyOn(component, 'runRebuildProcess').andCallFake((packagePath, callback) => {
            rebuildCalls.push({packagePath, callback})
          })

          component.rebuildIncompatiblePackages()
          await etch.getScheduler().getNextUpdatePromise() // view update

          expect(rebuildCalls.length).toBe(1)
          expect(rebuildCalls[0].packagePath).toBe('/Users/joe/.atom/packages/incompatible-1')

          expect(element.querySelector('.incompatible-package:nth-child(1) .badge').textContent).toBe('Rebuilding')
          expect(element.querySelector('.incompatible-package:nth-child(2) .badge')).toBeNull()

          rebuildCalls[0].callback({code: 0}) // simulate rebuild success
          await etch.getScheduler().getNextUpdatePromise() // view update

          expect(rebuildCalls.length).toBe(2)
          expect(rebuildCalls[1].packagePath).toBe('/Users/joe/.atom/packages/incompatible-2')

          expect(element.querySelector('.incompatible-package:nth-child(1) .badge').textContent).toBe('Rebuild Succeeded')
          expect(element.querySelector('.incompatible-package:nth-child(2) .badge').textContent).toBe('Rebuilding')

          rebuildCalls[1].callback({code: 12, stderr: 'This is an error from the test!'}) // simulate rebuild failure
          await etch.getScheduler().getNextUpdatePromise() // view update

          expect(element.querySelector('.incompatible-package:nth-child(1) .badge').textContent).toBe('Rebuild Succeeded')
          expect(element.querySelector('.incompatible-package:nth-child(2) .badge').textContent).toBe('Rebuild Failed')
          expect(element.querySelector('.incompatible-package:nth-child(2) pre').textContent).toBe('This is an error from the test!')
        })
      })
    })
  })
})
