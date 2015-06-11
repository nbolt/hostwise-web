CustomersCtrl = ['$scope', '$http', '$timeout', 'ngDialog', 'spinner', ($scope, $http, $timeout, ngDialog, spinner) ->

  $scope.fetch_hosts = ->
    spinner.startSpin()
    $http.get(window.location.href + '.json').success (rsp) ->
      $scope.users = rsp.hosts
      spinner.stopSpin()
      $timeout((->
        angular.element("#example-1").dataTable({
          aLengthMenu: [
            [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
          ]
        })
      ),1000)

  $scope.monthly_growth = ->
    users_last_month  = _($scope.users).filter (host) -> moment(host.created_at, 'YYYY-MM-DD') >= moment().subtract(1, 'months')
    users_last_month2 = _($scope.users).filter (host) -> moment(host.created_at, 'YYYY-MM-DD') >= moment().subtract(2, 'months') && moment(host.created_at, 'YYYY-MM-DD') <= moment().subtract(1, 'months')
    Math.round((users_last_month.length - users_last_month2.length) / users_last_month2.length * 10000) / 100

  $scope.fetch_hosts()

]

app = angular.module('porter').controller('customers', CustomersCtrl)
