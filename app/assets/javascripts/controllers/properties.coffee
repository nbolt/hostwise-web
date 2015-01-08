PropertyHomeCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.filter = {id:'all',text:'Showing all'}

  $scope.filters = ->
    {
      dropdownCssClass: 'filters'
      minimumResultsForSearch: 8
      data: [{id:'all',text:'Showing all'}]
      initSelection: (el, cb) ->
    }

]

app = angular.module('porter').controller('properties', PropertyHomeCtrl)
