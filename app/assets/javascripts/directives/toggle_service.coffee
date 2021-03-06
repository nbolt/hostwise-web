app = angular.module('porter').directive('toggleService', [-> (scope, element, attrs) ->
  element.on 'change', ->
    if element.is(':checked')
      scope.$apply ->
        scope.selected_services[attrs.toggleService] = true
        scope.selected_services['preset'] = false if attrs.toggleService is 'cleaning'
      element.parent().parent().addClass 'active'
    else
      scope.selected_services[attrs.toggleService] = false
      scope.$apply ->
        element.parent().parent().removeClass 'active'
        scope.to_staging_confirmation() if attrs.toggleService is 'cleaning'
    scope.calculate_pricing()
])
