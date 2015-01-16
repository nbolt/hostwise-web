ModalCtrl = ['$scope', '$timeout', 'ngDialog', ($scope, $timeout, ngDialog) ->
  $scope.show_signin = ->
    ngDialog.closeAll() if angular.element('.ngdialog')[0]
    ngDialog.open template: 'modal-sign-in', className: 'auth'

  $scope.show_signup = ->
    ngDialog.closeAll() if angular.element('.ngdialog')[0]
    ngDialog.open template: 'modal-sign-up', className: 'auth'

  $scope.show_forgot_pwd = ->
    ngDialog.closeAll() if angular.element('.ngdialog')[0]
    ngDialog.open template: 'modal-forgot-pwd', className: 'auth'
]

app = angular.module('porter').controller('modal', ModalCtrl)
