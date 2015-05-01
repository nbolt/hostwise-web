exports.config = {
  allScriptsTimeout: 11000,

  specs: [
    '../test/jasmine/e2e/**/*.js'
  ],

  capabilities: {
    'browserName': 'phantomjs',
    'phantomjs.binary.path': 'node_modules/.bin/phantomjs'
  },

  baseUrl: 'http://hostwise-web.dev/',

  framework: 'jasmine2',

  jasmineNodeOpts: {
    defaultTimeoutInterval: 30000
  }
};