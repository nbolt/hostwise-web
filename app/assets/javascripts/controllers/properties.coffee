PropertyHomeCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  $scope.form = {}
  $scope.filter = {id:'alphabetical',text:'Alphabetical'}
  $scope.sort = 'alphabetical'
  $scope.term = ''

  promise = null

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
              angular.element(".booking.modal .calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive').attr('booking', booking.id)
            else
              $timeout((->
                angular.element(".booking.modal .calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive').attr('booking', booking.id)
              ),100)
    }

  $scope.$watch 'search', (n,o) -> if o
    $timeout.cancel promise
    promise = $timeout (->
      $scope.term = n
      refresh_properties()
    ), 400

  $scope.$watch 'filter', (n,o) -> if o
    $scope.sort = n.id
    refresh_properties()

  $scope.page_changed = (n) ->
    angular.element('body, html').animate
      scrollTop: 0
    , 'fast'
    return true

  $scope.filters = ->
    {
      dropdownCssClass: 'filters'
      minimumResultsForSearch: 8
      data: [{id:'alphabetical',text:'Alphabetical'},{id:'recently_added',text:'Recently Added'},{id:'upcoming_service',text:'Upcoming Service'},{id:'deactivated',text:'Deactivated'}]
      initSelection: (el, cb) ->
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

  $scope.exists = () ->
    if $scope.property.bookings
      _($scope.property.bookings).find (b) -> b.id.toString() == $scope.selected_booking

  refresh_properties = ->
    $http.get('/data/properties', {params: {term: $scope.term, sort: $scope.sort}}).success (rsp) -> $scope.user.properties = rsp if $scope.user

]

app = angular.module('porter').controller('properties', PropertyHomeCtrl)
