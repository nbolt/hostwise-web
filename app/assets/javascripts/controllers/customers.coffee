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
          user.upcoming_jobs += property.active_bookings.length
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

  $scope.is_new_customer = (user) ->
    services = 0
    _(user.properties).each (property) ->
      services += property.bookings.length
    services <= 5

  $scope.active_hosts = ->
    active = _($scope.users).filter (host) -> _(host.properties).find (property) -> property.active_bookings[0]
    active.length
  
  $scope.bookings_per_host = ->
    if $scope.users
      Math.round(_($scope.users).reduce(((acc, host) ->
        acc + _(host.properties).reduce(((acc, property) -> acc + property.active_bookings.length + property.past_bookings.length), 0)
      ), 0) / $scope.users.length * 100) / 100
    else
      0
  
  $scope.properties_per_host = ->
    if $scope.users
      Math.round(_($scope.users).reduce(((acc, host) ->
        acc + host.properties.length
      ), 0) / $scope.users.length * 100) / 100
    else
      0

  $scope.monthly_growth = ->
    users_last_month  = _($scope.users).filter (host) -> moment(host.created_at, 'YYYY-MM-DD') >= moment().subtract(1, 'months')
    users_last_month2 = _($scope.users).filter (host) -> moment(host.created_at, 'YYYY-MM-DD') >= moment().subtract(2, 'months') && moment(host.created_at, 'YYYY-MM-DD') <= moment().subtract(1, 'months')
    Math.round( ((users_last_month.length - users_last_month2.length) / users_last_month2.length * 100) * 100 ) / 100
  
  $scope.fetch_hosts()

]

app = angular.module('porter').controller('customers', CustomersCtrl)
