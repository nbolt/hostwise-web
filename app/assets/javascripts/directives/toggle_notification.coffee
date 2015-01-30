app = angular.module('porter').directive('toggleNotification', [-> (scope, element, attrs) ->
  element.on 'change', ->
    idx = attrs.toggleNotification.lastIndexOf('_')
    key = attrs.toggleNotification.substr(0, idx)
    type = attrs.toggleNotification.substr(idx + 1)

    if element.is(':checked')
      scope.$apply -> scope.user.notification_settings[key][type] = true
    else
      scope.user.notification_settings[key][type] = false
])
