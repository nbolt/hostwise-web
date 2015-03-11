AdminJobCtrl = ['$scope', '$http', '$timeout', '$interval', '$q', '$window', ($scope, $http, $timeout, $interval, $q, $window) ->

  $scope.jobQ = $q.defer()

  $http.get($window.location.href + '.json').success (rsp) ->
    load_job(rsp)
    $timeout -> $scope.jobQ.resolve()

    $http.post("/jobs/#{$scope.job.id}/booking_cost", {services: $scope.job.booking.services}).success (rsp) ->
      _rsp = rsp
      _($scope.job.booking.services).each (service) -> service.cost = rsp[service.name]
      $http.get('/cost').success (rsp) ->
        $scope.pricing = rsp
        if _rsp.cost >= $scope.pricing.first_booking_discount
          $scope.job.first_booking_discount = $scope.pricing.first_booking_discount
        else
          $scope.job.first_booking_discount = _rsp.cost

    load_mapbox = null
    load_mapbox = $interval((->
      if $window.loaded_mapbox
        $interval.cancel(load_mapbox)
        map = L.mapbox.map 'map', 'useporter.l02en9o9'
        map.dragging.disable(); map.touchZoom.disable(); map.doubleClickZoom.disable(); map.scrollWheelZoom.disable()
        geocoder = L.mapbox.geocoder 'mapbox.places'
        geocoder.query $scope.job.booking.property.full_address, (err, data) ->
          if data.latlng
            map.setView([data.latlng[0], data.latlng[1]], 14)
            L.marker([data.latlng[0], data.latlng[1]], {
                icon: L.mapbox.marker.icon({
                    'marker-size': 'large',
                    'marker-symbol': 'building',
                    'marker-color': '#35A9B1'
                })
            }).addTo map
    ), 200)

  $scope.$watch 'job.state_cd', (n,o) -> if o != undefined
    $http.post($window.location.href + '/update_state', {state: $scope.job.state_cd})

  $scope.$watch 'new_teammate', (n,o) -> if n
    $http.post($window.location.href + '/add_contractor', {contractor_id: n.id}).success (rsp) -> load_job(rsp)

  $scope.remove = (contractor) ->
    $http.post($window.location.href + '/remove_contractor', {contractor_id: contractor.id}).success (rsp) -> load_job(rsp)

  $scope.teamHash = ->
    {
      dropdownCssClass: 'new-teammate'
      data: []
      initSelection: (el, cb) ->
      formatResult: (data) -> data.text
      ajax:
        url: $window.location.href + '/available_contractors'
        quietMillis: 400
        data: (term) -> { term: term }
        results: (data) -> { results: _(data).map (contractor) -> { id: contractor.id, text: contractor.name } }
    }

  load_job = (rsp) ->
    $scope.job = rsp
    $scope.job.contractor_count = $scope.job.contractors.length
    $scope.job.date_text = moment(rsp.date, 'YYYY-MM-DD').format 'ddd, MMM D'
    $scope.job.standard_services = _(rsp.booking.services).reject (s) -> s.extra
    $scope.job.extra_services    = _(rsp.booking.services).filter (s) -> s.extra
    switch $scope.job.state_cd
      when 0
        angular.element('#state-normal').click()
      when 1
        angular.element('#state-vip').click()
      when 2
        angular.element('#state-hidden').click()

]

app = angular.module('porter').controller('admin_job', AdminJobCtrl)
