ModalCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->
  $scope.show_signin = ->
    ngDialog.closeAll()
    $timeout((->
      ngDialog.open template: 'modal-sign-in'
    ), 700)

  $scope.show_signup = ->
    ngDialog.closeAll()
    $timeout((->
      ngDialog.open template: 'modal-sign-up'
    ), 700)

  $scope.show_forgot_pwd = ->
    ngDialog.closeAll()
    $timeout((->
      ngDialog.open template: 'modal-forgot-pwd'
    ), 700)
]

app = angular.module('porter').controller('modal', ModalCtrl)
