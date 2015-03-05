BookingModalCtrl = ['$scope', '$http', '$timeout', '$q', '$rootScope', 'ngDialog', ($scope, $http, $timeout, $q, $rootScope, ngDialog) ->

  last_payment = null
  $scope.days = []
  $scope.flashing = false
  $scope.selected_services = {} unless $scope.selected_booking
  $scope.chosen_dates = {} unless $scope.chosen_dates
  $scope.payment = {} unless $scope.payment
  $scope.same_day_cancellation = false
  $scope.same_day_booking = ''
  $scope.next_day_booking = ''
  $scope.booking = false
  $scope.refresh_booking = false

  unless $scope.selected_booking
    $http.get('/last_services').success (rsp) ->
      _(rsp).each (service) ->
        angular.element(".ngdialog .service.#{service.name} input").prop 'checked', true
        $scope.selected_services[service.name] = true
        $scope.calculate_pricing()

  $scope.payment_screen = (type) ->
    angular.element('.booking.modal .content.payment > div').hide()
    angular.element(".booking.modal .content.payment .#{type}-payment").show()
    null

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

  $scope.next = ->
    if !services_array()[0]
      flash 'failure', 'Please select at least one service'
    else if no_dates()
      flash 'failure', 'Please select at least one date'
    else
      if $scope.payment.id is 'new'
        $scope.payment_screen 'new'
      else
        $scope.payment_screen 'existing'
      $scope.slide 'step-two'
      $scope.calculate_pricing()
    null

  $scope.details = ->
    angular.element('.content-side-container .content-side').toggle()
    $scope.calculate_pricing()
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

  $scope.book = ->
    unless $scope.booking
      $scope.booking = true
      defer = $q.defer()
      defer.promise.then(((id) ->
        $http.post("/properties/#{$scope.property.slug}/book", {
          payment: id
          services: services_array()
          dates: $scope.chosen_dates
          late_next_day: $scope.next_day_booking
          late_same_day: $scope.same_day_booking
          spinner: true
        }).success (rsp) ->
          $scope.booking = false
          angular.element('#book').removeClass 'loading'
          if rsp.success
            $scope.to_booking_confirmation()
            $scope.$emit 'fetch_user'
            bookings = JSON.parse rsp.bookings
            _(bookings).each (booking) ->
              analytics.track('Booking', {
                booking_id: booking.id
                revenue: booking.cost
              })  
            null
          else
            flash 'failure', rsp.message
      ), ->
        $scope.booking = false
      )

      if $scope.payment.id == 'new'
        $scope.add_payment defer
      else
        defer.resolve $scope.payment.id

  $scope.load_pricing = ->
    $http.get('/cost').success (rsp) ->
      $scope.pricing = rsp

  $scope.calculate_pricing = ->
    first_booking_discount_applied = false
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
          if rsp.first_booking_discount && !first_booking_discount_applied
            if day.total >= $scope.pricing.first_booking_discount
              day.first_booking_discount = $scope.pricing.first_booking_discount
            else
              day.first_booking_discount = day.total
            day.total -= day.first_booking_discount
            first_booking_discount_applied = true
          $scope.total += day.total
          _($scope.selected_services).each (v,k) ->
            day[k] = rsp[k] if v
          $scope.days.push day

  $scope.slide = (type) ->
    angular.element('.booking.modal .content-container .content-group').css 'opacity', 0
    $timeout((->
      angular.element('.booking.modal .content-container .content-group').css 'display', 'none'
      angular.element(".booking.modal .content-container .content-group.#{type}").css 'display', 'block'
      $timeout((->angular.element(".booking.modal .content-container .content-group.#{type}").css 'opacity', 1),50)
    ), 400)
    $scope.refresh_booking = true if type is 'cancelled' or type is 'booked'
    null

  $scope.confirm_booking = -> ngDialog.closeAll()
  $scope.confirm_cancellation = -> ngDialog.closeAll()
  $scope.change_dates = -> $scope.slide 'step-one'
  $scope.to_booking_confirmation = -> $scope.slide 'booked'
  $scope.to_late_day_confirmation = (type) -> $scope.slide type
  $scope.to_staging_confirmation = -> $scope.slide 'staging'
  $scope.to_existing_booking = -> $scope.slide 'existing'

  $scope.to_booking_selection = ->
    if angular.element('.booking.modal .content-container').hasClass('exist')
      $scope.slide 'existing'
    else
      $scope.slide 'step-one'

  $scope.to_booking_cancellation = ->
    $http.get("/properties/#{$scope.property.slug}/#{$scope.selected_booking}/same_day_cancellation").success (rsp) ->
      $scope.same_day_cancellation = rsp.same_day_cancellation
      $scope.slide 'cancel'
      el = angular.element('.booking.modal .content-container .content-group.cancel')
      if $scope.same_day_cancellation
        el.find('.check-container.ok').hide()
        el.find('.check-container.cancellation').show()
      else
        el.find('.check-container.ok').show()
        el.find('.check-container.cancellation').hide()
    null

  $scope.cancel_late_day_booking = ->
    date = $scope.selected_date
    el = angular.element(".booking.modal .calendar td.active.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]")
    el.removeClass('chosen')
    key = "#{el.attr('month')}-#{el.attr('year')}"
    $scope.chosen_dates[key] = $scope.chosen_dates[key].filter (d) -> d != parseInt el.attr('day')
    $scope.to_booking_selection()

  $scope.cancel_staging = ->
    $scope.selected_services['cleaning'] = true
    $scope.selected_services['preset'] = false
    el = angular.element('.booking.modal .content .services .service.cleaning')
    el.find('input').prop 'checked', true
    el.addClass 'active'
    $scope.calculate_pricing()
    $scope.to_booking_selection()

  $scope.confirm_staging = ->
    $scope.selected_services['preset'] = true
    $scope.selected_services['linens'] = true
    $scope.selected_services['toiletries'] = true
    angular.element('.ngdialog .service.linens input, .ngdialog .service.toiletries input').prop 'checked', true
    $scope.calculate_pricing()
    $scope.to_booking_selection()

  $scope.confirm_next_day_booking = ->
    $scope.next_day_booking = $scope.selected_date.format('MMM D, YYYY')
    $scope.to_booking_selection()

  $scope.confirm_same_day_booking = ->
    $scope.same_day_booking = $scope.selected_date.format('MMM D, YYYY')
    $scope.to_booking_selection()

  $scope.confirm_cancellation = ->
    $http.post("/properties/#{$scope.property.slug}/#{$scope.selected_booking}/cancel", {
      apply_fee: $scope.same_day_cancellation
    }).success (rsp) ->
      if rsp.success
        date = $scope.selected_date
        angular.element(".column.cal .calendar td.active.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]").removeClass('booked').removeAttr 'booking'
        $scope.slide 'cancelled'

  $scope.update = ->
    defer = $q.defer()
    defer.promise.then((id) ->
      $http.post("/properties/#{$scope.property.slug}/#{$scope.selected_booking}/update", {
        payment: id
        services: services_array()
        spinner: true
      }).success (rsp) ->
        if rsp.success
          $scope.to_booking_confirmation()
        else
          flash 'failure', rsp.message
    )

    if $scope.payment.id == 'new'
      $scope.add_payment defer
    else
      defer.resolve $scope.payment.id

  flash = (type, msg) ->
    unless $scope.flashing
      $scope.flashing = true
      content_group_el = angular.element('.booking.modal .content-group').filter(':visible')
      header_el = content_group_el.find('.header')
      text_el = header_el.find('.text')
      orig_msg = text_el.text()
      #angular.element('.ngdialog-close').css 'opacity', 0
      text_el.css 'opacity', 0
      header_el.addClass type
      if msg.length > 80
        header_el.css 'height', 74
      $timeout((->
        text_el.text msg
        text_el.css 'opacity', 1
      ), 500)
      $timeout((->
        header_el.removeClass type
        text_el.css 'opacity', 0
        if msg.length > 37
          header_el.css 'height', 50
        $timeout((->
          text_el.text orig_msg
          text_el.css 'opacity', 1
          #angular.element('.ngdialog-close').css 'opacity', 1
          $scope.flashing = false
        ), 500)
      ), 4000)

  $scope.$watch 'payment', (n,o) -> if o
    angular.element('.booking.modal .content.payment > div').hide()
    if n.id == 'new'
      angular.element('.booking.modal .content.payment .new-payment').show()
    else
      last_payment = n.id
      angular.element('.booking.modal .content.payment .existing-payment').show()

  $scope.$watch 'payment_method', (n,o) -> if o
    angular.element('.booking.modal .content.payment .payment-tab').removeClass 'active'
    if n.id == 'credit-card'
      angular.element('.booking.modal .content.payment .payment-tab.credit-card').addClass 'active'
    else
      angular.element('.booking.modal .content.payment .payment-tab.ach').addClass 'active'

  $scope.$watch 'selected_services.linens', (n,o) ->
    if !n && $scope.selected_services['preset']
      $scope.selected_services['preset'] = false
      $scope.selected_services['cleaning'] = true
      angular.element('.ngdialog .service.cleaning input').prop 'checked', true

  $scope.$watch 'selected_services.preset', (n,o) ->
    if n
      angular.element('.ngdialog .service.cleaning .text').text 'Staging'
    else
      angular.element('.ngdialog .service.cleaning .text').text 'Cleaning'

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
    $scope.$emit 'refresh_bookings' if $scope.refresh_booking
    window.location = $scope.redirect_to if $scope.redirect_to

  services_array = ->
    services = []
    _($scope.selected_services).each (selected, service) ->
      services.push service if selected
    services

  no_dates = ->
    chosen = false
    _($scope.chosen_dates).each (v,k) ->
      chosen = true if v.length > 0
    !chosen

  $scope.included_services = -> _(services_array()).join(', ')

  $scope.load_pricing() unless $scope.pricing

  $scope.$on 'calculate_pricing', -> $scope.calculate_pricing()
  $scope.$on 'next_day_confirmation', -> $scope.to_late_day_confirmation 'next-day'
  $scope.$on 'same_day_confirmation', -> $scope.to_late_day_confirmation 'same-day'
  $scope.$on 'booking_selection', -> $scope.to_booking_selection()
  $scope.$on 'existing_booking', -> $scope.to_existing_booking()
]

app = angular.module('porter').controller('booking_modal', BookingModalCtrl)
