JobCtrl = ['$scope', '$http', '$timeout', '$interval', '$window', '$q', 'ngDialog', ($scope, $http, $timeout, $interval, $window, $q, ngDialog) ->

  $scope.jobQ = $q.defer()
  $scope.job_status = 'blocked'

  $http.get($window.location.href + '.json').success (rsp) ->
    $scope.job = rsp
    $scope.job.contractor_count = $scope.job.contractors.length
    $scope.job.date_text = moment(rsp.date, 'YYYY-MM-DD').format 'ddd, MMM D'
    $scope.job.standard_services = _(rsp.booking.services).reject (s) -> s.extra
    $scope.job.extra_services = _(rsp.booking.services).filter (s) -> s.extra
    $scope.staging = _($scope.job.standard_services).find (s) -> s.display == 'Staging'
    $scope.vip = $scope.job.state_cd == 1 unless $scope.staging #always show staging if it is a staging and vip job
    $timeout -> $scope.jobQ.resolve()
    $scope.user_fetched.promise.then -> $scope.job.contractors = _($scope.job.contractors).reject (user) -> user.id == $scope.user.id

    $http.get('/man_hrs').success (rsp) ->
      man_hrs = rsp[$scope.job.booking.property.property_type][$scope.job.booking.property.bedrooms][$scope.job.booking.property.bathrooms]
      $scope.man_hrs = "#{man_hrs} hours (est.)" if man_hrs

    load_mapbox = null
    load_mapbox = $interval((->
      if $window.loaded_mapbox
        $interval.cancel(load_mapbox)
        map = L.mapbox.map('map', 'useporter.l02en9o9',
          dragging: false
          touchZoom: false
          scrollWheelZoom: false
          doubleClickZoom: false
          attributionControl: false)
        markers = new L.LayerGroup().addTo(map)
        geocoder = L.mapbox.geocoder 'mapbox.places'
        geocoder.query $scope.job.booking.property.full_address, (err, data) ->
          if data.latlng
            map.setView([data.latlng[0], data.latlng[1]], 14)
            markers.clearLayers() # always clear previous markers
            L.marker([data.latlng[0], data.latlng[1]], {
              icon: L.icon({
                iconUrl: '/images/pin.png',
                iconSize: [28, 49],
              })
            }).addTo markers
    ), 200)

  $http.get($window.location.href + '/status').success (rsp) -> $scope.job_status = rsp.status

  $scope.completed_job = -> $scope.job.status_cd == 3

  $scope.arrived = ->
    angular.element('.arrived-dropdown').css 'max-height', 80
    null

  $scope.start = ->
    $http.post("/jobs/#{$scope.job.id}/begin")
    angular.element('.viewports').css 'margin-left', '-100%'
    angular.element('.viewport.side').removeClass 'active'
    angular.element('.viewport.start').addClass 'active'
    null

  $scope.complete = ->
    $http.post("/jobs/#{$scope.job.id}/complete").success (rsp) ->
      if rsp.next_job
        $window.location = "/jobs/#{rsp.next_job}"
      else
        $window.location = '/'

  $scope.cancel_modal = ->
    ngDialog.open template: 'cancel-job-modal', className: 'warning full', scope: $scope

  $scope.close_cancellation = ->
    ngDialog.closeAll()

  $scope.confirm_cancellation = ->
    $http.post("/jobs/#{$scope.job.id}/drop").success (rsp) -> $window.location = '/'

  $scope.pricing_class = ->
    if $scope.staging
      'staging'
    else if $scope.vip
      'vip'
    else
      ''

]

app = angular.module('porter').controller('job', JobCtrl)
