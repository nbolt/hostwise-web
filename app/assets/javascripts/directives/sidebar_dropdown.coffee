app = angular.module('porter').directive('sidebarDropdown', [-> (scope, element, attrs) ->
  element.on 'click', '.title', ->
    if element.children('.drop-container').css('max-height') == '0px'
      element.addClass('active')
      element.children('.drop-container').css('max-height', 75 + (scope.properties.length * 40))
      element.on 'mouseleave', ->
        element.off 'mouseleave'
        element.children('.drop-container').css('max-height', 0)
        element.removeClass('active')
    else
      element.children('.drop-container').css('max-height', 0)
      element.removeClass('active')
])