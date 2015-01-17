PropertyHomeCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.filter = {id:'alphabetical',text:'Alphabetical'}
  $scope.sort = 'alphabetical'
  $scope.term = ''

  promise = null

  # search within title | address1 | city | zip
  $scope.$watch 'search', (n,o) -> if o
    $timeout.cancel promise
    promise = $timeout (->
      $scope.term = n
      refresh_properties()
    ), 400

  $scope.$watch 'filter', (n,o) -> if o
    $scope.sort = n.id
    refresh_properties()

  $scope.page_changed = (n) ->
    angular.element('body, html').animate
      scrollTop: 0
    , 'fast'
    return true

  $scope.filters = ->
    {
      dropdownCssClass: 'filters'
      minimumResultsForSearch: 8
      data: [{id:'alphabetical',text:'Alphabetical'},{id:'recently_added',text:'Recently Added'},{id:'upcoming_service',text:'Upcoming Service'}]
      initSelection: (el, cb) ->
    }

  refresh_properties = ->
    $http.get('/data/properties', {params: {term: $scope.term, sort: $scope.sort}}).success (rsp) -> $scope.user.properties = rsp

]

app = angular.module('porter').controller('properties', PropertyHomeCtrl)
