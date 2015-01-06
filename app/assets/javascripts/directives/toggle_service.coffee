app = angular.module('porter').directive('toggleService', [-> (scope, element, attrs) ->
  element.on('click', ->
    element.addClass('selecting')
    if ( element.hasClass('active') )
      delete scope.chosen_services[element.text()]
      element.removeClass('active')
    else
      scope.chosen_services[element.text()] = attrs.sid
      element.addClass('active')
    element.on('mouseleave.selecting', ->
      element.off('mouseleave.selecting')
      element.removeClass('selecting')
    )
  )
])
