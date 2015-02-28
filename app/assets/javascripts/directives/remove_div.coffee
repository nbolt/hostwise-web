app = angular.module('porter').directive('removeDiv', [->
  link: (scope, element, attr) ->
    scope.jobQ.promise.then -> element.find('.div').last().remove()
])
