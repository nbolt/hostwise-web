app = angular.module('porter').factory '$exceptionHandler', [-> (error, cause) ->
  appsignal.sendError error
]