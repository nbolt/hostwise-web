app = angular.module('porter').directive('sidebarDropdown', [-> (scope, element, attrs) ->
  element.on 'click', '.title', ->
    if element.children('.drop-container').css('max-height') == '0px'
      max_height = if attrs.sidebarDropdown == '' then 82 + (scope.properties.length * 40) else parseInt attrs.sidebarDropdown
      element.addClass('active')
      element.children('.drop-container').css('max-height', max_height)
    else
      element.children('.drop-container').css('max-height', 0)
      element.removeClass('active')
])
