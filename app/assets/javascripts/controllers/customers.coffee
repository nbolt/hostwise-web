CustomersCtrl = ['$scope', '$http', '$timeout', 'ngDialog', 'spinner', ($scope, $http, $timeout, ngDialog, spinner) ->

  $scope.fetch_hosts = ->
    spinner.startSpin()
    $http.get(window.location.href + '.json').success (rsp) ->
      $scope.users = rsp
      _($scope.users).each (user) ->
        user.upcoming_jobs = _(user.properties).reduce(((acc, property) -> acc + property.future_bookings.length), 0)
        user.completed_jobs = _(user.properties).reduce(((acc, property) -> acc + property.past_bookings.length), 0)
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
    if $scope.users
      count = 0
      _($scope.users).each (host) ->
        active_properties = 0
        _(host.properties).each (property) ->
          booking = property.active_bookings[property.active_bookings.length-1]
          active_properties += 1 if booking && moment(booking.date, 'YYYY-MM-DD') >= moment().subtract(1, 'weeks')
        count += 1 if active_properties >= 1
      return count
    else
      0

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
    Math.round((users_last_month.length - users_last_month2.length) / users_last_month2.length * 10000) / 100

  $scope.fetch_hosts()

]

app = angular.module('porter').controller('customers', CustomersCtrl)
