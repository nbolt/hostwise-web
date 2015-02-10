#app = angular.module('porter').directive('slideBody', [-> (scope, element, attrs) ->
#  if angular.element('#sidebar-container').width() < 220
#    angular.element('#sidebar-container').hover(
#      (->
#        element.css('margin-left', 220)
#      ),
#      (->
#        element.css('margin-left', 80)
#      )
#    )
#])
