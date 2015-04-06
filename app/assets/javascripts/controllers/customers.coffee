CustomersCtrl = ['$scope', '$http', '$timeout', 'ngDialog', 'spinner', ($scope, $http, $timeout, ngDialog, spinner) ->

  promise = null

  $scope.$on 'fetch_hosts', ->
    spinner.startSpin()
    $http.get(window.location.href + '.json').success (rsp) ->
      $scope.users = rsp
      spinner.stopSpin()

  $scope.$emit 'fetch_hosts'

  $scope.$watch 'search', (n,o) -> if o
    $timeout.cancel promise
    promise = $timeout (->
      $http.get('/data/hosts', {params: {term: n}}).success (rsp) -> $scope.users = rsp if $scope.users
    ), 400

]

app = angular.module('porter').controller('customers', CustomersCtrl)
