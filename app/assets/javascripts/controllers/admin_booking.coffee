AdminBookingCtrl = ['$scope', '$http', '$timeout', '$interval', '$q', '$window', ($scope, $http, $timeout, $interval, $q, $window) ->

  $scope.bookingQ = $q.defer()

  $http.get($window.location.href + '.json').success (rsp) ->
    $scope.booking = rsp
    $scope.booking.standard_services = _(rsp.services).reject (s) -> s.extra
    $scope.booking.extra_services    = _(rsp.services).filter (s) -> s.extra
    $timeout -> $scope.bookingQ.resolve()

    load_mapbox = null
    load_mapbox = $interval((->
      if $window.loaded_mapbox
        $interval.cancel(load_mapbox)
        map = L.mapbox.map 'map', 'useporter.l02en9o9'
        map.dragging.disable(); map.touchZoom.disable(); map.doubleClickZoom.disable(); map.scrollWheelZoom.disable()
        geocoder = L.mapbox.geocoder 'mapbox.places'
        geocoder.query $scope.booking.property.full_address, (err, data) ->
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

app = angular.module('porter').controller('admin_booking', AdminBookingCtrl)
