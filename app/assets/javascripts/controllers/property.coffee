PropertyCtrl = ['$scope', '$http', '$window', '$timeout', '$interval', '$upload', '$rootScope', 'ngDialog', ($scope, $http, $window, $timeout, $interval, $upload, $rootScope, ngDialog) ->

  $scope.form = {}
  $scope.chosen_dates = {}
  $scope.payment = {}
  $scope.selected_services = {}
  $scope.selected_date = null
  $scope.current_zip = null
  $scope.current_address1 = null
  promises = {}

  $scope.$on 'refresh_property', -> $http.get($window.location.href + '.json').success (rsp) ->
    _($scope.property).extend rsp
    $scope.property.next_service_date = moment(rsp.next_service_date, 'YYYY-MM-DD').format('MM/DD/YY') if rsp.next_service_date

  $http.get($window.location.href + '.json').success (rsp) ->
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
          _($scope.property.bookings).each (booking) ->
            date = moment.utc(booking.date)
            if $('.booking.modal')[0]
              angular.element(".booking.modal .calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive booked').attr('booking', booking.id)
            else
              $timeout((->
                angular.element(".booking.modal .calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive').attr('booking', booking.id)
              ),100)
    }

  $scope.calendar_options =
    {
      selectable: true
      clickable: false
      selected_class: 'booked'
      disable_past: true
      onchange: () ->
        if $scope.property
          _($scope.property.bookings).each (booking) ->
            date = moment.utc(booking.date)
            angular.element(".column.cal .calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").addClass('booked').attr('booking', booking.id)

      onclick: ($this) ->
        ngDialog.open template: 'booking-modal', className: 'booking', scope: $scope
        date = moment.utc "#{$this.attr 'year'} #{$this.attr 'day'} #{parseInt($this.attr 'month')+1}", 'YYYY D MM'
        $scope.selected_date = date
        $scope.selected_date_confirmation = date.format('ddd, MMM D')
        $scope.selected_date_booking = date.format('MMM D, YYYY')
        $scope.chosen_dates["#{date.month()}-#{date.year()}"] = [date.date()]
        $scope.selected_services = {}
        $scope.selected_booking = $this.attr 'booking'
        if $scope.selected_booking
          $http.get("#{$window.location.href}/#{$scope.selected_booking}/show").success (rsp) ->
            payment_type = if rsp.payment.stripe_id then 'Card' else 'Bank'
            $scope.payment.id = rsp.payment.id
            $scope.payment.text = "#{payment_type} ending in #{rsp.payment.last4}"
            _(rsp.services).each (service) ->
              $scope.selected_services[service.name] = true
              angular.element(".booking.modal .services .service.#{service.name}, .booking.modal .extra .service.#{service.name}").addClass 'active'
              angular.element(".booking.modal .services .service.#{service.name} input, .booking.modal .extra .service.#{service.name} input").attr 'checked', true
    }

  $scope.update_details = ->
    if _(angular.element('.bed-types').find('input')).filter((el) -> parseInt(angular.element(el).val()) > 0).length is 0
      flash 'failure', 'Please select at least one bed', true
      return
    $scope.update_property()

  $scope.update_property = ->
    $http.post("/properties/#{$scope.property.slug}/update", {form: $scope.form}).success (rsp) ->
      if typeof rsp.success == 'undefined'
        $scope.$emit 'refresh_property'
        ngDialog.closeAll()
      else
        flash 'failure', rsp.message, true

  $scope.edit = ->
    ngDialog.open template: 'property-edit-modal', controller: 'property', className: 'edit', scope: $scope

  $scope.edit_access = ->
    ngDialog.open template: 'property-access-modal', controller: 'property', className: 'edit', scope: $scope

  $scope.edit_trash = ->
    ngDialog.open template: 'property-trash-modal', controller: 'property', className: 'edit', scope: $scope

  $scope.edit_parking = ->
    ngDialog.open template: 'property-parking-modal', controller: 'property', className: 'edit', scope: $scope

  $scope.edit_additional = ->
    ngDialog.open template: 'property-additional-modal', controller: 'property', className: 'edit', scope: $scope

  $scope.open_deactivation = ->
    ngDialog.open template: 'property-deactivation-modal', controller: 'property', className: 'warning', scope: $scope

  $scope.open_reactivation = ->
    ngDialog.open template: 'property-reactivation-modal', controller: 'property', className: 'warning', scope: $scope

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

    _($scope.property.bookings).each (booking) ->
      date = moment.utc booking.date
      booking.parsed_date = date.format('MMMM Do, YYYY')
      booking.parsed_date_short = date.format('MM/DD/YY')
      booking.display_services = _(booking.services).map((booking) -> booking.display).join(', ')
      booking.display_full_services = booking.display_services
      if booking.display_services.length > 24
        booking.display_services = booking.display_services.slice(0,24) + '...'
      angular.element(".column.cal .calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").addClass('booked').attr('booking', booking.id)

    $scope.property.upcoming_bookings = _($scope.property.bookings).filter (booking) ->
      moment(booking.date, 'YYYY-MM-DD').diff(moment().startOf('day'), 'days') > 0

    $scope.property.past_bookings = _($scope.property.bookings).filter (booking) ->
      moment(booking.date, 'YYYY-MM-DD').diff(moment().startOf('day'), 'days') < 0

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
    if $scope.property.bookings
      _($scope.property.bookings).find (b) -> b.id.toString() == $scope.selected_booking

  form_flash = (field) ->
    el = angular.element(".input.#{field} .typcn")
    if el.css('opacity') == '0'
      el.css 'opacity', 1
    else
      el.css 'opacity', 0
      $timeout((->el.css 'opacity', 1),600)
    $timeout((->el.css 'opacity', 0),4000)

  $scope.property_image = (src) ->
    $scope.image = src

  $scope.$watch 'files', (n,o) -> if n
    $upload.upload(
      url: $window.location.href
      file: n[0]
    ).success (rsp) ->
      form_flash 'photo'
      $scope.property_image(rsp.image)

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
      data: [{id:'0',text:'0'},{id:'1',text:'1'},{id:'2',text:'2'},{id:'3',text:'3'},{id:'4',text:'4'},{id:'5',text:'5'}]
      initSelection: (el, cb) ->
    }

  $scope.beds = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:'0',text:'0'},{id:'1',text:'1'},{id:'2',text:'2'},{id:'3',text:'3'},{id:'4',text:'4'},{id:'5',text:'5'}]
      initSelection: (el, cb) ->
    }

  $scope.property_type = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:0,text:'House'},{id:1,text:'Apartment/Condo'}]
      initSelection: (el, cb) ->
    }

  $scope.rental_type = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:0,text:'Full-time'},{id:1,text:'Part-time'}]
      initSelection: (el, cb) ->
    }

]

app = angular.module('porter').controller('property', PropertyCtrl)
