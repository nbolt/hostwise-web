exports.config = {
  allScriptsTimeout: 15000,

  specs: [
    '../test/jasmine/e2e/*.js',
    '../test/jasmine/e2e/**/*.js'
  ],

  capabilities: {
    'browserName': 'phantomjs',
    'phantomjs.binary.path': './node_modules/phantomjs/bin/phantomjs'
  },

  //capabilities: {
  //  'browserName': 'firefox'
  //},

  baseUrl: 'http://hostwise-web.dev',

  framework: 'jasmine2',

  jasmineNodeOpts: {
    defaultTimeoutInterval: 30000
  }
};