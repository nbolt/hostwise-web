app = angular.module('porter').directive('startTimer', [-> (scope, element, attrs) ->
  element[0].start() if scope.job.cant_access_seconds_left > 0
])
