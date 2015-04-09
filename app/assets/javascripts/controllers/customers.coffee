CustomersCtrl = ['$scope', '$http', '$timeout', 'ngDialog', 'spinner', ($scope, $http, $timeout, ngDialog, spinner) ->

  $scope.fetch_hosts = ->
    spinner.startSpin()
    $http.get(window.location.href + '.json').success (rsp) ->
      $scope.users = rsp
      _($scope.users).each (user) ->
        user.upcoming_jobs = 0
        user.completed_jobs = 0
        user.total_spent = 0
        _(user.properties).each (property) ->
          user.upcoming_jobs += property.future_bookings.length
          user.completed_jobs += property.past_bookings.length
          if user.completed_jobs > 0
            _(property.past_bookings).each (booking) ->
              _(booking.successful_transactions).each (transaction) -> user.total_spent += transaction.amount/100
      spinner.stopSpin()
      $timeout((->
        angular.element("#example-1").dataTable({
          aLengthMenu: [
            [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
          ]
        })
      ),1000)

  
  $scope.fetch_hosts()

]

app = angular.module('porter').controller('customers', CustomersCtrl)
