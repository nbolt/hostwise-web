app = angular.module('porter').directive('toggleFaq', [->
  link: (scope, element, attr) ->
    element.click ->
      if element.hasClass 'active'
        element.removeClass 'active'
      else
        element.addClass 'active'
])
