NotificationCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.save = (pref) ->
    $http.put('/notifications/update', {
      user: $scope.user
    }).success (rsp) ->
      flash 'info', 'Your changes have been saved!', pref if rsp.success

  flash = (type, msg, pref) ->
    el = angular.element(".notification-container form .section.#{pref} .flash")
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

]

app = angular.module('porter').controller('notification', NotificationCtrl)
