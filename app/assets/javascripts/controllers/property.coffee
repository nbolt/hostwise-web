String.prototype.capitalize = -> this.charAt(0).toUpperCase() + this.slice(1)

PropertyCtrl = ['$scope', '$http', '$window', '$timeout', '$upload', '$rootScope', 'ngDialog', ($scope, $http, $window, $timeout, $upload, $rootScope, ngDialog) ->

  $scope.form = {}
  $scope.selected_date = {}
  $scope.payment = {}
  $scope.selected_services = {cleaning:false,linens:false,restocking:false}
  $scope.selected_booking = null
  promises = {}

  $http.get($window.location.href + '.json').success (rsp) ->
    $scope.property = rsp
    $scope.form     = rsp
    $scope.form.property_type = { id: rsp.property_type, text: rsp.property_type.capitalize() }
    _($scope.property.bookings).each (booking) ->
      date = moment.utc booking.date
      booking.parsed_date = date.format('MMMM Do, YYYY')
      angular.element("#calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").addClass('booked').attr('booking', booking.id)
      #angular.element('#property .section .input.property_type').select2 'data', rsp.property

    bedrooms_text = if rsp.bedrooms == 0 then 'None' else if rsp.bedrooms == 1 then 'Bedroom' else 'Bedrooms'
    $scope.form.bedrooms = { id: rsp.bedrooms.toString(), text: "#{rsp.bedrooms} #{bedrooms_text}" }
    bathrooms_text = if rsp.bathrooms == 0 then 'None' else if rsp.bathrooms == 1 then 'Bath' else 'Bathrooms'
    $scope.form.bathrooms = { id: rsp.bathrooms.toString(), text: "#{rsp.bathrooms} #{bathrooms_text}" }
    twin_beds_text = if rsp.twin_beds == 0 then 'None' else if rsp.twin_beds == 1 then '1 Twin' else "#{rsp.twin_beds} Twins"
    $scope.form.twin_beds = { id: rsp.twin_beds.toString(), text: twin_beds_text }
    full_beds_text = if rsp.full_beds == 0 then 'None' else if rsp.full_beds == 1 then '1 Full' else "#{rsp.full_beds} Fulls"
    $scope.form.full_beds = { id: rsp.full_beds.toString(), text: full_beds_text }
    queen_beds_text = if rsp.queen_beds == 0 then 'None' else if rsp.queen_beds == 1 then '1 Queen' else "#{rsp.queen_beds} Queens"
    $scope.form.queen_beds = { id: rsp.queen_beds.toString(), text: queen_beds_text }
    king_beds_text = if rsp.king_beds == 0 then 'None' else if rsp.king_beds == 1 then '1 King' else "#{rsp.king_beds} Kings"
    $scope.form.king_beds = { id: rsp.king_beds.toString(), text: king_beds_text }

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
            angular.element("#calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").addClass('booked').attr('booking', booking.id)

      onclick: ($this) ->
        ngDialog.open template: 'booking-modal', className: 'booking', scope: $scope
        date = moment.utc "#{$this.attr 'year'} #{$this.attr 'day'} #{parseInt($this.attr 'month')+1}", 'YYYY D MM'
        $scope.selected_date.moment = date
        $scope.selected_date.num = date.day()
        $scope.selected_date.day_text = date.format('dddd,')
        $scope.selected_date.date_text = date.format('MMM Do')
        $scope.selected_booking = $this.attr('booking')
        $scope.selected_services = {cleaning:false,linens:false,restocking:false}
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

  $scope.expand = (section) ->
    angular.element('#property .section').removeClass 'active'
    angular.element("#property .section.#{section}").addClass 'active'
    if section == 'map' && !angular.element('.leaflet-container')[0]
      map = L.mapbox.map 'map', 'useporter.l02en9o9'
      geocoder = L.mapbox.geocoder 'mapbox.places'
      geocoder.query $scope.property.full_address, (err, data) ->
        if data.latlng
          map.setView([data.latlng[0], data.latlng[1]], 14)
          L.marker([data.latlng[0], data.latlng[1]], {
              icon: L.mapbox.marker.icon({
                  'marker-size': 'large',
                  'marker-symbol': 'building',
                  'marker-color': '#35A9B1'
              })
          }).addTo map
    null

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

  $scope.$watch 'files', (n,o) -> if n
    $upload.upload(
      url: $window.location.href
      file: n[0]
    ).success (rsp) -> console.log rsp

  $scope.$watch 'form.nickname', (n,o) -> if o
    $timeout.cancel promises.nickname
    promises.nickname = $timeout((->
      $http.post($window.location.href, {form: { title: n }}).success (rsp) ->
        if rsp.success
          form_flash 'nickname'
        else
          flash('failure', rsp.message)
    ),2000)

  $scope.$watch 'form.property_type', (n,o) -> if o
    $http.post($window.location.href, {form: { property_type: n }}).success (rsp) ->
      if rsp.success
        form_flash 'property_type'
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.bedrooms.id', (n,o) -> if o
    $http.post($window.location.href, {form: { bedrooms: n }}).success (rsp) ->
      if rsp.success
        form_flash 'bedrooms'
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.bathrooms.id', (n,o) -> if o
    $http.post($window.location.href, {form: { bathrooms: n }}).success (rsp) ->
      if rsp.success
        form_flash 'bathrooms'
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.twin_beds.id', (n,o) -> if o
    $http.post($window.location.href, {form: { twin_beds: n }}).success (rsp) ->
      if rsp.success
        form_flash 'twins'
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.full_beds.id', (n,o) -> if o
    $http.post($window.location.href, {form: { full_beds: n }}).success (rsp) ->
      if rsp.success
        form_flash 'fulls'
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.queen_beds.id', (n,o) -> if o
    $http.post($window.location.href, {form: { queen_beds: n }}).success (rsp) ->
      if rsp.success
        form_flash 'queens'
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.king_beds.id', (n,o) -> if o
    $http.post($window.location.href, {form: { king_beds: n }}).success (rsp) ->
      if rsp.success
        form_flash 'kings'
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.parking_info', (n,o) -> if o
    $http.post($window.location.href, {form: { parking_info: n }}).success (rsp) ->
      if rsp.success
        form_flash 'parking'
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
      data: [{id:'0',text:'None'},{id:'1',text:'1'},{id:'2',text:'2'},{id:'3',text:'3'},{id:'4',text:'4'},{id:'5',text:'5'},{id:'6',text:'6'},{id:'7',text:'7'},{id:'8',text:'8'},{id:'9',text:'9'},{id:'10',text:'10'}]
      initSelection: (el, cb) ->
    }

  $scope.bedrooms = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:'0',text:'None'},{id:'1',text:'1 Bedroom'},{id:'2',text:'2 Bedrooms'},{id:'3',text:'3 Bedrooms'},{id:'4',text:'4 Bedrooms'},{id:'5',text:'5 Bedrooms'},{id:'6',text:'6 Bedrooms'},{id:'7',text:'7 Bedrooms'},{id:'8',text:'8 Bedrooms'},{id:'9',text:'9 Bedrooms'},{id:'10',text:'10 Bedrooms'}]
      initSelection: (el, cb) ->
    }

  $scope.bathrooms = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:'0',text:'None'},{id:'1',text:'1 Bathroom'},{id:'2',text:'2 Bathrooms'},{id:'3',text:'3 Bathrooms'},{id:'4',text:'4 Bathrooms'},{id:'5',text:'5 Bathrooms'},{id:'6',text:'6 Bathrooms'},{id:'7',text:'7 Bathrooms'},{id:'8',text:'8 Bathrooms'},{id:'9',text:'9 Bathrooms'},{id:'10',text:'10 Bathrooms'}]
      initSelection: (el, cb) ->
    }

  $scope.twins = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:'0',text:'None'},{id:'1',text:'1 Twin'},{id:'2',text:'2 Twins'},{id:'3',text:'3 Twins'},{id:'4',text:'4 Twins'},{id:'5',text:'5 Twins'},{id:'6',text:'6 Twins'},{id:'7',text:'7 Twins'},{id:'8',text:'8 Twins'},{id:'9',text:'9 Twins'},{id:'10',text:'10 Twins'}]
      initSelection: (el, cb) ->
    }

  $scope.fulls = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:'0',text:'None'},{id:'1',text:'1 Full'},{id:'2',text:'2 Fulls'},{id:'3',text:'3 Fulls'},{id:'4',text:'4 Fulls'},{id:'5',text:'5 Fulls'},{id:'6',text:'6 Fulls'},{id:'7',text:'7 Fulls'},{id:'8',text:'8 Fulls'},{id:'9',text:'9 Fulls'},{id:'10',text:'10 Fulls'}]
      initSelection: (el, cb) ->
    }

  $scope.queens = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:'0',text:'None'},{id:'1',text:'1 Queen'},{id:'2',text:'2 Queens'},{id:'3',text:'3 Queens'},{id:'4',text:'4 Queens'},{id:'5',text:'5 Queens'},{id:'6',text:'6 Queens'},{id:'7',text:'7 Queens'},{id:'8',text:'8 Queens'},{id:'9',text:'9 Queens'},{id:'10',text:'10 Queens'}]
      initSelection: (el, cb) ->
    }

  $scope.kings = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:'0',text:'None'},{id:'1',text:'1 King'},{id:'2',text:'2 Kings'},{id:'3',text:'3 Kings'},{id:'4',text:'4 Kings'},{id:'5',text:'5 Kings'},{id:'6',text:'6 Kings'},{id:'7',text:'7 Kings'},{id:'8',text:'8 Kings'},{id:'9',text:'9 Kings'},{id:'10',text:'10 Kings'}]
      initSelection: (el, cb) ->
    }

  $scope.property_type = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:'house',text:'House'},{id:'condo',text:'Condo'},{id:'apartment',text:'Apartment'}]
      initSelection: (el, cb) ->
    }

]

app = angular.module('porter').controller('property', PropertyCtrl)
