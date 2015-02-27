BookingModalCtrl = ['$scope', '$http', '$timeout', '$q', '$rootScope', 'ngDialog', ($scope, $http, $timeout, $q, $rootScope, ngDialog) ->

  last_payment = null
  $scope.days = []
  $scope.flashing = false
  $scope.selected_services = {cleaning:true,linens:true,toiletries:true} unless $scope.selected_services && $scope.selected_booking
  $scope.chosen_dates = {} unless $scope.chosen_dates
  $scope.payment = {}
  $scope.same_day_cancellation = false
  $scope.same_day_booking = ''
  $scope.next_day_booking = ''

  unless $scope.payment && $scope.payment.id
    if $scope.user.payments && $scope.user.payments[0]
      payment = $scope.user.payments[0]
      payment_type = if payment.card_type then payment.card_type.capitalize() else payment.bank_name.capitalize()
      $scope.payment.id = payment.id
      $scope.payment.text = "#{payment_type} ending in #{payment.last4}"
    else
      $scope.payment.id = 'new'
      $scope.payment.text = 'Add New Payment'

  payments_map = _($scope.user.payments).map (payment) ->
    payment_type = if payment.card_type then payment.card_type.capitalize() else payment.bank_name.capitalize()
    { id: payment.id, text: "#{payment_type} ending in #{payment.last4}" }
  payments_map.push { id: 'new', text: 'Add New Payment' }

  $scope.payment_screen = -> if $scope.payment && $scope.payment.id == 'new' then 'new' else 'existing'

  $scope.next = ->
    if !services_array()[0]
      flash 'failure', 'Please select at least one service'
    else
      angular.element('.booking.modal .content-container').css 'margin-left', margin_left()
      update_header 2
      $scope.calculate_pricing()
    null

  $scope.details = ->
    if angular.element('.content-side-container').css('margin-left') == '0px'
      if mobile()
        angular.element('.content-side-container').css 'margin-left', margin_left()
      else
        angular.element('.content-side-container').css 'margin-left', margin_left()/2
    else
      angular.element('.content-side-container').css 'margin-left', 0
    $scope.calculate_pricing()
    null

  $scope.change_dates = ->
    angular.element('.booking.modal .content-container').css 'margin-left', 0
    update_header 1
    null

  $scope.add_payment = (defer) ->
    if $scope.payment_method.id == 'credit-card'
      exp_date = angular.element(".payment-tab.credit-card input[data-stripe=expiry]").val()
      exp_month = exp_date.split("/")[0]
      exp_year = exp_date.split("/")[1]
      if exp_date is 'MM/YY'
        exp_month = ''
        exp_year =  ''
      Stripe.createToken
        number: angular.element(".payment-tab.credit-card input[data-stripe=number]").val()
        cvc: angular.element(".payment-tab.credit-card input[data-stripe=cvc]").val()
        exp_month: exp_month
        exp_year: exp_year
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
    defer = $q.defer()
    defer.promise.then((id) ->
      $http.post("/properties/#{$scope.property.slug}/book", {
        payment: id
        services: services_array()
        dates: $scope.chosen_dates
        late_next_day: $scope.next_day_booking
        late_same_day: $scope.same_day_booking
      }).success (rsp) ->
        if rsp.success
          $scope.to_booking_confirmation()
          null
        else
          flash 'failure', rsp.message
    )

    if $scope.payment.id == 'new'
      $scope.add_payment defer
    else
      defer.resolve $scope.payment.id

  $scope.load_pricing = ->
    $http.get('/cost').success (rsp) ->
      $scope.pricing = rsp

  $scope.calculate_pricing = ->
    $scope.total = 0
    $scope.days = []
    $http.post("/properties/#{$scope.property.slug}/booking_cost", {services: $scope.selected_services}).success (rsp) ->
      $scope.service_total = rsp.cost
      _($scope.chosen_dates).each (v,k) ->
        _(v).each (d) ->
          day = {}
          day.total = rsp.cost
          day.date  = moment("#{k}-#{d}", 'M-YYYY-D').format('MMM D, YYYY')
          if day.date == $scope.next_day_booking
            day.next_day_booking = $scope.pricing.late_next_day
            day.total += $scope.pricing.late_next_day
          if day.date == $scope.same_day_booking
            day.same_day_booking = $scope.pricing.late_same_day
            day.total += $scope.pricing.late_same_day
          $scope.total += day.total
          _($scope.selected_services).each (v,k) ->
            day[k] = rsp[k] if v
          $scope.days.push day

  $scope.to_booking_confirmation = ->
    angular.element('.booking.modal .content.confirmation').removeClass 'active'
    angular.element('.booking.modal .content.confirmation.teal').addClass 'active'
    angular.element('.booking.modal .content-container').css 'margin-left', margin_left()*2
    update_header 3
    null

  $scope.to_late_day_confirmation = (type) ->
    angular.element('.booking.modal .content.confirmation').removeClass 'active'
    angular.element(".booking.modal .content.confirmation.red.#{type}").addClass 'active'
    angular.element('.booking.modal .content-container').css 'margin-left', margin_left()*2
    angular.element('.booking.modal .header').addClass 'white white-transition'
    angular.element('.booking.modal .header .icon, .booking.modal .header .text').css 'opacity', 0

  $scope.cancel_late_day_booking = ->
    date = $scope.selected_date
    el = angular.element(".booking.modal .calendar td.active.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]")
    el.removeClass('chosen')
    key = "#{el.attr('month')}-#{el.attr('year')}"
    $scope.chosen_dates[key] = $scope.chosen_dates[key].filter (d) -> d != parseInt el.attr('day')
    $scope.to_booking_selection()

  $scope.confirm_next_day_booking = ->
    $scope.next_day_booking = $scope.selected_date.format('MMM D, YYYY')
    $scope.to_booking_selection()

  $scope.confirm_same_day_booking = ->
    $scope.same_day_booking = $scope.selected_date.format('MMM D, YYYY')
    $scope.to_booking_selection()

  $scope.to_booking_selection = ->
    angular.element('.booking.modal .content-container').css 'margin-left', 0
    angular.element('.booking.modal .header').removeClass 'white'
    $timeout((->angular.element('.booking.modal .header').removeClass 'white-transition'),600)
    angular.element('.booking.modal .header .icon, .booking.modal .header .text').css 'opacity', 1
    null

  $scope.to_booking_cancellation = ->
    $http.get("/properties/#{$scope.property.slug}/#{$scope.selected_booking}/same_day_cancellation").success (rsp) ->
      $scope.same_day_cancellation = rsp.same_day_cancellation
      angular.element('.booking.modal .content.confirmation').removeClass 'active'
      el = angular.element('.booking.modal .content.confirmation.red')
      el.addClass 'active'
      if $scope.same_day_cancellation
        el.find('.check-container.ok').hide()
        el.find('.check-container.cancellation').show()
      else
        el.find('.check-container.ok').show()
        el.find('.check-container.cancellation').hide()
      angular.element('.booking.modal .content-container').css 'margin-left', margin_left()
      angular.element('.booking.modal .header').addClass 'white white-transition'
      angular.element('.booking.modal .header .icon, .booking.modal .header .text').css 'opacity', 0
    null

  $scope.confirm_cancellation = ->
    $http.post("/properties/#{$scope.property.slug}/#{$scope.selected_booking}/cancel", {
      apply_fee: $scope.same_day_cancellation
    }).success (rsp) ->
      if rsp.success
        date = $scope.selected_date
        angular.element(".column.cal .calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").removeClass('booked').removeAttr 'booking'
        angular.element('.booking.modal .content-container').css 'margin-left', margin_left()*2

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
          angular.element('.booking.modal .content-container').css 'margin-left', margin_left()
          update_header 3
          null
        else
          flash 'failure', rsp.message
    )

    if $scope.payment.id == 'new'
      $scope.add_payment defer
    else
      defer.resolve $scope.payment.id

  mobile = ->
    angular.element('.booking.modal .content-container .content-group').width() <= 320

  margin_left = ->
    container_width = angular.element('.booking.modal .content-container .content-group').width()
    if container_width < 481
      -320
    else if container_width < 769
      -700
    else
      -976

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
      data: [{id:'credit-card', text:'Credit Card'}]
      initSelection: (el, cb) -> cb {id:'credit-card', text:'Credit Card'}
    }

  $rootScope.$on 'ngDialog.closing', (e, $dialog) ->
    if $dialog.find('.ngdialog-content .modal .content.confirmation').hasClass('active')
      $scope.$emit 'refresh_bookings'
      window.location = $scope.redirect_to if $scope.redirect_to

  services_array = ->
    services = []
    _($scope.selected_services).each (selected, service) ->
      services.push service if selected
    services

  update_header = (step) ->
    title = 'Select Date(s) & Services'
    switch step
      when 2
        title = 'Confirm Booking & Payment'
      when 3
        title = 'Booking Confirmed'
    angular.element('.booking.modal .header .text').text title

  $scope.included_services = -> _(services_array()).join(', ')

  $scope.calculate_pricing() unless $scope.selected_services && $scope.selected_booking

  $scope.$on 'calculate_pricing', -> $scope.calculate_pricing()

  $scope.load_pricing() unless $scope.pricing

  $scope.$on 'next_day_confirmation', -> $scope.to_late_day_confirmation 'next-day'
  $scope.$on 'same_day_confirmation', -> $scope.to_late_day_confirmation 'same-day'
]

app = angular.module('porter').controller('booking_modal', BookingModalCtrl)
