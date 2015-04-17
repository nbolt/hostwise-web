AdminJobCtrl = ['$scope', '$http', '$timeout', '$interval', '$q', '$window', ($scope, $http, $timeout, $interval, $q, $window) ->

  $scope.jobQ = $q.defer()

  $http.get($window.location.href + '.json').success (rsp) ->
    load_job(rsp)
    $timeout -> $scope.jobQ.resolve()

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

  $scope.$watch 'status', (n,o) -> if o != undefined
    $http.post($window.location.href + '/update_status', {status: $scope.status.id})

  $scope.$watch 'state', (n,o) -> if o != undefined
    $http.post($window.location.href + '/update_state', {state: $scope.state.id})

  $scope.$watch 'new_teammate', (n,o) -> if n
    $http.post($window.location.href + '/add_contractor', {contractor_id: n.id}).success (rsp) ->
      if rsp.failure
        angular.element('.add-teammate .flash').css 'display', 'block'
        $timeout((-> angular.element('.add-teammate .flash').css('opacity', 1).text rsp.message), 50)
        $timeout((->
          angular.element('.add-teammate .flash').css 'opacity', 0
          $timeout((-> angular.element('.add-teammate .flash').css 'display', 'none'), 800)
        ), 3000)
      else
        load_job(rsp)

  $scope.remove = (contractor) ->
    $http.post($window.location.href + '/remove_contractor', {contractor_id: contractor.id}).success (rsp) -> load_job(rsp)

  $scope.stateHash = ->
    {
      minimumResultsForSearch: -1
      data: [{id:0,text:'Normal'},{id:1,text:'VIP'},{id:2,text:'Hidden'}]
      initSelection: (el, cb) ->
    }

  $scope.statusHash = ->
    {
      minimumResultsForSearch: -1
      data: [{id:0,text:'Open'},{id:1,text:'Scheduled'},{id:2,text:'In Progress'},{id:3,text:'Completed'},{id:4,text:'Past Due'},{id:5,text:"Can't Access"},{id:6,text:'Cancelled'}]
      initSelection: (el, cb) ->
    }

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
        results: (data) -> { results: _(data).filter((contractor) -> contractor.contractor_profile).map (contractor) -> { id: contractor.id, text: "#{contractor.name} - #{contractor.contractor_profile.display_position}" } }
    }

  $scope.refresh_cost = ->
    $http.post("/jobs/#{$scope.job.id}/booking_cost", {services: $scope.job.booking.services}).success (rsp) ->
      _rsp = rsp
      $scope.job.booking.cost = rsp.cost
      _($scope.job.booking.services).each (service) ->
        service.cost = rsp[service.name]
        angular.element(".services .service.#{service.name}").addClass 'active'
        angular.element(".services .service.#{service.name} input").attr 'checked', true

  $scope.refresh_invoice = ->
    $http.get($window.location.href + '.json').success (rsp) ->
      load_job(rsp)

  load_job = (rsp) ->
    $scope.job = rsp
    $scope.job.contractor_count = $scope.job.contractors.length
    $scope.job.date_text = moment(rsp.date, 'YYYY-MM-DD').format 'ddd, MMM D'
    $scope.job.standard_services = _(rsp.booking.services).reject (s) -> s.extra
    $scope.job.extra_services    = _(rsp.booking.services).filter (s) -> s.extra

    switch $scope.job.state_cd
      when 0
        $scope.state = { id: $scope.job.state_cd, text: 'Normal' }
      when 1
        $scope.state = { id: $scope.job.state_cd, text: 'VIP' }
      when 2
        $scope.state = { id: $scope.job.state_cd, text: 'Hidden' }

    switch $scope.job.status_cd
      when 0
        $scope.status = { id: $scope.job.status_cd, text: 'Open' }
      when 1
        $scope.status = { id: $scope.job.status_cd, text: 'Scheduled' }
      when 2
        $scope.status = { id: $scope.job.status_cd, text: 'In Progress' }
      when 3
        $scope.status = { id: $scope.job.status_cd, text: 'Completed' }
      when 4
        $scope.status = { id: $scope.job.status_cd, text: 'Past Due' }
      when 5
        $scope.status = { id: $scope.job.status_cd, text: "Can't Access" }
      when 6
        $scope.status = { id: $scope.job.status_cd, text: 'Cancelled' }

    $scope.refresh_cost()
]

app = angular.module('porter').controller('admin_job', AdminJobCtrl)
