PropertyCtrl = ['$scope', '$http', '$window', '$timeout', '$interval', '$upload', '$rootScope', 'spinner', 'ngDialog', ($scope, $http, $window, $timeout, $interval, $upload, $rootScope, spinner, ngDialog) ->

  $scope.form = {}
  $scope.chosen_dates = {}
  $scope.payment = {}
  $scope.selected_services = {}
  $scope.selected_date = null
  $scope.current_zip = null
  $scope.current_address1 = null
  promises = {}

  $scope.$on 'refresh_property', -> $http.get($window.location.href + '.json').success (rsp) ->
    $scope.property = rsp
    $scope.form = _(rsp).clone()
    load_bookings(rsp)

  $http.get($window.location.href.split('?')[0] + '.json').success (rsp) ->
    $scope.property = rsp
    $scope.form = _(rsp).clone()
    load_bookings(rsp)

    load_mapbox = null
    load_mapbox = $interval((->
      if $window.loaded_mapbox
        $interval.cancel(load_mapbox)
        unless $scope.map
          $scope.map = L.mapbox.map('map', 'useporter.l02en9o9',
            dragging: false
            touchZoom: false
            scrollWheelZoom: false
            doubleClickZoom: false
            attributionControl: false)
          $scope.markers = new L.LayerGroup().addTo($scope.map)
          $scope.geocoder = L.mapbox.geocoder 'mapbox.places'
          refresh_map()
    ), 200)

    $scope.form.bedrooms = { id: rsp.bedrooms.toString(), text: rsp.bedrooms.toString() }
    $scope.form.bathrooms = { id: rsp.bathrooms.toString(), text: rsp.bathrooms.toString() }
    $scope.form.twin_beds = { id: rsp.twin_beds.toString(), text: rsp.twin_beds.toString() }
    $scope.form.full_beds = { id: rsp.full_beds.toString(), text: rsp.full_beds.toString() }
    $scope.form.queen_beds = { id: rsp.queen_beds.toString(), text: rsp.queen_beds.toString() }
    $scope.form.king_beds = { id: rsp.king_beds.toString(), text: rsp.king_beds.toString() }
    $scope.current_zip = $scope.form.zip
    $scope.current_address1 = $scope.form.address1
    $scope.property_image($scope.property.primary_photo)

  $scope.modal_calendar_options =
    {
      selectable: true
      clickable: true
      disable_past: true
      onchange: () ->
        if $scope.property
          _($scope.property.active_bookings).each (booking) ->
            date = moment.utc(booking.date)
            if $('.booking.modal')[0]
              angular.element(".booking.modal .calendar td.active.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive booked').attr('booking', booking.id)
            else
              $timeout((->
                angular.element(".booking.modal .calendar td.active.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive').attr('booking', booking.id)
              ),100)

      onclick: ($this) ->
        return if $this.hasClass('chosen')
        $scope.selected_date = moment "#{$this.attr 'year'} #{$this.attr 'day'} #{parseInt($this.attr 'month')}", 'YYYY D MM'
        days_diff = $scope.selected_date.diff(moment().startOf('day'), 'days')
        hour = moment().hours()
        minute = moment().minutes()
        if days_diff == 0 and hour <= 14 and minute <= 59 # same day booking before 3pm
          $scope.$broadcast 'same_day_confirmation'
        else if days_diff == 1 and hour >= 22 # next day booking after 10pm
          $scope.$broadcast 'next_day_confirmation'
    }

  $scope.quick_add = (property) ->
    ngDialog.open template: 'booking-modal', className: 'booking', scope: $scope, closeByDocument: false
    $scope.property = property
    $scope.chosen_dates = {}

    $timeout((->
      angular.element('.booking.modal .content.side').removeClass 'active'
      angular.element('.booking.modal .content.side.calendar').addClass 'active'
      $scope.$broadcast 'booking_selection'
    ),500)

    $http.get("/properties/#{property.slug}.json").success (rsp) ->
      $scope.property = rsp
      _($scope.property.active_bookings).each (booking) ->
        date = moment.utc booking.date
        booking.parsed_date = date.format('MMMM Do, YYYY')
        angular.element(".booking.modal .calendar td.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive').addClass('booked').attr('booking', booking.id)

  $scope.calendar_options =
    {
      selectable: true
      clickable: false
      selected_class: 'booked'
      disable_past: true
      onchange: ->
        if $scope.property
          _($scope.property.active_bookings).each (booking) ->
            date = moment.utc(booking.date)
            angular.element(".column.cal .calendar td.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]").addClass('booked').attr('booking', booking.id)
          _($scope.property.past_bookings).each (booking) ->
            date = moment.utc(booking.date)
            angular.element(".column.cal .calendar td.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]").addClass('booked').attr('booking', booking.id)

      onclick: ($this) -> edit_booking($this)
    }

  $scope.update_details = ->
    if _(angular.element('.bed-types').find('input')).filter((el) -> parseInt(angular.element(el).val()) > 0).length is 0
      flash 'failure', 'Please select at least one bed', true
      return
    $scope.update_property()

  $scope.update_property = ->
    post_url = "/properties/#{$scope.property.slug}/update"
    spinner.startSpin()
    if $scope.files && $scope.files[0]
      $upload.upload(
        url: post_url
        file: $scope.files[0]
        fields:
          form: $scope.form
      ).success (rsp) ->
        spinner.stopSpin()
        if typeof rsp.success == 'undefined'
          $window.location = $window.location.href
        else
          flash 'failure', rsp.message, true
    else
      $http.post(post_url, {form: $scope.form}).success (rsp) ->
        spinner.stopSpin()
        if typeof rsp.success == 'undefined'
          $scope.$emit 'refresh_property'
          ngDialog.closeAll()
        else
          flash 'failure', rsp.message, true

  $scope.$watch 'files', ->
    if $scope.files && $scope.files[0]
      spinner.startSpin()
      $upload.upload(
        url: '/properties/upload'
        file: $scope.files[0]
      ).success (rsp) ->
        spinner.stopSpin()
        if rsp.success
          angular.element('.preview').attr('src', rsp.image)
        else
          flash 'failure', rsp.message, true

  $scope.edit_booking = (booking) ->
    if booking
      $this = {}
      $this.attr = (attr) ->
        switch attr
          when 'day'
            parseInt moment(booking.date, 'YYYY-MM-DD').format('MM/DD/YY').split('/')[1]
          when 'month'
            parseInt moment(booking.date, 'YYYY-MM-DD').format('MM/DD/YY').split('/')[0]
          when 'year'
            '20' + moment(booking.date, 'YYYY-MM-DD').format('MM/DD/YY').split('/')[2]
          when 'booking'
            booking.id

      edit_booking $this
    else
      day   = parseInt $scope.property.next_service_date.split('/')[1]
      month = parseInt $scope.property.next_service_date.split('/')[0]
      year  = '20' + $scope.property.next_service_date.split('/')[2]
      edit_booking angular.element(".column.cal .calendar td.active.day[month=#{month}][year=#{year}][day=#{day}]")

  edit_booking = ($this) ->
    ngDialog.open template: 'booking-modal', className: 'booking', scope: $scope, closeByDocument: false
    date = moment "#{$this.attr 'year'} #{$this.attr 'day'} #{parseInt($this.attr 'month')}", 'YYYY D MM'
    $scope.selected_date = date
    $scope.selected_date_confirmation = date.format('ddd, MMM D')
    $scope.selected_date_booking = date.format('MMM D, YYYY')
    $scope.chosen_dates = {}
    $scope.chosen_dates["#{date.month()+1}-#{date.year()}"] = [date.date()]
    $scope.modal_calendar_options.init_month = date.month() + 1
    $scope.modal_calendar_options.init_year  = date.year()
    $scope.selected_services = {}
    $scope.selected_booking = $this.attr 'booking'
    if $scope.selected_booking
      $http.get("#{$window.location.href}/#{$scope.selected_booking}/show").success (rsp) ->
        payment_type = if rsp.payment.stripe_id then 'Card' else 'Bank'
        $scope.payment.id = rsp.payment.id
        $scope.payment.text = "#{payment_type} ending in #{rsp.payment.last4}"
        $scope.extra = {king_sets: rsp.extra_king_sets, twin_sets: rsp.extra_twin_sets, toiletry_sets: rsp.extra_toiletry_sets}
        _(rsp.services).each (service) ->
          $scope.selected_services[service.name] = true
          angular.element(".booking.modal .services .service.#{service.name}, .booking.modal .extra .service.#{service.name}").addClass 'active'
          angular.element(".booking.modal .services .service.#{service.name} input, .booking.modal .extra .service.#{service.name} input").attr 'checked', true
        $scope.$broadcast 'calculate_pricing'
        $timeout((->$scope.$broadcast 'booking_selection'),100)
    else
      days_diff = $scope.selected_date.diff(moment().startOf('day'), 'days')
      hour = moment().hours()
      minute = moment().minutes()
      if days_diff == 0 and hour <= 14 and minute <= 59 # same day booking before 3pm
        $timeout((->$scope.$broadcast 'same_day_confirmation'),100)
      else if days_diff == 1 and hour >= 22 # next day booking after 10pm
        $timeout((->$scope.$broadcast 'next_day_confirmation'),100)
      else
        $timeout((->$scope.$broadcast 'booking_selection'),100)

  $scope.edit = ->
    ngDialog.open template: 'property-edit-modal', controller: 'property', className: 'edit', scope: $scope

  $scope.edit_access = ->
    ngDialog.open template: 'property-access-modal', controller: 'property', className: 'edit full', scope: $scope

  $scope.edit_trash = ->
    ngDialog.open template: 'property-trash-modal', controller: 'property', className: 'edit full', scope: $scope

  $scope.edit_parking = ->
    ngDialog.open template: 'property-parking-modal', controller: 'property', className: 'edit full', scope: $scope

  $scope.edit_restocking = ->
    ngDialog.open template: 'property-restocking-modal', controller: 'property', className: 'edit full', scope: $scope

  $scope.edit_additional = ->
    ngDialog.open template: 'property-additional-modal', controller: 'property', className: 'edit full', scope: $scope

  $scope.open_deactivation = ->
    ngDialog.open template: 'property-deactivation-modal', controller: 'property', className: 'warning full', scope: $scope

  $scope.open_reactivation = ->
    ngDialog.open template: 'property-reactivation-modal', controller: 'property', className: 'warning full', scope: $scope

  $scope.toggle = (event) =>
    id = if $(event.currentTarget).parents('.section').hasClass('services') then '.table' else '.instruction'
    content = $(event.currentTarget).parents('.section').find(id)
    $(event.currentTarget).removeClass('icon-acc-close icon-acc-open')
    if content.is(':visible')
      $(event.currentTarget).addClass('icon-acc-close')
    else
      $(event.currentTarget).addClass('icon-acc-open')
    content.toggle()
    return true

  $scope.cancel_deactivation = ->
    ngDialog.closeAll()

  $scope.confirm_deactivation = ->
    $http.post("/properties/#{$scope.property.slug}/deactivate").success (rsp) ->
      if rsp.success
        window.location = '/'
      else
        flash 'failure', rsp.message

  $scope.confirm_reactivation = ->
    $http.post("/properties/#{$scope.property.slug}/reactivate").success (rsp) ->
      if rsp.success
        window.location = '/'
      else
        flash 'failure', rsp.message

  $scope.expand = (section) ->
    angular.element('#property .section').removeClass 'active'
    angular.element("#property .section.#{section}").addClass 'active'
    null

  load_bookings = (rsp) ->
    $scope.property.next_service_date = moment(rsp.next_service_date, 'YYYY-MM-DD').format('MM/DD/YY') if rsp.next_service_date

    _($scope.property.active_bookings).each (booking) ->
      date = moment.utc booking.date
      booking.parsed_date = date.format('MMMM Do, YYYY')
      booking.parsed_date_short = date.format('MM/DD/YY')
      booking.display_services = _(booking.services).map((booking) -> booking.display).join(', ')
      angular.element(".column.cal .calendar td.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]").addClass('booked').attr('booking', booking.id)

    _($scope.property.past_bookings).each (booking) ->
      date = moment.utc booking.date
      booking.parsed_date = date.format('MMMM Do, YYYY')
      booking.parsed_date_short = date.format('MM/DD/YY')
      booking.display_services = _(booking.services).map((booking) -> booking.display).join(', ')
      angular.element(".column.cal .calendar td.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]").addClass('booked').attr('booking', booking.id)

  $scope.$on 'refresh_bookings', ->
    $http.get($window.location.href + '.json').success (rsp) ->
      $scope.property = rsp
      load_bookings(rsp)

  refresh_map = ->
    $scope.geocoder.query $scope.property.full_address, (err, data) ->
      if data.latlng
        $scope.map.setView([data.latlng[0], data.latlng[1]], 14)
        $scope.markers.clearLayers() # always clear previous markers
        L.marker([data.latlng[0], data.latlng[1]], {
          icon: L.icon({
            iconUrl: '/images/pin.png',
            iconSize: [28, 49],
          })
        }).addTo $scope.markers

  $scope.exists = () ->
    if $scope.property.active_bookings
      _($scope.property.active_bookings).find (b) -> b.id.toString() == $scope.selected_booking.toString() if $scope.selected_booking

  $scope.property_image = (src) ->
    $scope.image = src

  flash = (type, msg, modal) ->
    el = if modal then angular.element('.modal .flash') else angular.element('#property .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0).removeClass('info success failure')
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

  $scope.rooms = ->
    {
    dropdownCssClass: 'details'
    minimumResultsForSearch: -1
    data: [{id:'0',text:'0'},{id:'1',text:'1'},{id:'2',text:'2'},{id:'3',text:'3'},{id:'4',text:'4'},{id:'5',text:'5'},{id:'6',text:'6'},{id:'7',text:'7'},{id:'8',text:'8'},{id:'9',text:'9'},{id:'10',text:'10'}]
    initSelection: (el, cb) ->
    }

  $scope.beds = ->
    {
    dropdownCssClass: 'details'
    minimumResultsForSearch: -1
    data: [{id:'0',text:'0'},{id:'1',text:'1'},{id:'2',text:'2'},{id:'3',text:'3'},{id:'4',text:'4'},{id:'5',text:'5'},{id:'6',text:'6'},{id:'7',text:'7'},{id:'8',text:'8'},{id:'9',text:'9'},{id:'10',text:'10'}]
    initSelection: (el, cb) ->
    }
]

app = angular.module('porter').controller('property', PropertyCtrl)
