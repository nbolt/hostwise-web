ModalCtrl = ['$scope', '$timeout', 'ngDialog', ($scope, $timeout, ngDialog) ->
  $scope.show_signin = ->
    openDialog 'modal-sign-in'

  $scope.show_signup = ->
    openDialog 'modal-sign-up'

  $scope.show_forgot_pwd = ->
    openDialog 'modal-forgot-pwd'

  openDialog = (id) ->
    if angular.element('.ngdialog')[0]
      ngDialog.closeAll()
      $timeout((->ngDialog.open template: id, className: 'auth full'),600)
    else
      ngDialog.open template: id, className: 'auth full'
]

app = angular.module('porter').controller('modal', ModalCtrl)
