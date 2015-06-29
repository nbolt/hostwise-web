EditCustomerCtrl = ['$scope', '$http', '$timeout', 'ngDialog', 'spinner', ($scope, $http, $timeout, ngDialog, spinner) ->

  url = window.location.href.split('/')
  $scope.id = url[url.length-2]

  $http.get(window.location.href + '.json').success (rsp) -> $scope.host = rsp

  $scope.open_charge = -> ngDialog.open template: 'charge-modal', className: 'info full', scope: $scope

  $scope.charge = ->
    spinner.startSpin()
    $http.post("/hosts/#{$scope.host.id}/charge", { amount: $scope.amount, reason: $scope.reason }).success (rsp) ->
      if rsp.success
        $scope.amount = null
        $scope.reason = null
        ngDialog.closeAll()
        spinner.stopSpin()

  $scope.count_bookings = ->
    if $scope.host
      count = 0
      _.each $scope.host.properties, (property) ->
        _.each property.bookings, (booking) ->
          count += 1
      return count

  $scope.last_booking = ->
    if $scope.host
      bookings = []
      _.each $scope.host.properties, (property) ->
        _.each property.bookings, (booking) ->
          bookings.push(booking)
      bookings = _.sortBy  bookings, 'date'

      return bookings[bookings.length - 1]

  $scope.next_service_date = (property) ->
    if $scope.host
      return property.next_service_date

  $scope.update_account = ->
    $http.put("/hosts/#{$scope.id}/update", {
      host: $scope.host
    }).success (rsp) ->
      if rsp.success
        window.location = window.location.href
      else
        flash 'failure', rsp.message

  $scope.open_deactivation = ->
    $scope.current_name = "#{$scope.host.first_name}'s"
    ngDialog.open template: 'account-deactivation-modal', controller: 'edit-customer', className: 'warning', scope: $scope

  $scope.open_reactivation = ->
    $scope.current_name = "#{$scope.host.first_name}'s"
    ngDialog.open template: 'account-reactivation-modal', controller: 'edit-customer', className: 'warning', scope: $scope

  $scope.cancel_deactivation = ->
    ngDialog.closeAll()

  $scope.confirm_deactivation = ->
    $http.post("/hosts/#{$scope.id}/deactivate").success (rsp) ->
      window.location = window.location.href if rsp.success

  $scope.confirm_reactivation = ->
    $http.post("/hosts/#{$scope.id}/reactivate").success (rsp) ->
      window.location = window.location.href if rsp.success

  flash = (type, msg) ->
    el = angular.element('form .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    scroll 0
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

  scroll = (position) ->
    angular.element('body, html').animate
      scrollTop: position
    , 'fast'

]

app = angular.module('porter').controller('edit-customer', EditCustomerCtrl)
