app = angular.module('porter').directive('slideBody', [-> (scope, element, attrs) ->
  angular.element('#sidebar-container').hover(
    (->
      element.css('margin-left', 300)
    ),
    (->
      element.css('margin-left', 130)
    )
  )
])