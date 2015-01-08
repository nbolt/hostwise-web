AuthCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.posting = false
  $scope.form = { role: 'host' }

  $scope.signin = ->
    $http.post('/auth/signin', {
      form: $scope.form
    }).success (rsp) ->
      if rsp.success
        window.location = rsp.redirect_to
      else
        flash('failure', rsp.message)

  $scope.step = (n) ->
    if n < 4
      success = -> angular.element('#signup .steps').css('margin-left', -(n * 600))
    else
      success = -> $http.post('/auth/phone_confirmed', { email: $scope.form.email }).success (rsp) -> window.location = '/'
    
    unless $scope.posting
      $scope.posting = true
      $http.post('/auth/signup', {
        stage: n
        form: $scope.form
        code: $scope.confirmation_code
      }).success (rsp) ->
        $scope.posting = false
        if rsp.success
          success()
        else
          flash('failure', rsp.message)


  flash = (type, msg) ->
    el = angular.element('#signin .flash, #signup .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

]

app = angular.module('porter').controller('auth', AuthCtrl)
