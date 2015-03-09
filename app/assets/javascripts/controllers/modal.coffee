ModalCtrl = ['$scope', '$timeout', 'ngDialog', '$rootScope', ($scope, $timeout, ngDialog, $rootScope) ->
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

  $rootScope.$on 'ngDialog.opened', (e, $dialog) ->
    el = $dialog.find('input')[0]
    el.focus()
]

app = angular.module('porter').controller('modal', ModalCtrl)
