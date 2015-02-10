app = angular.module('porter').directive('slideBody', [-> (scope, element, attrs) ->
  if angular.element('#sidebar-container').width() < 250
    angular.element('#sidebar-container').hover(
      (->
        element.css('margin-left', 300)
      ),
      (->
        element.css('margin-left', 130)
      )
    )
])
