BookingModalCtrl = ['$scope', '$http', '$timeout', '$window', '$q', '$rootScope', 'spinner', 'ngDialog', ($scope, $http, $timeout, $window, $q, $rootScope, spinner, ngDialog) ->

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
  $scope.show_back = false
  $scope.discount = 0
  $scope.linen_handling = null
  $scope.calculating = false
  $scope.slideQ = $q.defer()

  $scope.steps = [
    {
      name: 'services'
      display: 'Date & Services'
      visible: true
    },
    {
      name: 'linens'
      display: 'Linens & Towels'
      visible: true
    },
    {
      name: 'extras'
      display: 'Extra Options'
      visible: true
    },
    {
      name: 'time'
      display: 'Select a Time'
      visible: true
    },
    {
      name: 'pay'
      display: 'Finish & Pay'
      visible: true
    }
  ]

  $timeout((-> angular.element('.ngdialog-close').click(-> ngDialog.closeAll())), 1000)

  services_array = ->
    services = []
    _($scope.selected_services).each (selected, service) ->
      services.push service if selected
    services

  if $scope.selected_booking
    booking = _($scope.property.active_bookings).find (booking) -> booking.id == parseInt($scope.selected_booking)
    $scope.linen_handling = booking.linen_handling_cd
    $scope.extra = {king_sets: booking.extra_king_sets, twin_sets: booking.extra_twin_sets, toiletry_sets: booking.extra_toiletry_sets, instructions: booking.extra_instructions}
    linen_handling =
      switch booking.linen_handling_cd
        when 0 then 'purchase'
        when 1 then 'rental'
        when 2 then 'in-unit'
    $timeout((->
      angular.element(".step-linens .box.#{linen_handling}").addClass 'selected'
      if booking.timeslot_type_cd == 0
        $scope.chosen_time = 'flex'
        angular.element(".step-three .box.flex").addClass 'chosen'
      else
        time = booking.timeslot
        $scope.chosen_time = time
        angular.element(".step-three .box.premium").addClass 'chosen'
        if time < 12 then meridian = 'a' else meridian = 'p'
        time1 = time - 1; time1 -= 12 if time1 > 12
        time2 = time;     time2 -= 12 if time2 > 12
        $scope.booking.display_timeslot_1 = time1
        $scope.booking.display_timeslot_2 = time2
        $scope.booking.formatted_date = moment($scope.booking.date).format 'MMMM D, YYYY'
        $scope.calculate_pricing()
        $timeout((->angular.element('.timeboxes .box.premium .text').text "#{time1} - #{time2}#{meridian}m - $#{$scope.time_total($scope.chosen_time)}"),500)
    ),1000)
    $scope.booking = booking
    $timeout((->
      unless _(services_array()).find((service) -> service == 'linens')
        _($scope.steps).find((step) -> step.name == 'linens').visible = false
    ), 500)
  else
    $scope.extra = {king_sets: 0, twin_sets: 0, toiletry_sets: 0}
    if $scope.property && $scope.property.linen_handling_cd == 0
      $scope.linen_handling = 0
      $timeout((-> angular.element(".step-linens .box.purchase").addClass 'selected'), 1000)

  unless $scope.selected_booking
    $http.get("/properties/#{$scope.property.slug}/last_services").success (rsp) ->
      _(rsp.services).each (service) ->
        angular.element(".ngdialog .service.#{service.name} input").prop 'checked', true
        $scope.selected_services[service.name] = true
        $scope.calculate_pricing()
      unless _(services_array()).find((service) -> service == 'linens')
        _($scope.steps).find((step) -> step.name == 'linens').visible = false

  $http.get('/data/timeslots').success (rsp) -> $scope.timeslots = rsp.timeslots

  $scope.service_text = (display) ->
    if display == 'Linens & Towels'
      switch $scope.linen_handling
        when 0
          'Launder & Press'
        when 1
          'Linens & Towels &mdash; Rental'
        when 2
          'Linens & Towels'
    else
      display

  $scope.steps_class = -> if _($scope.steps).filter((step) -> step.visible).length == 4 then 'four' else 'five'

  $scope.step_class = (step, name, index) ->
    if $scope.steps
      if name
        name = _($scope.steps).find (step) -> step.name == name
        if name
          if step.visible
            if index < _($scope.steps).indexOf name
              'complete'
            else if index == _($scope.steps).indexOf name
              'current'
            else
              ''
          else
            'hidden'
        else
          ''
      else
        'complete'
    else
      ''

  $scope.step_num = (step) ->
    if _($scope.steps).find((step) -> step.name == 'linens').visible
      _($scope.steps).indexOf(step) + 1
    else
      index = _($scope.steps).indexOf(step)
      if index == 0
        1
      else
        index

  $scope.format_chosen_time = ->
    time = parseInt $scope.chosen_time
    if time < 12 then meridian = 'a' else meridian = 'p'
    time1 = time - 1; time1 -= 12 if time1 > 12
    time2 = time;     time2 -= 12 if time2 > 12
    "#{time1} - #{time2} #{meridian}m"

  $scope.time_total = (time) ->
    if $scope.timeslots
      if $scope.flex_service_total() == 0
        0
      else
        total = $scope.flex_service_total() - $scope.cleaning_cost
        switch time
          when 9  then total += $scope.cleaning_cost * $scope.timeslots[9]
          when 10 then total += $scope.cleaning_cost * $scope.timeslots[10]
          when 11 then total += $scope.cleaning_cost * $scope.timeslots[11]
          when 12 then total += $scope.cleaning_cost * $scope.timeslots[12]
          when 13 then total += $scope.cleaning_cost * $scope.timeslots[13]
          when 14 then total += $scope.cleaning_cost * $scope.timeslots[14]
          when 15 then total += $scope.cleaning_cost * $scope.timeslots[15]
          when 16 then total += $scope.cleaning_cost * $scope.timeslots[16]
          when 17 then total += $scope.cleaning_cost * $scope.timeslots[17]
          when 18 then total += $scope.cleaning_cost * $scope.timeslots[18]
        Math.round(total * 100) / 100

  $scope.choose_flex = ->
    $scope.chosen_time = 'flex'
    $scope.calculate_pricing()
    angular.element('.timeboxes .box').removeClass 'chosen'
    angular.element('.timeboxes .box.flex').addClass 'chosen'
    angular.element('.timeboxes .box.premium .text').html 'Choose your time<i class="icon-acc-open" />'
    null

  $scope.learn_purchase = ->
    $scope.slide 'learn-purchase'
    angular.element('.ngdialog-close').hide()
    null

  $scope.dismiss_purchase = ->
    $scope.slide 'step-linens'
    $timeout((-> angular.element('.ngdialog-close').show()), 200)
    null

  $scope.select_handling = (num, name) ->
    $scope.linen_handling = num
    if num == 0 then $scope.linen_handling_chosen = true else $scope.linen_handling_chosen = false
    $scope.calculate_pricing()
    angular.element('.linen-boxes .box').removeClass 'selected'
    angular.element(".linen-boxes .box.#{name}").addClass 'selected'
    null

  $scope.choose_time_modal = ->
    angular.element('.timeboxes .times').fadeIn()
    $timeout((->
      angular.element('.ngdialog.booking').on('click', ->
        angular.element('.timeboxes .times').fadeOut()
        angular.element('.ngdialog.booking').off('click')
      )
    ), 500)
    null

  $scope.choose_time = (time) ->
    $scope.chosen_time = time
    $scope.calculate_pricing()
    angular.element('.timeboxes .times').fadeOut()
    angular.element('.timeboxes .box').removeClass 'chosen'
    angular.element('.timeboxes .box.premium').addClass 'chosen'
    if time < 12 then meridian = 'a' else meridian = 'p'
    time1 = time - 1; time1 -= 12 if time1 > 12
    time2 = time;     time2 -= 12 if time2 > 12
    angular.element('.timeboxes .box.premium .text').text "#{time1} - #{time2}#{meridian}m - $#{$scope.time_total($scope.chosen_time)}"
    null

  $scope.payment_screen = (type) ->
    angular.element('.booking.modal .content.payment > div').hide()
    angular.element(".booking.modal .content.payment .#{type}-payment").show()
    null

  unless $scope.payment && $scope.payment.id
    if $scope.user.payments && $scope.user.payments[0]
      payment = _($scope.user.payments).find (payment) -> payment.primary
      payment_type = if payment.card_type then payment.card_type.capitalize() else payment.bank_name.capitalize()
      $scope.payment_id = payment.id
    else
      $scope.payment.id = 'new'
      $scope.payment.text = 'Add New Payment'

  payments_map = _($scope.user.payments).map (payment) ->
    payment_type = if payment.card_type then payment.card_type.capitalize() else payment.bank_name.capitalize()
    { id: payment.id, text: "#{payment_type} ending in #{payment.last4}" }
  payments_map.push { id: 'new', text: 'Add New Payment' }

  $scope.next = ->
    if !services_array()[0]
      $scope.flash 'failure', 'Please select at least one service'
    else if no_dates()
      $scope.flash 'failure', 'Please select at least one date'
    else
      $scope.calculate_pricing()
      if _(services_array()).find((service) -> service == 'linens')
        $scope.slide 'step-linens'
        $timeout((-> _($scope.steps).find((service) -> service.name == 'linens').visible = true),300)
      else
        $scope.slide 'step-additional'
        $timeout((-> _($scope.steps).find((service) -> service.name == 'linens').visible = false),300)
    null

  $scope.select_time = -> $scope.slide 'step-three'

  $scope.select_extras = ->
    if $scope.linen_handling != null || $scope.property.linen_handling_cd == 0
      $scope.slide 'step-additional'
    else
      $scope.flash 'failure', 'Please select a linens & towels option'

  $scope.select_payment = ->
    if $scope.chosen_time
      if $scope.payment.id is 'new'
        $scope.payment_screen 'new'
      else
        $scope.payment_screen 'existing'
      $scope.slide 'step-four'
      $scope.calculate_pricing()
    else
      $scope.flash 'failure', 'Please select a service time'

  $scope.back = ->
    angular.element('.content.side').hide()
    angular.element('.content.side.edit').css 'display', 'inline-block'
    $scope.show_back = false

  $scope.change_payment = ->
    angular.element('.content.side').hide()
    angular.element('.content.side.payment').css 'display', 'inline-block'
    $scope.show_back = true

  $scope.edit_extras = ->
    angular.element('.content.side').hide()
    angular.element('.content.side.extras').css 'display', 'inline-block'
    $scope.show_back = true

  $scope.change_time = ->
    angular.element('.content.side').hide()
    angular.element('.content.side.time').css 'display', 'inline-block'
    $scope.show_back = true

  $scope.edit_services = ->
    angular.element('.content.side').hide()
    angular.element('.content.side.services').css 'display', 'inline-block'
    $scope.show_back = true

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
          $scope.flash "failure", rsp.error.message
          defer.reject() if defer
        else
          $http.post('/payments/add',{stripe_id:rsp.id,payment_method:$scope.payment_method}).success (rsp) ->
            if rsp.success
              $scope.$emit 'fetch_user'
              defer.resolve rsp.payment.id if defer
            else
              $scope.flash 'failure', rsp.message
              defer.reject() if defer

  $scope.book = ->
    unless $scope.booking
      $scope.booking = true
      spinner.startSpin()
      defer = $q.defer()
      defer.promise.then(((id) ->
        $http.post("/properties/#{$scope.property.slug}/book", {
          payment: id
          services: services_array()
          extra_king_sets: $scope.extra.king_sets
          extra_twin_sets: $scope.extra.twin_sets
          extra_toiletry_sets: $scope.extra.toiletry_sets
          extra_instructions: $scope.extra.instructions
          dates: $scope.chosen_dates
          late_next_day: $scope.next_day_booking
          late_same_day: $scope.same_day_booking
          coupon_id: $scope.coupon_id
          timeslot: $scope.chosen_time
          handling: $scope.linen_handling
        }).success (rsp) ->
          $scope.booking = false
          spinner.stopSpin()
          angular.element('#book').removeClass 'loading'
          if rsp.success
            $scope.to_booking_confirmation()
            $scope.$emit 'refresh_properties'
            bookings = JSON.parse rsp.bookings
            _(bookings).each (booking) ->
              analytics.track('Made a Booking', {
                booking_id: booking.id
                revenue: booking.cost
              })
            null
          else
            $scope.flash 'failure', rsp.message
      ), ->
        $scope.booking = false
        spinner.stopSpin()
      )

      if $scope.payment.id == 'new'
        $scope.add_payment defer
      else
        defer.resolve $scope.payment.id

  $scope.abs = (num) -> Math.abs num

  $scope.load_pricing = -> $http.get('/cost').success (rsp) -> $scope.pricing = rsp; $scope.slideQ.resolve()

  $scope.flex_service_total = -> $scope.service_total + $scope.first_booking_discount_cost - ($scope.timeslot_cost || 0) - ($scope.linen_handling_chosen && 299 * $scope.property.beds || 0)

  $scope.calculate_pricing = ->
    if $scope.pricing && !$scope.calculating
      first_booking_discount_applied = false
      linen_handling_applied = false
      service_total = -1
      $scope.total = 0
      $scope.days = []
      remaining = $scope.remaining
      $scope.calculating = true
      $scope.slideQ = $q.defer()
      $http.post("/properties/#{$scope.property.slug}/booking_cost", {services: $scope.selected_services, handling: $scope.linen_handling, timeslot: $scope.chosen_time, coupon_id: $scope.coupon_id, extra_king_sets: $scope.extra.king_sets, extra_twin_sets: $scope.extra.twin_sets, extra_toiletry_sets: $scope.extra.toiletry_sets, booking: $scope.selected_booking, dates: $scope.chosen_dates}).success (rsp) ->
        $scope.calculating = false
        $scope.slideQ.resolve()
        $scope.timeslot_cost = rsp.timeslot_cost
        $scope.cleaning_cost = rsp.orig_service_cost
        cancellation_cost = rsp.cost - (rsp.linens || 0) - (rsp.toiletries || 0)
        cancellation_cost = 0 if cancellation_cost < 0
        twenty_percent = +(cancellation_cost * 0.2).toFixed(2)
        $scope.pricing.cancellation = twenty_percent if twenty_percent > $scope.pricing.cancellation
        _($scope.chosen_dates).each (v,k) ->
          _(v).each (d) ->
            day = {}
            day.total = rsp.cost
            day.date  = moment("#{k}-#{d}", 'M-YYYY-D').format('MMM D, YYYY')
            day.timeslot_cost = rsp.timeslot_cost
            $scope.next_day_booking = day.date if rsp.late_next_day
            $scope.same_day_booking = day.date if rsp.late_same_day
            if day.date == $scope.next_day_booking
              day.next_day_booking = $scope.pricing.late_next_day
              day.total += $scope.pricing.late_next_day unless rsp.late_next_day
            if day.date == $scope.same_day_booking
              day.same_day_booking = $scope.pricing.late_same_day
              day.total += $scope.pricing.late_same_day unless rsp.late_same_day
            if $scope.linen_handling_chosen && !linen_handling_applied
              day.linen_handling_cost = 299 * $scope.property.beds
              day.total += day.linen_handling_cost
              linen_handling_applied = true
            if rsp.first_booking_discount_cost && !first_booking_discount_applied
              day.first_booking_discount = rsp.first_booking_discount_cost
              day.total -= day.first_booking_discount
              first_booking_discount_applied = true
            if rsp.first_booking_discount
              day.first_booking_discount = rsp.first_booking_discount
            if rsp.overage_cost
              day.overage = true
              day.overage_cost = rsp.overage_cost
            if rsp.discounted_cost
              day.discounted = true
              day.discounted_cost = rsp.discounted_cost
            if rsp.extra_king_sets
              day.extra_king_sets = rsp.extra_king_sets
            if rsp.extra_twin_sets
              day.extra_twin_sets = rsp.extra_twin_sets
            if rsp.extra_toiletry_sets
              day.extra_toiletry_sets = rsp.extra_toiletry_sets
            if (remaining == -1 || remaining > 0) && _(rsp.valid_dates).find((str) -> str == moment("#{k}-#{d}", 'M-YYYY-D').format('YYYY-MM-DD')) && !$scope.selected_booking
              remaining -= 1 if remaining > 0
              day.discount = rsp.coupon_cost / 100
              day.total -= day.discount
            day.total = parseFloat day.total.toFixed(2)
            $scope.total += day.total
            if day.total > service_total
              service_total = day.total
              $scope.first_booking_discount_cost = day.first_booking_discount || 0
            _($scope.selected_services).each (v,k) ->
              if v
                if (k is 'cleaning' or k is 'preset') and day.timeslot_cost
                  day[k] = rsp[k] + day.timeslot_cost
                else
                  day[k] = rsp[k]
            $scope.days.push day
        $scope.service_total = service_total
        $scope.total = 0 if $scope.total < 0

  $scope.slide = (type) ->
    $scope.slideQ.promise.then ->
      angular.element('.booking.modal .content-container .content-group').css 'opacity', 0
      $timeout((->
        angular.element('.booking.modal .content-container .content-group').css 'display', 'none'
        angular.element(".booking.modal .content-container .content-group.#{type}").css 'display', 'block'
        $timeout((->angular.element(".booking.modal .content-container .content-group.#{type}").css 'opacity', 1),50)
        if ($($window).width() <= 480)
          if (type == 'step-linens')
            owl = angular.element('.linen-boxes').owlCarousel({items: 1, loop: true, dots: false, smartSpeed: 500})
            angular.element('.linen-boxes').prepend("<div class='nav'> <div class='next'><div class='icon'><i class='icon-job-start'/></div></div> <div class='prev'><div class='icon'><i class='icon-job-start'/></div></div> </div>")
            angular.element('.linen-boxes .next').click -> owl.trigger('next.owl.carousel')
            angular.element('.linen-boxes .prev').click -> owl.trigger('prev.owl.carousel')
          if type != 'step-four' && (angular.element(".booking.modal .content-container .content-group.#{type}").outerHeight() < $($window).height())
            angular.element(".booking.modal .content-container .content-group.#{type} .content").css 'min-height', $($window).height() - 102
      ), 400)
      $scope.refresh_booking = true if type is 'cancelled' or type is 'booked'
      null

  $scope.prev = ->
    last_complete = angular.element('.step.complete:visible:last')
    if last_complete.hasClass('extras')
      if _($scope.steps).find((step) -> step.name == 'linens').visible
        $scope.slide 'step-linens'
      else
        $scope.slide 'step-one'
    else
      $scope.slide last_complete.attr 'prev'

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
    spinner.startSpin()
    defer = $q.defer()
    defer.promise.then(((id) ->
      $http.post("/properties/#{$scope.property.slug}/#{$scope.selected_booking}/update", {
        payment: id
        services: services_array()
        coupon_id: $scope.coupon_id
        extra_king_sets: $scope.extra.king_sets
        extra_twin_sets: $scope.extra.twin_sets
        extra_toiletry_sets: $scope.extra.toiletry_sets
        extra_instructions: $scope.extra.instructions
        timeslot: $scope.chosen_time
        handling: $scope.linen_handling
      }).success (rsp) ->
        spinner.stopSpin()
        if rsp.success
          $scope.to_booking_confirmation()
        else
          $scope.flash 'failure', rsp.message
    ),(-> spinner.stopSpin()))

    if $scope.payment.id == 'new'
      $scope.add_payment defer
    else
      defer.resolve $scope.payment.id

  $scope.flash = (type, msg) ->
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

  $scope.$watch 'discount_code', (n,o) -> if o != undefined && n != o
    $http.post("/bookings/apply_discount", {code: n, total: $scope.total, property_id: $scope.property.id, dates: $scope.chosen_dates}).success (rsp) ->
      if rsp.success
        angular.element('#discount-code input').attr('disabled', true)
        angular.element('#discount-code').addClass 'applied'
        angular.element('#discount-text').text "#{rsp.display_amount} Discount Applied"
        $scope.discount = rsp.amount
        $scope.remaining = rsp.remaining
        $scope.coupon_id = rsp.coupon_id
        $scope.calculate_pricing()

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
    if !n && o
      $scope.linen_handling = null
      angular.element('.linen-boxes .box').removeClass 'selected'
      if $scope.selected_services['preset']
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
