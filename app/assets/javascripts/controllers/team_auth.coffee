TeamAuthCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.posting = false
  $scope.form = { role: 'contractor' }

  $scope.signin = ->
    $http.post('/auth/signin', {
      form: $scope.form
    }).success (rsp) ->
      if rsp.success
        window.location = rsp.redirect_to
      else
        flash('failure', rsp.message)

  flash = (type, msg) ->
    angular.element('#signin .flash').removeClass('success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      angular.element('#signin .flash').css('opacity', 0)
    ), 3000)

]

app = angular.module('porter').controller('team-auth', TeamAuthCtrl)
