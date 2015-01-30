app = angular.module('porter').directive('collapse', [->
  link: (scope, element, attr) ->
    element.on 'click', '.arrow', ->
      if element.find('.day-services').css('max-height') == '0px'
        element.find('.day-services').css 'max-height', 192
      else
        element.find('.day-services').css 'max-height', 0
])
