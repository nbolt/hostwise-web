ModalCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  $scope.show_signin_modal = ->
    ngDialog.open template: 'modal-sign-in'

  $scope.show_signup_modal = ->
    ngDialog.open template: 'modal-sign-up'

]

app = angular.module('porter').controller('modal', ModalCtrl)
