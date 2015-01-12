PropertyHomeCtrl = ['$scope', '$http', '$timeout', '$document', ($scope, $http, $timeout, $document) ->

  $scope.filter = {id:'all',text:'Showing all'}

  promise = null

  # search within title | address1 | city | zip
  $scope.$watch 'search', (n,o) -> if o
    $timeout.cancel promise
    promise = $timeout (->
      $http.get('/data/properties', {params: {term: n}}).success (rsp) -> $scope.properties = rsp
    ), 400

  $scope.page_changed = (n) ->
    $document.scrollToElement angular.element('#search')

  $scope.filters = ->
    {
      dropdownCssClass: 'filters'
      minimumResultsForSearch: 8
      data: [{id:'all',text:'Showing all'}]
      initSelection: (el, cb) ->
    }

]

app = angular.module('porter').controller('properties', PropertyHomeCtrl)
