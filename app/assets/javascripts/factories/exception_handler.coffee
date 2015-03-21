app = angular.module('porter').factory '$exceptionHandler', ['$log', ($log) -> (error, cause) ->
  appsignal.sendError error
  $log.error error.message
]