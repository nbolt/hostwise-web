AdminInventoryCtrl = ['$scope', '$http', '$timeout', 'spinner', ($scope, $http, $timeout, spinner) ->

  $scope.fetch_properties = ->
    spinner.startSpin()
    $http.get('/properties.json').success (rsp) ->
      $scope.properties = rsp
      $scope.total_linen_sets = _(rsp).reduce(((a, p) -> a + p.linen_count),0)
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

app = angular.module('porter').controller('admin_inventory', AdminInventoryCtrl)
