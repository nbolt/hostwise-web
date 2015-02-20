PropertySearchCtrl = ['$scope', '$http', '$timeout', '$window', ($scope, $http, $timeout, $window) ->

  $scope.$watch 'property_search', (n,o) -> if o
    $timeout.cancel promise
    promise = $timeout (->
      $http.get('/data/properties', {params: {term: $scope.property_search}}).success (rsp) -> $scope.user.properties = rsp
    ), 400
    el = angular.element('.search .icon-close')
    if n
      el.show()
    else
      el.hide()

  $scope.clear = -> $scope.property_search = ''
]

app = angular.module('porter').controller('property_search', PropertySearchCtrl)
