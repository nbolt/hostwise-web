app = angular.module('porter').directive('decrement', [->
  scope:
    decrement: '='
  link: (scope, element, attr) -> element.click ->
    scope.$apply -> scope.decrement -= 1 if scope.decrement > 0
    scope.$emit 'calculate_pricing'
])
