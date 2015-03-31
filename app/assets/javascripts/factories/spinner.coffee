app = angular.module('porter').factory 'spinner', [->
  startSpin: -> angular.element('#spinner-overlay').addClass 'active'
  stopSpin: -> angular.element('#spinner-overlay').removeClass 'active'
]