AccountCtrl = ['$scope', '$http', '$timeout', '$window', ($scope, $http, $timeout, $window) ->

  $scope.form = {}

  $http.get($window.location.href + '.json').success (rsp) ->
    $scope.form.email = rsp.email
    $scope.form.phone_number = rsp.phone_number
    $scope.form.first_name = rsp.first_name
    $scope.form.last_name = rsp.last_name

  $scope.update = (step) ->
    $http.put('/user/update', {
      form: $scope.form
      step: step
    }).success (rsp) ->
      if rsp.success
        message = 'Contact info'
        if step is 'password'
          message = 'Password'
          $scope.form.password = ''
          $scope.form.password_confirmation = ''
          $scope.form.current_password = ''
        message += ' updated successfully!'
        flash('info', message)
      else
        flash('failure', rsp.message)

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
