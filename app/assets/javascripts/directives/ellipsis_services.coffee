app = angular.module('porter').directive('ellipsisServices', ['$timeout', ($timeout) ->
  link: (scope, element, attr) ->
    element.hover(
        (->
          element.find('.text').text scope.booking.display_full_services
          element.find('.text').css 'max-height', 76
      ),(->
          $timeout((->element.find('.text').text scope.booking.display_services),400)
          element.find('.text').css 'max-height', 20
      )
    )
])
