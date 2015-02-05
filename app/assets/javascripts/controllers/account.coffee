AccountCtrl = ['$scope', '$http', '$timeout', '$upload', 'ngDialog', ($scope, $http, $timeout, $upload, ngDialog) ->

  $scope.files = []

  $scope.update = (step) ->
    $http.put('/user/update', {
      user: $scope.user
      step: step
    }).success (rsp) ->
      if rsp.success
        message = 'Contact info'
        if step is 'password'
          message = 'Password'
          $scope.user.password = ''
          $scope.user.password_confirmation = ''
          $scope.user.current_password = ''
        message += ' updated successfully!'
        flash 'info', message
      else
        flash 'failure', rsp.message

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
          flash 'failure', rsp.message
      )
      i++

  $scope.open_deactivation = ->
    ngDialog.open template: 'account-deactivation-modal', controller: 'account', className: 'account', scope: $scope

  $scope.cancel_deactivation = -> ngDialog.closeAll()

  $scope.confirm_deactivation = ->
    $http.post('/user/deactivate').success (rsp) ->
      if rsp.success
        window.location = '/'
      else
        flash 'failure', rsp.message

  flash = (type, msg) ->
    el = angular.element('.account-container form .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

]

app = angular.module('porter').controller('account', AccountCtrl)
