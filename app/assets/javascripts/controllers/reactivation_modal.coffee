ReactivationModalCtrl = ['$scope', '$http', 'ngDialog', ($scope, $http, ngDialog) ->
  $scope.flashing = false

  $scope.cancel_reactivation = -> ngDialog.closeAll()

  $scope.confirm_reactivation = ->
    $http.post("/properties/#{$scope.property.slug}/reactivate").success (rsp) ->
      if rsp.success
        ngDialog.closeAll()
        $scope.property.active = true
      else
        flash 'failure', rsp.message

  flash = (type, msg) ->
    unless $scope.flashing
      $scope.flashing = true
      orig_msg = angular.element('.booking.modal .header .text').text()
      angular.element('.ngdialog-close').css 'opacity', 0
      angular.element('.booking.modal .header .text').css 'opacity', 0
      angular.element('.booking.modal .header').addClass type
      if msg.length > 37
        angular.element('.booking.modal .header').css 'height', 74
      $timeout((->
        angular.element('.booking.modal .header .text').text msg
        angular.element('.booking.modal .header .text').css 'opacity', 1
      ), 500)
      $timeout((->
        angular.element('.booking.modal .header').removeClass type
        angular.element('.booking.modal .header .text').css 'opacity', 0
        if msg.length > 37
          angular.element('.booking.modal .header').css 'height', 50
        $timeout((->
          angular.element('.booking.modal .header .text').text orig_msg
          angular.element('.booking.modal .header .text').css 'opacity', 1
          angular.element('.ngdialog-close').css 'opacity', 1
          $scope.flashing = false
        ), 500)
      ), 4000)
]

app = angular.module('porter').controller('reactivation_modal', ReactivationModalCtrl)
