PropertyHomeCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $http.get('/data/properties').success (rsp) -> $scope.properties = rsp

]

app = angular.module('porter').controller('properties', PropertyHomeCtrl)
