AdminPropertyCtrl = ['$scope', '$http', '$window', '$timeout', '$interval', '$upload', '$rootScope', 'spinner', 'ngDialog', ($scope, $http, $window, $timeout, $interval, $upload, $rootScope, spinner, ngDialog) ->

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

  $scope.update_details = ->
    if _(angular.element('.bed-types').find('input')).filter((el) -> parseInt(angular.element(el).val()) > 0).length is 0
      flash 'failure', 'Please select at least one bed', true
      return
    $scope.update_property()

  $scope.update_property = ->
    post_url = "/properties/#{$scope.property.id}"
    spinner.startSpin()
    if $scope.files && $scope.files[0]
      $upload.upload(
        url: post_url
        file: $scope.files[0]
        fields:
          form: $scope.form
      ).success (rsp) ->
        if typeof rsp.success == 'undefined'
          $window.location = $window.location.href
        else
          spinner.stopSpin()
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
        url: "/properties/#{$scope.property.id}/upload"
        file: $scope.files[0]
      ).success (rsp) ->
        spinner.stopSpin()
        if rsp.success
          angular.element('.preview').attr('src', rsp.image)
        else
          flash 'failure', rsp.message, true

  $scope.edit = ->
    ngDialog.open template: 'property-edit-modal', controller: 'admin-property', className: 'edit', scope: $scope

  $scope.edit_access = ->
    ngDialog.open template: 'property-access-modal', controller: 'admin-property', className: 'edit full', scope: $scope

  $scope.edit_trash = ->
    ngDialog.open template: 'property-trash-modal', controller: 'admin-property', className: 'edit full', scope: $scope

  $scope.edit_parking = ->
    ngDialog.open template: 'property-parking-modal', controller: 'admin-property', className: 'edit full', scope: $scope

  $scope.edit_restocking = ->
    ngDialog.open template: 'property-restocking-modal', controller: 'admin-property', className: 'edit full', scope: $scope

  $scope.edit_additional = ->
    ngDialog.open template: 'property-additional-modal', controller: 'admin-property', className: 'edit full', scope: $scope

  $scope.open_deactivation = ->
    ngDialog.open template: 'property-deactivation-modal', controller: 'admin-property', className: 'warning full', scope: $scope

  $scope.open_reactivation = ->
    ngDialog.open template: 'property-reactivation-modal', controller: 'admin-property', className: 'warning full', scope: $scope

  $scope.cancel_deactivation = ->
    ngDialog.closeAll()

  $scope.confirm_deactivation = ->
    $http.post("/properties/#{$scope.property.id}/deactivate").success (rsp) ->
      if rsp.success
        spinner.startSpin()
        $window.location = $window.location.href
      else
        flash 'failure', rsp.message

  $scope.confirm_reactivation = ->
    $http.post("/properties/#{$scope.property.id}/reactivate").success (rsp) ->
      if rsp.success
        spinner.startSpin()
        $window.location = $window.location.href
      else
        flash 'failure', rsp.message

  load_bookings = (rsp) ->
    $scope.property.next_service_date = moment(rsp.next_service_date, 'YYYY-MM-DD').format('MM/DD/YY') if rsp.next_service_date

    _(['future_bookings', 'past_bookings']).each (type) ->
      _($scope.property[type]).each (booking) ->
        date = moment.utc booking.date
        booking.parsed_date = date.format('MMMM Do, YYYY')
        booking.parsed_date_short = date.format('MM/DD/YY')
        booking.display_services = _(booking.services).map((booking) -> booking.display).join(', ')

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

app = angular.module('porter').controller('admin-property', AdminPropertyCtrl)
