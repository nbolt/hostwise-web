app = angular.module('porter').directive('propertiesDropdown', [-> (scope, element, attrs) ->
  element.on 'click', '.icon-button', ->
    element.siblings('#user').find('.drop-container').css('max-height', 0)
    menu = element.children('.drop-container')
    if menu.css('max-height') == '0px'
      max_height = 70 + (scope.user.properties.length * 40)
      max_height = 310 if max_height > 310
      menu.css('max-height', max_height)
    else
      menu.css('max-height', 0)
    menu.on 'mouseleave', -> menu.css('max-height', 0)
])
