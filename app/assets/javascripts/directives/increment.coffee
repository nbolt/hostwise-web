app = angular.module('porter').directive('increment', [->
  scope:
    increment: '='
  link: (scope, element, attr) -> element.click ->
    scope.$apply -> scope.increment += 1
    scope.$emit 'calculate_pricing'
])
