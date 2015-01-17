BookingModalCtrl = ['$scope', '$http', '$timeout', '$window', 'ngDialog', ($scope, $http, $timeout, $window, ngDialog) ->

  last_payment = null
  $scope.flashing = false
  $scope.selected_services = {cleaning:false,linens:false,restocking:false}

  if $scope.user.payments[0]
    $scope.payment = $scope.user.payments[0].id
  else
    $scope.payment = { id: 'new', text: 'Add New Payment' }

  payments_map = _($scope.user.payments).map (payment) ->
    payment_type = if payment.stripe_id then 'Card' else 'Bank'
    { id: payment.id, text: "#{payment_type} ending in #{payment.last4}" }
  payments_map.push { id: 'new', text: 'Add New Payment' }

  $scope.toPayment = ->
    angular.element('.booking.modal .content.side').removeClass 'active'
    angular.element('.booking.modal .content.side.payment').addClass 'active'
    angular.element('.booking.modal .content-container').css 'margin-left', -400
    null

  $scope.fromPayment = ->
    angular.element('.booking.modal .content > .payment .select2-container').select2 'val', $scope.payment.id || last_payment || payments_map[0].id
    angular.element('.booking.modal .content.main').addClass 'active'
    angular.element('.booking.modal .content-container').css 'margin-left', 0
    $timeout((->
      angular.element('.booking.modal .content.side').removeClass 'active'
      $scope.card = {}; $scope.bank = {}
    ),600)

  $scope.total = ->
    total = 0
    _($scope.selected_services).each (selected, service) ->
      total += 19 if selected
    total

  $scope.add_payment = ->
    if $scope.payment_method == 'credit-card'
      Stripe.createToken
        number: angular.element(".card-details input[data-stripe=number]").val()
        cvc: angular.element(".card-details input[data-stripe=cvc]").val()
        exp_month: angular.element(".card-details input[data-stripe=expiry]").val().split("/")[0]
        exp_year: angular.element(".card-details input[data-stripe=expiry]").val().split("/")[1]
      , (_, rsp) ->
        if rsp.error
          flash "failure", rsp.error.message
        else
          $http.post('/users/add_payment',{stripe_id:rsp.id,payment_method:$scope.payment_method}).success (rsp) ->
            if rsp.success
              angular.element('.booking.modal .content > .payment .select2-container')
                .select2 'data', payments_map.unshift({ id: rsp.payment.id, text: "Card ending in #{rsp.payment.last4}" })
                .select2 'val', rsp.payment.id
              $scope.$emit 'fetch_user'
              $scope.fromPayment()
            else
              flash 'failure', rsp.message
    else
      balanced.bankAccount.create $scope.bank, (rsp) ->
        if rsp.status_code != 201
          flash 'failure', rsp.errors[0].description
        else
          $http.post('/users/add_payment',{balanced_id:rsp.bank_accounts[0].id,payment_method:$scope.payment_method}).success (rsp) ->
            if rsp.success
              angular.element('.booking.modal .content > .payment .select2-container')
                .select2 'data', payments_map.unshift({ id: rsp.payment.id, text: "Bank ending in #{rsp.payment.last4}" })
                .select2 'val', rsp.payment.id
              $scope.$emit 'fetch_user'
              $scope.fromPayment()
          

  $scope.book = ->
    if $scope.payment.id == 'new'
      flash 'failure', 'Please add a payment method'
    else if !services_array()[0]
      flash 'failure', 'Please select at least one service'
    else
      $http.post($window.location.href + '/book', {
        payment: $scope.payment
        services: services_array()
        date: $scope.selected_date
      }).success (rsp) ->
        if rsp.success
          ngDialog.closeAll()
          date = $scope.selected_date.moment
          angular.element("#calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").addClass 'booked'


  flash = (type, msg) ->
    unless $scope.flashing
      $scope.flashing = true
      orig_msg = angular.element('.booking.modal .header .text').text()
      angular.element('.ngdialog-close').css 'opacity', 0
      angular.element('.booking.modal .header .text').css 'opacity', 0
      angular.element('.booking.modal .header').addClass type
      if msg.length > 37
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
          angular.element('.ngdialog-close').css 'opacity', 1
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

]

app = angular.module('porter').controller('booking_modal', BookingModalCtrl)