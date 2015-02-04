JobCtrl = ['$scope', '$http', '$timeout', '$interval', '$window', 'ngDialog', ($scope, $http, $timeout, $interval, $window, ngDialog) ->

  $http.get($window.location.href + '.json').success (rsp) ->
    $scope.job = rsp
    $scope.job.date = moment(rsp.booking.date, 'YYYY-MM-DD').format 'ddd, MMM D'

    load_mapbox = null
    load_mapbox = $interval((->
      if $window.loaded_mapbox
        $interval.cancel(load_mapbox)
        map = L.mapbox.map 'map', 'useporter.l02en9o9'
        geocoder = L.mapbox.geocoder 'mapbox.places'
        geocoder.query $scope.job.booking.property.full_address, (err, data) ->
          if data.latlng
            console.log data
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

app = angular.module('porter').controller('job', JobCtrl)
