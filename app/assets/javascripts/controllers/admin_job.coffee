AdminJobCtrl = ['$scope', '$http', '$timeout', '$interval', '$q', '$window', ($scope, $http, $timeout, $interval, $q, $window) ->

  $scope.jobQ = $q.defer()

  $http.get($window.location.href + '.json').success (rsp) ->
    $scope.job = rsp
    $scope.job.contractor_count = $scope.job.contractors.length
    $scope.job.date_text = moment(rsp.date, 'YYYY-MM-DD').format 'ddd, MMM D'
    $scope.job.standard_services = _(rsp.booking.services).reject (s) -> s.extra
    $scope.job.extra_services    = _(rsp.booking.services).filter (s) -> s.extra
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

]

app = angular.module('porter').controller('admin_job', AdminJobCtrl)
