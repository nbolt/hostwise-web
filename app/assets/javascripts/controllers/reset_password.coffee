ResetPwdCtrl = ['$scope', '$http', '$timeout', '$window', ($scope, $http, $timeout, $window) ->

  $scope.posting = true
  $scope.form = {}

  $scope.reset_pwd = ->
    $http.post('/password_resets/create', {
      form: $scope.form
    }).success (rsp) ->
      if rsp.success
        flash('info', rsp.message)
      else
        flash('failure', rsp.message)

  $scope.save_pwd = ->
    url = $window.location.href.split('/')
    token = url[url.length-2]
    $http.put('/password_resets/' + token, {
      form: $scope.form
    }).success (rsp) ->
      if rsp.success
        window.location = rsp.redirect_to
      else
        flash('failure', rsp.message)

  flash = (type, msg) ->
    el = angular.element('.forgotpwd .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

]

app = angular.module('porter').controller('reset-pwd', ResetPwdCtrl)
