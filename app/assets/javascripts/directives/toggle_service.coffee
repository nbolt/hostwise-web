app = angular.module('porter').directive('toggleService', [-> (scope, element, attrs) ->
  element.on 'change', ->
    if element.is(':checked')
      scope.$apply -> scope.selected_services[attrs.toggleService] = true
      element.parent().parent().addClass 'active'
    else
      scope.selected_services[attrs.toggleService] = false
      scope.$apply -> element.parent().parent().removeClass 'active'
])
