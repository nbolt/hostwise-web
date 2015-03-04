PropertyHomeCtrl = ['$scope', '$http', '$timeout', '$window', 'ngDialog', ($scope, $http, $timeout, $window, ngDialog) ->

  $scope.form = {}
  $scope.filter = {id:'alphabetical',text:'Alphabetical'}
  $scope.sort = 'alphabetical'
  $scope.term = ''

  promise = null

  $scope.init = ->
    alert 'ok', 'Property added successfully!' if getParam('f') is '1'
    null

  $scope.toProperty = (property) -> $window.location = "/properties/#{property.slug}"

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
              angular.element(".booking.modal .calendar td.active.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive booked').attr('booking', booking.id)
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

  $scope.$watch 'search', (n,o) -> if o
    $timeout.cancel promise
    promise = $timeout (->
      $scope.term = n
      refresh_properties()
    ), 400
    el = angular.element('#search-bar #search .icon-close')
    if n
      el.show()
    else
      el.hide()

  $scope.$watch 'filter', (n,o) -> if o
    $scope.sort = n.id
    refresh_properties()

  $scope.clear = -> $scope.search = ''

  $scope.page_changed = (n) ->
    angular.element('body, html').animate
      scrollTop: 0
    , 'fast'
    return true

  $scope.filters = ->
    {
      dropdownCssClass: 'filters'
      minimumResultsForSearch: -1
      data: [{id:'alphabetical',text:'Alphabetical'},{id:'recently_added',text:'Recently Added'},{id:'upcoming_service',text:'Upcoming Service'},{id:'deactivated',text:'Deactivated'}]
      initSelection: (el, cb) ->
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

  $scope.exists = () ->
    if $scope.property.active_bookings
      _($scope.property.bookings).find (b) -> b.id.toString() == $scope.selected_booking

  $scope.address = (property) ->
    parts = property.full_address.split ','
    return parts[0] + ", <span class='city_state'>" + parts[1] + ", " + parts[2] + "</span>"

  refresh_properties = ->
    $http.get('/data/properties', {params: {term: $scope.term, sort: $scope.sort}}).success (rsp) ->
      if $scope.user
        $scope.user.properties = rsp if $scope.user
        _($scope.user.properties).each (property) ->
          property.next_service_date = moment(property.next_service_date, 'YYYY-MM-DD').format('MM/DD/YY') if property.next_service_date

  getParam = (name) ->
    decodeURIComponent name[1] if name = (new RegExp("[?&]" + encodeURIComponent(name) + "=([^&]*)")).exec(location.search)

  alert = (type, msg) ->
    classes = 'info ok warning bolt exclamation question'
    el = angular.element('#properties .alert')
    el.removeClass(classes).addClass("active #{type}")
    el.find('i').removeClass().addClass("icon-alert-#{type}")
    el.find('.title').text msg
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass(classes + ' active')
    ), 4000)

]

app = angular.module('porter').controller('properties', PropertyHomeCtrl)
