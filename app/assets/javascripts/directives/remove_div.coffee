app = angular.module('porter').directive('removeDiv', [->
  link: (scope, element, attr) ->
    if scope.bookingQ
      scope.bookingQ.promise.then -> element.find('.div').last().remove()
    else
      scope.jobQ.promise.then -> element.find('.div').last().remove()
])
