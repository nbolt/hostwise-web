ModalCtrl = ['$scope', '$timeout', 'ngDialog', ($scope, $timeout, ngDialog) ->
  $scope.show_signin = ->
    ngDialog.closeAll()
    $timeout((->
      ngDialog.open template: 'modal-sign-in', className: 'auth'
    ), 700)

  $scope.show_signup = ->
    ngDialog.closeAll()
    $timeout((->
      ngDialog.open template: 'modal-sign-up', className: 'auth'
    ), 700)

  $scope.show_forgot_pwd = ->
    ngDialog.closeAll()
    $timeout((->
      ngDialog.open template: 'modal-forgot-pwd', className: 'auth'
    ), 700)
]

app = angular.module('porter').controller('modal', ModalCtrl)
