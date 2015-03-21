DistributionJobCtrl = ['$scope', '$http', '$timeout', '$interval', '$window', '$q', '$upload', 'ngDialog', ($scope, $http, $timeout, $interval, $window, $q, $upload, ngDialog) ->

  $scope.jobQ = $q.defer()
  $scope.job_status = 'blocked'

  $http.get($window.location.href + '.json').success (rsp) ->
    $scope.job = rsp
    $scope.next_job = rsp.next_job.id if rsp.next_job
    $scope.job.contractor_count = $scope.job.contractors.length
    $scope.job.date_text = moment(rsp.date, 'YYYY-MM-DD').format 'ddd, MMM D'
    $scope.job.date_text_2 = moment(rsp.date, 'YYYY-MM-DD').format 'MMMM Do, YYYY'
    $timeout -> $scope.jobQ.resolve()
    $scope.user_fetched.promise.then -> $scope.job.contractors = _($scope.job.contractors).reject (user) -> user.id == $scope.user.id

    $http.get($window.location.href + '/status').success (rsp) ->
      $scope.job.status = rsp.status
      $scope.job.blocker = rsp.blocker

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
        geocoder.query $scope.job.distribution_center.full_address, (err, data) ->
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


  $scope.done = ->
    if $scope.job.status != 'blocked'
      $http.post($window.location.href + '/done').success (rsp) ->
        if rsp.next_job
          $window.location = '/jobs/' + rsp.next_job
        else
          $window.location = '/'

]

app = angular.module('porter').controller('distribution_job', DistributionJobCtrl)