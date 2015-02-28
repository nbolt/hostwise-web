JobCtrl = ['$scope', '$http', '$timeout', '$interval', '$window', '$q', 'ngDialog', ($scope, $http, $timeout, $interval, $window, $q, ngDialog) ->

  $scope.jobQ = $q.defer()

  $http.get($window.location.href + '.json').success (rsp) ->
    $scope.job = rsp
    $scope.job.contractor_count = $scope.job.contractors.length
    $scope.job.date_text = moment(rsp.date, 'YYYY-MM-DD').format 'ddd, MMM D'
    $scope.job.standard_services = _(rsp.booking.services).reject (s) -> s.extra
    $scope.job.extra_services = _(rsp.booking.services).filter (s) -> s.extra
    $timeout -> $scope.jobQ.resolve()
    $scope.user_fetched.promise.then -> $scope.job.contractors = _($scope.job.contractors).reject (user) -> user.id == $scope.user.id

    load_mapbox = null
    load_mapbox = $interval((->
      if $window.loaded_mapbox
        $interval.cancel(load_mapbox)
        map = L.mapbox.map 'map', 'useporter.l02en9o9'
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

    $scope.job_status = ->
      if $scope.user
        if $scope.job.status_cd == 3
          'completed'
        else if $scope.job.status_cd == 2
          'in_progress'
        else
          date = moment($scope.job.date, 'YYYY-MM-DD')
          today = date.date() == moment().date() && date.month() == moment().month() && date.year() == moment().year()
          if today
            job = _($scope.user.jobs_today).find (job) -> job.priority == $scope.job.priority - 1
            if job
              if job.status_cd == 3
                'active'
              else
                'blocked'
            else
              'active'
          else
            'blocked'
      else
        'blocked'

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
        job = _($scope.user.jobs_today).find (job) -> job.priority == $scope.job.priority + 1
        if job
          $window.location = "/jobs/#{job.id}"
        else
          $window.location = '/'

]

app = angular.module('porter').controller('job', JobCtrl)
