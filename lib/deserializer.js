module.exports = function () {
  const IncompatiblePackagesComponent = require('./incompatible-packages-component')
  return new IncompatiblePackagesComponent(atom.packages)
}
