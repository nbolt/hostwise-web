app = angular.module('porter').directive('ellipsisServices', ['$timeout', ($timeout) ->
  link: (scope, element, attr) ->
    element.hover(
        (->
          element.text scope.booking.display_full_services
          element.css 'max-height', 76
      ),(->
          $timeout((->element.text scope.booking.display_services),400)
          element.css 'max-height', 20
      )
    )
])
