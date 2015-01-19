PropertyCtrl = ['$scope', '$http', '$window', '$timeout', '$rootScope', 'ngDialog', ($scope, $http, $window, $timeout, $rootScope, ngDialog) ->

  $scope.form = {}
  $scope.selected_date = {}
  $scope.payment = {}
  $scope.selected_services = {cleaning:false,linens:false,restocking:false}
  $scope.selected_booking = null
  promises = {}

  $http.get($window.location.href + '.json').success (rsp) ->
    $scope.property = rsp
    _($scope.property.bookings).each (booking) ->
      date = moment.utc booking.date
      booking.parsed_date = date.format('MMMM Do, YYYY')
      angular.element("#calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").addClass('booked').attr('booking', booking.id)

    bedrooms_text = if rsp.bedrooms == 0 then 'None' else if rsp.bedrooms == 1 then 'Bedroom' else 'Bedrooms'
    $scope.form.bedrooms = { id: rsp.bedrooms.toString(), text: "#{rsp.bedrooms} #{bedrooms_text}" }
    bathrooms_text = if rsp.bathrooms == 0 then 'None' else if rsp.bathrooms == 1 then 'Bath' else 'Bathrooms'
    $scope.form.bathrooms = { id: rsp.bathrooms.toString(), text: "#{rsp.bathrooms} #{bathrooms_text}" }
    twin_beds_text = if rsp.twin_beds == 0 then 'None' else if rsp.twin_beds == 1 then 'Bed' else 'Beds'
    $scope.form.twin_beds = { id: rsp.twin_beds.toString(), text: "#{rsp.twin_beds} #{twin_beds_text}" }
    full_beds_text = if rsp.full_beds == 0 then 'None' else if rsp.full_beds == 1 then 'Bed' else 'Beds'
    $scope.form.full_beds = { id: rsp.full_beds.toString(), text: "#{rsp.full_beds} #{full_beds_text}" }
    queen_beds_text = if rsp.queen_beds == 0 then 'None' else if rsp.queen_beds == 1 then 'Bed' else 'Beds'
    $scope.form.queen_beds = { id: rsp.queen_beds.toString(), text: "#{rsp.queen_beds} #{queen_beds_text}" }
    king_beds_text = if rsp.king_beds == 0 then 'None' else if rsp.king_beds == 1 then 'Bed' else 'Beds'
    $scope.form.king_beds = { id: rsp.king_beds.toString(), text: "#{rsp.king_beds} #{king_beds_text}" }

  $scope.calendar_options =
    {
      selectable: true
      clickable: false
      selected_class: 'booked'
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
    if section == 'map'
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
    _(_(_(_($scope.user.properties).map((p) -> p.bookings)).flatten())).find (b) -> b.id.toString() == $scope.selected_booking

  $scope.$watch 'property.nickname', (n,o) -> if o
    $timeout.cancel promises.nickname
    promises.nickname = $timeout((->
      $http.post($window.location.href, {form: { title: n }}).success (rsp) ->
        if rsp.success
          if angular.element('.input.nickname .typcn').css('opacity') == '0'
            angular.element('.input.nickname .typcn').css 'opacity', 1
          else
            angular.element('.input.nickname .typcn').css 'opacity', 0
            $timeout((->angular.element('.input.nickname .typcn').css 'opacity', 1),600)
          #$timeout((->angular.element('.input.nickname .typcn').css 'opacity', 0),5000)
        else
          flash('failure', rsp.message)
    ),2000)

  $scope.$watch 'form.bedrooms.id', (n,o) -> if o
    $http.post($window.location.href, {form: { bedrooms: n }}).success (rsp) ->
      if rsp.success
        flash('success', 'Changes saved')
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.bathrooms.id', (n,o) -> if o
    $http.post($window.location.href, {form: { bathrooms: n }}).success (rsp) ->
      if rsp.success
        flash('success', 'Changes saved')
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.twin_beds.id', (n,o) -> if o
    $http.post($window.location.href, {form: { twin_beds: n }}).success (rsp) ->
      if rsp.success
        flash('success', 'Changes saved')
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.full_beds.id', (n,o) -> if o
    $http.post($window.location.href, {form: { full_beds: n }}).success (rsp) ->
      if rsp.success
        flash('success', 'Changes saved')
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.queen_beds.id', (n,o) -> if o
    $http.post($window.location.href, {form: { queen_beds: n }}).success (rsp) ->
      if rsp.success
        flash('success', 'Changes saved')
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.king_beds.id', (n,o) -> if o
    $http.post($window.location.href, {form: { king_beds: n }}).success (rsp) ->
      if rsp.success
        flash('success', 'Changes saved')
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

  $scope.beds = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:'0',text:'None'},{id:'1',text:'1'},{id:'2',text:'2'},{id:'3',text:'3'},{id:'4',text:'4'},{id:'5',text:'5'},{id:'6',text:'6'},{id:'7',text:'7'},{id:'8',text:'8'},{id:'9',text:'9'},{id:'10',text:'10'}]
      initSelection: (el, cb) ->
    }

]

app = angular.module('porter').controller('property', PropertyCtrl)
