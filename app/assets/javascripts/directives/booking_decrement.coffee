app = angular.module('porter').directive('bookingDecrement', [-> (scope, element, attrs) ->
  element.on 'click', ->
    input = element.siblings('input')
    val = parseInt(input.val())
    if val > 0
      scope.$apply ->
        scope.extra.king_sets = val - 1 if attrs.bookingDecrement is 'extra_king_sets'
        scope.extra.twin_sets = val - 1 if attrs.bookingDecrement is 'extra_twin_sets'
        scope.extra.toiletry_sets = val - 1 if attrs.bookingDecrement is 'extra_toiletry_sets'
        scope.calculate_pricing()
])
