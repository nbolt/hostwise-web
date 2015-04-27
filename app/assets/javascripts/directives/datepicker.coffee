app = angular.module('porter').directive('datepicker', [->
  link: (scope, element, attr) -> element.datepicker()
])
