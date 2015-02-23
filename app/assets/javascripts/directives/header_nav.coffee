app = angular.module('porter').directive('headerNav', [-> (scope, element, attrs) ->
  element.find('#user').on 'click', ->
    menu = element.find('#user .drop-container')
    element.find('.link .drop-container').css('max-height', 0)
    if menu.css('max-height') == '0px'
      menu.css('max-height', 260)
    else
      menu.css('max-height', 0)

    menu.on 'mouseleave', ->
      menu.css('max-height', 0)
])
