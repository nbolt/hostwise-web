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
        _($scope.property.active_bookings).each (booking) ->
          date = moment.utc(booking.date)
          if $('.booking.modal')[0]
            angular.element(".booking.modal .calendar td.active.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive').attr('booking', booking.id)
          else
            $timeout((->
              angular.element(".booking.modal .calendar td.active.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive').attr('booking', booking.id)
            ),100)

    onclick: ($this) ->
      return if $this.hasClass('chosen')
      $scope.selected_date = moment.utc "#{$this.attr 'year'} #{$this.attr 'day'} #{parseInt($this.attr 'month')}", 'YYYY D MM'
      days_diff = $scope.selected_date.diff(moment.utc().startOf('day'), 'days')
      hour = moment().hours()
      minute = moment().minutes()
      if days_diff == 0 and hour <= 14 and minute <= 59 #same day booking before 3pm
        $scope.$broadcast 'same_day_confirmation'
      else if days_diff == 1 and hour >= 22 #next day booking after 10pm
        $scope.$broadcast 'next_day_confirmation'
  }

  $scope.quick_add = (property) ->
    ngDialog.open template: 'booking-modal', className: 'booking', scope: $scope, closeByDocument: false
    $scope.property = property

    $timeout((->
      angular.element('.booking.modal .content.side').removeClass 'active'
      angular.element('.booking.modal .content.side.calendar').addClass 'active'
      $scope.$broadcast 'booking_selection'
    ),100)

    $http.get("/properties/#{property.slug}.json").success (rsp) ->
      $scope.property = rsp
      _($scope.property.active_bookings).each (booking) ->
        date = moment.utc booking.date
        booking.parsed_date = date.format('MMMM Do, YYYY')
        angular.element(".booking.modal .calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive').addClass('booked').attr('booking', booking.id)

]

app = angular.module('porter').controller('property_search', PropertySearchCtrl)
