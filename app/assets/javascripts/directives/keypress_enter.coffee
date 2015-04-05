app = angular.module('porter').directive('keypressEnter', [-> (scope, element, attrs) ->
  element.bind 'keydown keypress', (event) ->
    if event.which == 13
      scope.$apply ->
        scope.$eval attrs.keypressEnter
      event.preventDefault()
])
