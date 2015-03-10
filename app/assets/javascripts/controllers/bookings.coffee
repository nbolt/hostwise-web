BookingsCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  promise = null
  $scope.sort = {id:'id',text:'ID'}
  $scope.filter = {id:'all',text:'All'}
  $scope.search = ''

  $scope.fetch_bookings = ->
    $http.get('/bookings.json',{params:{sort: $scope.sort.id,search: $scope.search,filter: $scope.filter.id}}).success (rsp) ->
      $scope.bookings = JSON.parse rsp.bookings
      $scope.today = rsp.today
      _($scope.bookings).each (booking) ->
        booking.created = moment(booking.created_at, 'YYYY-MM-DD').format('YYYY-MM-DD')
        booking.status = switch booking.status_cd
          when 0 then 'deleted'
          when 1 then 'scheduled'
          when 2 then 'cancelled'
          when 3 then 'completed'
          when 4 then 'scheduled'

  $scope.export = ->
    window.location = "/bookings.csv?sort=#{$scope.sort.id}&search=#{$scope.search}&filter=#{$scope.filter.id}"

  $scope.sortHash = ->
    {
      dropdownCssClass: 'sort'
      minimumResultsForSearch: -1
      data: [{id:'id',text:'ID'},{id:'date',text:'Date'}]
      initSelection: (el, cb) ->
    }

  $scope.filterHash = ->
    {
      dropdownCssClass: 'filter'
      minimumResultsForSearch: -1
      data: [{id:'all',text:'All'},{id:'active',text:'Active'},{id:'future',text:'Future'}]
      initSelection: (el, cb) ->
    }

  $scope.$watch 'sort.id', (n,o) -> $scope.fetch_bookings() if o
  $scope.$watch 'filter.id', (n,o) -> $scope.fetch_bookings() if o

  $scope.$watch 'search', (n,o) -> if o
    $timeout.cancel promise
    promise = $timeout (->
      $scope.search = n
      $scope.fetch_bookings()
    ), 400

  $scope.fetch_bookings()

]

app = angular.module('porter').controller('bookings', BookingsCtrl)
