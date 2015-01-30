NotificationCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.save = ->
    $http.put('/notifications/update', {
      user: $scope.user
    }).success (rsp) ->
      flash 'info', 'Your changes have been saved!' if rsp.success

  flash = (type, msg) ->
    el = angular.element('.notification-container form .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

]

app = angular.module('porter').controller('notification', NotificationCtrl)
