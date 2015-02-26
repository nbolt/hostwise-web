PropertySearchCtrl = ['$scope', '$http', '$timeout', '$window', 'ngDialog', ($scope, $http, $timeout, $window, ngDialog) ->

  $scope.$watch 'property_search', (n,o) -> if o
    $timeout.cancel promise
    promise = $timeout (->
      $http.get('/data/properties', {params: {term: $scope.property_search}}).success (rsp) -> $scope.user.properties = rsp
    ), 400
    el = angular.element('.search .icon-close')
    if n
      el.show()
    else
      el.hide()

  $scope.clear = -> $scope.property_search = ''

  $scope.modal_calendar_options =
  {
    selectable: true
    clickable: true
    disable_past: true
    onchange: () ->
      if $scope.property
        _($scope.property.bookings).each (booking) ->
          date = moment.utc(booking.date)
          if $('.booking.modal')[0]
            angular.element(".booking.modal .calendar td.active.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive').attr('booking', booking.id)
          else
            $timeout((->
              angular.element(".booking.modal .calendar td.active.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive').attr('booking', booking.id)
            ),100)
  }

  $scope.quick_add = (property) ->
    ngDialog.open template: 'booking-modal', className: 'booking', scope: $scope
    $scope.property = property

    $timeout((->
      angular.element('.booking.modal .content.side').removeClass 'active'
      angular.element('.booking.modal .content.side.calendar').addClass 'active'
    ),100)

    $http.get("/properties/#{property.slug}.json").success (rsp) ->
      $scope.property = rsp
      _($scope.property.bookings).each (booking) ->
        date = moment.utc booking.date
        booking.parsed_date = date.format('MMMM Do, YYYY')
        angular.element(".booking.modal .calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").addClass('booked').attr('booking', booking.id)

]

app = angular.module('porter').controller('property_search', PropertySearchCtrl)
