ModalCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->
  $scope.show_signin = ->
    ngDialog.open template: 'modal-sign-in'

  $scope.show_signup = ->
    ngDialog.open template: 'modal-sign-up'

  $scope.show_forgot_pwd = ->
    ngDialog.open template: 'modal-forgot-pwd'
]

app = angular.module('porter').controller('modal', ModalCtrl)
