app = angular.module('porter').factory '$exceptionHandler', ['$log', ($log) -> (error, cause) ->
  appsignal.sendError error if typeof appsignal != 'undefined'
  $log.error error.message
]