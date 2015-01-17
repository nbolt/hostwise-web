PropertySearchCtrl = ['$scope', '$http', '$timeout', '$window', ($scope, $http, $timeout, $window) ->

  $scope.$watch 'property_search', (n,o) -> if o
    $timeout.cancel promise
    promise = $timeout (->
      $http.get('/data/properties', {params: {term: $scope.property_search}}).success (rsp) -> $scope.user.properties = rsp
    ), 400

]

app = angular.module('porter').controller('property_search', PropertySearchCtrl)
