app = angular.module('porter').factory 'spinner', [->
  startSpin: -> angular.element('#spin-overlay').addClass 'active'
  stopSpin: -> angular.element('#spin-overlay').removeClass 'active'
]