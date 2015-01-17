app = angular.module('porter').directive('propertiesDropdown', [-> (scope, element, attrs) ->
  element.on 'click', ->
    if element.children('.drop-container').css('max-height') == '0px'
      max_height = 70 + (scope.user.properties.length * 40)
      max_height = 310 if max_height > 310
      element.children('.drop-container').css('max-height', max_height)
    else
      element.children('.drop-container').css('max-height', 0)    
])