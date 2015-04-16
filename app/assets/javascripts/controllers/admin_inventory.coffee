AdminInventoryCtrl = ['$scope', '$http', '$timeout', 'spinner', ($scope, $http, $timeout, spinner) ->

  $scope.fetch_distribution_centers = ->
    spinner.startSpin()
    $http.get('/inventory.json').success (rsp) ->
      $scope.fetch_distribution_centers = rsp
      spinner.stopSpin()
      $timeout((->
        angular.element("#example-1").dataTable({
          aLengthMenu: [
            [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
          ]
        })
      ),1000)

  $scope.fetch_distribution_centers()

]

app = angular.module('porter').controller('admin_inventory', AdminInventoryCtrl)
