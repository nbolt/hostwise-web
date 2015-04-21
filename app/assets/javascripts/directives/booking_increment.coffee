app = angular.module('porter').directive('bookingIncrement', [-> (scope, element, attrs) ->
  element.on 'click', ->
    input = element.siblings('input')
    scope.$apply -> scope.extra.king_sets = parseInt(input.val()) + 1 if attrs.bookingIncrement is 'extra_king_sets'
    scope.$apply -> scope.extra.twin_sets = parseInt(input.val()) + 1 if attrs.bookingIncrement is 'extra_twin_sets'
    scope.$apply -> scope.extra.toiletry_sets = parseInt(input.val()) + 1 if attrs.bookingIncrement is 'extra_toiletry_sets'
    scope.calculate_pricing()
])
