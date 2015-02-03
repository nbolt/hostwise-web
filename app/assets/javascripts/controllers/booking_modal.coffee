BookingModalCtrl = ['$scope', '$http', '$timeout', '$q', '$window', 'ngDialog', ($scope, $http, $timeout, $q, $window, ngDialog) ->

  last_payment = null
  $scope.days = []
  $scope.flashing = false
  $scope.selected_services = {} unless $scope.selected_services
  $scope.chosen_dates = {} unless $scope.chosen_dates
  $scope.payment = {}

  unless $scope.payment && $scope.payment.id
    if $scope.user.payments && $scope.user.payments[0]
      payment = $scope.user.payments[0]
      payment_type = if payment.card_type then payment.card_type.capitalize() else 'Bank'
      $scope.payment.id = payment.id
      $scope.payment.text = "#{payment_type} ending in #{payment.last4}"
    else
      $scope.payment.id = 'new'
      $scope.payment.text = 'Add New Payment'

  payments_map = _($scope.user.payments).map (payment) ->
    payment_type = if payment.card_type then payment.card_type.capitalize() else 'Bank'
    { id: payment.id, text: "#{payment_type} ending in #{payment.last4}" }
  payments_map.push { id: 'new', text: 'Add New Payment' }

  $scope.payment_screen = -> if $scope.payment && $scope.payment.id == 'new' then 'new' else 'existing'

  $scope.next = ->
    angular.element('.booking.modal .content-container').css 'margin-left', -976
    calculate_pricing()
    null

  $scope.details = ->
    if angular.element('.content-side-container').css('margin-left') == '0px'
      angular.element('.content-side-container').css 'margin-left', -488
    else
      angular.element('.content-side-container').css 'margin-left', 0
    calculate_pricing()
    null

  $scope.change_dates = ->
    angular.element('.booking.modal .content-container').css 'margin-left', 0
    null

  $scope.setup = -> true

  $scope.total = ->
    total = 0
    _($scope.selected_services).each (selected, service) ->
      total += 19 if selected
    total

  $scope.add_payment = (defer) ->
    if $scope.payment_method.id == 'credit-card'
      Stripe.createToken
        number: angular.element(".payment-tab.credit-card input[data-stripe=number]").val()
        cvc: angular.element(".payment-tab.credit-card input[data-stripe=cvc]").val()
        exp_month: angular.element(".payment-tab.credit-card input[data-stripe=expiry]").val().split("/")[0]
        exp_year: angular.element(".payment-tab.credit-card input[data-stripe=expiry]").val().split("/")[1]
      , (_, rsp) ->
        if rsp.error
          flash "failure", rsp.error.message
        else
          $http.post('/payments/add',{stripe_id:rsp.id,payment_method:$scope.payment_method}).success (rsp) ->
            if rsp.success
              $scope.$emit 'fetch_user'
              defer.resolve rsp.payment.id if defer
            else
              flash 'failure', rsp.message
              defer.reject() if defer
    else
      balanced.bankAccount.create $scope.bank, (rsp) ->
        if rsp.status_code != 201
          flash 'failure', rsp.errors[0].description
          defer.reject() if defer
        else
          $http.post('/payments/add',{balanced_id:rsp.bank_accounts[0].id,payment_method:$scope.payment_method}).success (rsp) ->
            if rsp.success
              $scope.$emit 'fetch_user'
              defer.resolve rsp.payment.id if defer

  $scope.confirm_booking = -> ngDialog.closeAll()
  $scope.confirm_cancellation = -> ngDialog.closeAll()

  $scope.book = ->
    if !services_array()[0]
      flash 'failure', 'Please select at least one service'
    else
      defer = $q.defer()
      defer.promise.then((id) ->
        $http.post("/properties/#{$scope.property.slug}/book", {
          payment: id
          services: services_array()
          dates: $scope.chosen_dates
        }).success (rsp) ->
          if rsp.success
            $scope.$emit 'refresh_bookings'
            $scope.to_booking_confirmation()
            null
          else
            flash 'failure', rsp.message
      )

      if $scope.payment.id == 'new'
        $scope.add_payment defer
      else
        defer.resolve $scope.payment.id

  $scope.to_booking_confirmation = ->
    angular.element('.booking.modal .content.confirmation').removeClass 'active'
    angular.element('.booking.modal .content.confirmation.teal').addClass 'active'
    angular.element('.booking.modal .content-container').css 'margin-left', -1952
    angular.element('.booking.modal .header .icon, .booking.modal .header .text').css 'opacity', 0
    null

  $scope.to_booking_cancellation = ->
    angular.element('.booking.modal .content.confirmation').removeClass 'active'
    angular.element('.booking.modal .content.confirmation.red').addClass 'active'
    angular.element('.booking.modal .content-container').css 'margin-left', -976
    angular.element('.booking.modal .header').addClass 'red red-transition'
    angular.element('.booking.modal .header .icon, .booking.modal .header .text').css 'opacity', 0
    null

  $scope.cancel_cancellation = ->
    angular.element('.booking.modal .content-container').css 'margin-left', 0
    angular.element('.booking.modal .header').removeClass 'red'
    $timeout((->angular.element('.booking.modal .header').removeClass 'red-transition'),600)
    angular.element('.booking.modal .header .icon, .booking.modal .header .text').css 'opacity', 1
    null

  $scope.confirm_cancellation = ->
    $http.post("/properties/#{$scope.property.slug}/#{$scope.selected_booking}/cancel").success (rsp) ->
      if rsp.success
        date = $scope.selected_date
        angular.element(".column.cal .calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").removeClass('booked').removeAttr 'booking'
        angular.element('.booking.modal .content-container').css 'margin-left', -1952

  $scope.update = ->
    defer = $q.defer()
    defer.promise.then((id) ->
      $http.post("/properties/#{$scope.property.slug}/#{$scope.selected_booking}/update", {
        payment: id
        services: services_array()
      }).success (rsp) ->
        if rsp.success
          angular.element('.booking.modal .content.confirmation').removeClass 'active'
          angular.element('.booking.modal .content.confirmation.teal').addClass 'active'
          angular.element('.booking.modal .content-container').css 'margin-left', -976
          angular.element('.booking.modal .header .icon, .booking.modal .header .text').css 'opacity', 0
          null
        else
          flash 'failure', rsp.message
    )

    if $scope.payment.id == 'new'
      $scope.add_payment defer
    else
      defer.resolve $scope.payment.id

  calculate_pricing = ->
    $scope.days = []
    _($scope.chosen_dates).each (v,k) ->
      day = {}
      day.total = 129
      _($scope.selected_services).each (v,k) ->
        day[k] = 49 if v
      $scope.days.push day

  flash = (type, msg) ->
    unless $scope.flashing
      $scope.flashing = true
      orig_msg = angular.element('.booking.modal .header .text').text()
      #angular.element('.ngdialog-close').css 'opacity', 0
      angular.element('.booking.modal .header .text').css 'opacity', 0
      angular.element('.booking.modal .header').addClass type
      if msg.length > 80
        angular.element('.booking.modal .header').css 'height', 74
      $timeout((->
        angular.element('.booking.modal .header .text').text msg
        angular.element('.booking.modal .header .text').css 'opacity', 1
      ), 500)
      $timeout((->
        angular.element('.booking.modal .header').removeClass type
        angular.element('.booking.modal .header .text').css 'opacity', 0
        if msg.length > 37
          angular.element('.booking.modal .header').css 'height', 50
        $timeout((->
          angular.element('.booking.modal .header .text').text orig_msg
          angular.element('.booking.modal .header .text').css 'opacity', 1
          #angular.element('.ngdialog-close').css 'opacity', 1
          $scope.flashing = false
        ), 500)
      ), 4000)

  $scope.$watch 'payment', (n,o) -> if o
    if n.id == 'new'
      angular.element('.booking.modal .content  > .payment').addClass 'new'
    else
      last_payment = n.id
      angular.element('.booking.modal .content > .payment').removeClass 'new'

  $scope.$watch 'payment_method', (n,o) -> if o
    angular.element('.booking.modal .content.payment .payment-tab').removeClass 'active'
    if n.id == 'credit-card'
      angular.element('.booking.modal .content.payment .payment-tab.credit-card').addClass 'active'
    else
      angular.element('.booking.modal .content.payment .payment-tab.ach').addClass 'active'


  $scope.paymentHash = ->
    {
      dropdownCssClass: 'payment'
      minimumResultsForSearch: -1
      data: payments_map
      initSelection: (el, cb) -> cb(_(payments_map).find (p) -> p.id.toString() == el.val()) if el.val()
    }

  $scope.paymentMethodHash = ->
    {
      dropdownCssClass: 'payment'
      minimumResultsForSearch: -1
      data: [{id:'credit-card', text:'Credit Card'},{id:'ach', text: 'ACH Bank Transfer'}]
      initSelection: (el, cb) -> cb {id:'credit-card', text:'Credit Card'}
    }

  services_array = ->
    services = []
    _($scope.selected_services).each (selected, service) ->
      services.push service if selected
    services

  $scope.included_services = -> _(services_array()).join(', ')

]

app = angular.module('porter').controller('booking_modal', BookingModalCtrl)
