PropertyHomeCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.filter = {id:'all',text:'Showing all'}

  # search within title | address1 | city | zip
  $scope.search = (property) ->
      query = ($scope.query or '').toLowerCase()
      property.title.toLowerCase().indexOf(query) isnt -1 or
      property.address1.toLowerCase().indexOf(query) isnt -1 or
      property.city.toLowerCase().indexOf(query) isnt -1 or
      property.zip.indexOf(query) isnt -1

  $scope.filters = ->
    {
      dropdownCssClass: 'filters'
      minimumResultsForSearch: 8
      data: [{id:'all',text:'Showing all'}]
      initSelection: (el, cb) ->
    }

]

app = angular.module('porter').controller('properties', PropertyHomeCtrl)
