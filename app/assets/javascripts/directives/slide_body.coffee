app = angular.module('porter').directive('slideBody', [-> (scope, element, attrs) ->
  angular.element('#sidebar-container').hover(
    (->
      element.css('margin-left', -278)
    ),
    (->
      element.css('margin-left', -448)
    )
  )
])