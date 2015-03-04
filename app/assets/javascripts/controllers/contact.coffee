ContactCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.form = {}

  $scope.submit = ->
    $http.post('/contact_email', {form: $scope.form}).success (rsp) ->
      $scope.form = {}
      angular.element('.pl-confirmation').css 'opacity', 1
      $timeout((-> angular.element('.pl-confirmation').css 'opacity', 0), 10000)

]

app = angular.module('porter').controller('contact', ContactCtrl)
