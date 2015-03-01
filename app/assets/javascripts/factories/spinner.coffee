app = angular.module('porter').factory 'spinner', [->
    spinner =
      request: (config) ->
        angular.element('#spin-overlay').addClass 'active' if config.data && config.data.spinner
        config
      response: (response) ->
        angular.element('#spin-overlay').removeClass 'active'
        response
    spinner
]