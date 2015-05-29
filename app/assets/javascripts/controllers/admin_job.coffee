AdminJobCtrl = ['$scope', '$http', '$timeout', '$interval', '$q', '$window', 'ngDialog', ($scope, $http, $timeout, $interval, $q, $window, ngDialog) ->

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

  $scope.$watch 'status', (n,o) -> if o != undefined && o.id != n.id
    if $scope.reset_status
      $scope.reset_status = false
    else
      $http.post($window.location.href + '/update_status', {status: $scope.status.id}).success (rsp) ->
        load_job(JSON.parse rsp.job)
        unless rsp.success
          $scope.reset_status = true
          angular.element('.states .message').css 'opacity', 1
          angular.element('.states .message .text').text rsp.message
          $timeout((-> angular.element('.states .message').css 'opacity', 0), 2000)

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

  $scope.abs = (num) -> Math.abs num

  $scope.update_extras = ->
    $http.post($window.location.href + '/update_extras', extras: $scope.extra).success (rsp) ->
      if rsp.success
        $scope.job.booking.extra_king_sets     = rsp.extra_king_sets
        $scope.job.booking.extra_twin_sets     = rsp.extra_twin_sets
        $scope.job.booking.extra_toiletry_sets = rsp.extra_toiletry_sets
        $scope.job.king_bed_count              = rsp.king_beds
        $scope.job.twin_bed_count              = rsp.twin_beds
        $scope.job.toiletry_count              = rsp.toiletries
        $scope.refresh_invoice()
        ngDialog.closeAll()

  $scope.update_instructions = ->
    $http.post($window.location.href + '/update_instructions', extras: $scope.extra).success (rsp) ->
      if rsp.success
        $scope.job.booking.extra_instructions = rsp.extra_instructions
        ngDialog.closeAll()

  $scope.edit_extras_modal = -> ngDialog.open template: 'edit-extras-modal', className: 'extras info full', scope: $scope
  $scope.edit_instructions_modal = -> ngDialog.open template: 'edit-instructions-modal', className: 'extras info full', scope: $scope

  $scope.cancel_process = -> ngDialog.closeAll()

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
    $scope.extra = { king_sets: rsp.booking.extra_king_sets, twin_sets: rsp.booking.extra_twin_sets, toiletry_sets: rsp.booking.extra_toiletry_sets, instructions: rsp.booking.extra_instructions }
    $scope.job = rsp
    $scope.job.contractor_count = $scope.job.contractors.length
    $scope.job.date_text = moment(rsp.date, 'YYYY-MM-DD').format 'ddd, MMM D'
    $scope.job.standard_services = _(rsp.booking.services).reject (s) -> s.extra
    $scope.job.extra_services    = _(rsp.booking.services).filter (s) -> s.extra
    $scope.job.contractors = _($scope.job.payouts).map((payout) -> payout.user) if $scope.job.status_cd == 6

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
