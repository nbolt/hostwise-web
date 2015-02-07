app = angular.module('porter').directive('ellipsisServices', [->
  link: (scope, element, attr) ->
    element.hover(
        (->
          element.text scope.booking.display_full_services
      ),(->
          element.text scope.booking.display_services
      )
    )
])
