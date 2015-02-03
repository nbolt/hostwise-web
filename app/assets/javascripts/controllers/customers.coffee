CustomersCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  promise = null

  $scope.$on 'fetch_hosts', ->
    $http.get(window.location.href + '.json').success (rsp) ->
      $scope.users = rsp

  $scope.$emit 'fetch_hosts'

  $scope.$watch 'search', (n,o) -> if o
    $timeout.cancel promise
    promise = $timeout (->
      $http.get('/data/hosts', {params: {term: n}}).success (rsp) -> $scope.users = rsp if $scope.users
    ), 400

]

app = angular.module('porter').controller('customers', CustomersCtrl)
