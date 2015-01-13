PropertyHomeCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.filter = {id:'all',text:'Showing all'}

  promise = null

  # search within title | address1 | city | zip
  $scope.$watch 'search', (n,o) -> if o
    $timeout.cancel promise
    promise = $timeout (->
      $http.get('/data/properties', {params: {term: n}}).success (rsp) -> $scope.properties = rsp
    ), 400

  $scope.page_changed = (n) ->
    angular.element('body, html').animate
      scrollTop: 0
    , 'fast'
    return true

  $scope.filters = ->
    {
      dropdownCssClass: 'filters'
      minimumResultsForSearch: 8
      data: [{id:'all',text:'Showing all'}]
      initSelection: (el, cb) ->
    }

]

app = angular.module('porter').controller('properties', PropertyHomeCtrl)
