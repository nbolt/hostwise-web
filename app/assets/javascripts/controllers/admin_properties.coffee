AdminPropertiesCtrl = ['$scope', '$http', '$timeout', 'spinner', ($scope, $http, $timeout, spinner) ->

  $scope.fetch_properties = ->
    spinner.startSpin()
    $http.get('/properties.json').success (rsp) ->
      $scope.properties = rsp
      _($scope.properties).each (property) ->
        property.service_completed = _(property.bookings).filter((booking) -> booking.status_cd == 3).length
        property.revenue = _(property.bookings).reduce(((acc, booking) -> acc + booking.cost), 0)
      spinner.stopSpin()
      $timeout((->
        angular.element("#example-1").dataTable({
          aLengthMenu: [
            [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
          ]
        })
      ),1000)

  $scope.fetch_properties()

]

app = angular.module('porter').controller('admin_properties', AdminPropertiesCtrl)
