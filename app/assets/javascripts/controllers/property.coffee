PropertyCtrl = ['$scope', '$http', '$window', '$timeout', '$upload', '$rootScope', 'ngDialog', ($scope, $http, $window, $timeout, $upload, $rootScope, ngDialog) ->

  $scope.form = {}
  $scope.chosen_dates = {}
  $scope.payment = {}
  $scope.selected_services = {}
  $scope.selected_date = null
  $scope.current_zip = null
  $scope.current_address1 = null

  promises = {}

  $http.get($window.location.href + '.json').success (rsp) ->
    $scope.property = rsp
    $scope.form = _(rsp).clone()
    $scope.form.property_type = { id: rsp.property_type, text: rsp.property_type.capitalize() }
    $scope.form.rental_type = { id: rsp.rental_type, text: rsp.rental_type.capitalize() }

    $scope.property.next_service_date = moment(rsp.next_service_date, 'YYYY-MM-DD').format('MM/DD/YY') if rsp.next_service_date

    _($scope.property.bookings).each (booking) ->
      date = moment.utc booking.date
      booking.parsed_date = date.format('MMMM Do, YYYY')
      booking.parsed_date_short = date.format('MM/DD/YY')
      angular.element(".column.cal .calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").addClass('booked').attr('booking', booking.id)

    $scope.property.upcoming_bookings = _($scope.property.bookings).filter (booking) ->
      moment(booking.date, 'YYYY-MM-DD').diff(moment(), 'days') > 0

    $scope.property.past_bookings = _($scope.property.bookings).filter (booking) ->
      moment(booking.date, 'YYYY-MM-DD').diff(moment(), 'days') < 0

    $scope.map = L.mapbox.map 'map', 'useporter.l02en9o9'
    $scope.markers = new L.LayerGroup().addTo($scope.map)
    $scope.geocoder = L.mapbox.geocoder 'mapbox.places'
    refresh_map()

    $scope.form.bedrooms = { id: rsp.bedrooms.toString(), text: rsp.bedrooms.toString() }
    $scope.form.bathrooms = { id: rsp.bathrooms.toString(), text: rsp.bathrooms.toString() }
    $scope.form.twin_beds = { id: rsp.twin_beds.toString(), text: rsp.twin_beds.toString() }
    $scope.form.full_beds = { id: rsp.full_beds.toString(), text: rsp.full_beds.toString() }
    $scope.form.queen_beds = { id: rsp.queen_beds.toString(), text: rsp.queen_beds.toString() }
    $scope.form.king_beds = { id: rsp.king_beds.toString(), text: rsp.king_beds.toString() }
    $scope.current_zip = $scope.form.zip
    $scope.current_address1 = $scope.form.address1
    $scope.property_image($scope.property.property_photos[0].photo.url)

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
              angular.element(".booking.modal .calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive').attr('booking', booking.id)
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
        $scope.selected_date_text = date.format('ddd, MMM D')
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
              angular.element(".booking.modal .services .service.#{service.name}").addClass 'active'
              angular.element(".booking.modal .services .service.#{service.name} input").attr 'checked', true
    }

  $scope.confirm_deactivation = ->
    ngDialog.open template: 'deactivation-modal', className: 'booking', scope: $scope

  $scope.confirm_reactivation = ->
    ngDialog.open template: 'reactivation-modal', className: 'booking', scope: $scope

  $scope.expand = (section) ->
    angular.element('#property .section').removeClass 'active'
    angular.element("#property .section.#{section}").addClass 'active'
    null

  refresh_map = ->
    $scope.geocoder.query $scope.property.full_address, (err, data) ->
      if data.latlng
        $scope.map.setView([data.latlng[0], data.latlng[1]], 14)
        $scope.markers.clearLayers() # always clear previous markers
        L.marker([data.latlng[0], data.latlng[1]], {
          icon: L.mapbox.marker.icon({
            'marker-size': 'large',
            'marker-symbol': 'building',
            'marker-color': '#35A9B1'
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

  $scope.$on 'refresh_bookings', ->
    $http.get($window.location.href + '.json').success (rsp) ->
      $scope.property = rsp
      _($scope.property.bookings).each (booking) ->
        date = moment.utc booking.date
        booking.parsed_date = date.format('MMMM Do, YYYY')
        angular.element(".column.cal .calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").addClass('booked').attr('booking', booking.id)

  $scope.property_image = (src) ->
    $scope.image = src

  $scope.$watch 'files', (n,o) -> if n
    $upload.upload(
      url: $window.location.href
      file: n[0]
    ).success (rsp) ->
      form_flash 'photo'
      $scope.property_image(rsp.image)

  $scope.$watch 'form.zip', (n,o) -> if o
    $scope.current_zip = n
    $timeout.cancel promises.zip
    promises.zip = $timeout((->
      update('zip', {form: { zip: n, address1: $scope.current_address1 }})
    ),2000)

  $scope.$watch 'form.address1', (n,o) -> if o
    $scope.current_address1 = n
    $timeout.cancel promises.address1
    promises.address1 = $timeout((->
      update('address1', {form: { address1: n, zip: $scope.current_zip  }})
    ),2000)

  $scope.$watch 'form.nickname', (n,o) -> if o
    $timeout.cancel promises.nickname
    promises.nickname = $timeout((->
      update('nickname', {form: { title: n }})
    ),2000)

  $scope.$watch 'form.property_type', (n,o) -> if o
    update('property_type', {form: { property_type: n }})

  $scope.$watch 'form.rental_type', (n,o) -> if o
    update('rental_type', {form: { rental_type: n }})

  $scope.$watch 'form.bedrooms.id', (n,o) -> if o
    update('bedrooms', {form: { bedrooms: n }})

  $scope.$watch 'form.bathrooms.id', (n,o) -> if o
    update('bathrooms', {form: { bathrooms: n }})

  $scope.$watch 'form.twin_beds.id', (n,o) -> if o
    update('twins', {form: { twin_beds: n }})

  $scope.$watch 'form.full_beds.id', (n,o) -> if o
    update('fulls', {form: { full_beds: n }})

  $scope.$watch 'form.queen_beds.id', (n,o) -> if o
    update('queens', {form: { queen_beds: n }})

  $scope.$watch 'form.king_beds.id', (n,o) -> if o
    update('kings', {form: { king_beds: n }})

  $scope.$watch 'form.access_info', (n,o) -> if o
    update('access', {form: { access_info: n }})

  $scope.$watch 'form.trash_disposal', (n,o) -> if o
    update('trash', {form: { trash_disposal: n }})

  $scope.$watch 'form.parking_info', (n,o) -> if o
    update('parking', {form: { parking_info: n }})

  $scope.$watch 'form.additional_info', (n,o) -> if o
    update('additional', {form: { additional_info: n }})

  update = (field, params) ->
    $http.post($window.location.href, params).success (rsp) ->
      if rsp.id
        $scope.property = rsp
        form_flash field
        refresh_map() if field is 'zip' or field is 'address1'
      else
        flash('failure', rsp.message)

  flash = (type, msg) ->
    angular.element('#property .flash').removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      angular.element('#property .flash').css('opacity', 0).removeClass('info success failure')
    ), 3000)
    $timeout((->
      angular.element('#property .flash').removeClass('info success failure')
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
      data: [{id:'house',text:'House'},{id:'condo',text:'Condo'},{id:'apartment',text:'Apartment'}]
      initSelection: (el, cb) ->
    }

  $scope.rental_type = ->
    {
    dropdownCssClass: 'details'
    minimumResultsForSearch: -1
    data: [{id:'full-time',text:'Full-time'},{id:'part-time',text:'Part-time'}]
    initSelection: (el, cb) ->
    }

]

app = angular.module('porter').controller('property', PropertyCtrl)
