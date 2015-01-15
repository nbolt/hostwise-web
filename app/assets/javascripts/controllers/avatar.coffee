AvatarCtrl = ['$scope', '$http', '$timeout', '$upload', ($scope, $http, $timeout, $upload) ->

  $scope.files = []

  $scope.$watch 'files', ->
    i = 0
    while i < $scope.files.length
      file = $scope.files[i]
      $scope.upload = $upload.upload(
        url: '/user/update'
        data:
          step: 'photo'
        method: 'PUT'
        file: file
      ).success((rsp, status, headers, config) ->
        if rsp.success
          window.location = window.location.href
        else
          flash('failure', rsp.message)
      )
      i++

  flash = (type, msg) ->
    el = angular.element('.avatar .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

]

app = angular.module('porter').controller('avatar', AvatarCtrl)
