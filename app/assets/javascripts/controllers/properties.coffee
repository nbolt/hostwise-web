PropertyHomeCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  $scope.form = {}
  $scope.selected_date = {}
  $scope.payment = {}
  $scope.selected_services = {cleaning:false,linens:false,restocking:false}
  $scope.selected_booking = null

  $scope.filter = {id:'alphabetical',text:'Alphabetical'}
  $scope.sort = 'alphabetical'
  $scope.term = ''

  promise = null

  $scope.calendar_options =
    {
      selectable: true
      clickable: false
      selected_class: 'booked'
      disable_past: true
      onchange: () ->
        if $scope.property
          _($scope.property.bookings).each (booking) ->
            date = moment.utc(booking.date)
            angular.element("#calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").addClass('booked').attr('booking', booking.id)

      onclick: ($this) ->
        date = moment.utc "#{$this.attr 'year'} #{$this.attr 'day'} #{parseInt($this.attr 'month')+1}", 'YYYY D MM'
        $scope.selected_date.moment = date
        $scope.selected_date.num = date.day()
        $scope.selected_date.day_text = date.format('dddd,')
        $scope.selected_date.date_text = date.format('MMM Do')
        $scope.selected_booking = $this.attr('booking')
        $scope.selected_services = {cleaning:false,linens:false,restocking:false}
        if $scope.selected_booking
          $http.get("/properties/#{$scope.property.slug}/#{$scope.selected_booking}/show").success (rsp) ->
            payment_type = if rsp.payment.stripe_id then 'Card' else 'Bank'
            $scope.payment.id = rsp.payment.id
            $scope.payment.text = "#{payment_type} ending in #{rsp.payment.last4}"
            _(rsp.services).each (service) ->
              $scope.selected_services[service.name] = true
              angular.element(".booking.modal .services .service.#{service.name}").addClass 'active'
              angular.element(".booking.modal .services .service.#{service.name} input").attr 'checked', true
        $timeout(->
          angular.element('.booking.modal .content-container').css 'margin-left', -400
          $timeout((->
            angular.element('.booking.modal .content-container').css 'transition', 'none'
            angular.element('.booking.modal .content-container').css 'margin-left', 0
            angular.element('.booking.modal .content.side').removeClass 'active'
            $timeout((->angular.element('.booking.modal .content-container').css 'transition', 'margin-left .5s ease-in-out'),100)
          ), 500)
        )
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
      data: [{id:'alphabetical',text:'Alphabetical'},{id:'recently_added',text:'Recently Added'},{id:'upcoming_service',text:'Upcoming Service'}]
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
        console.log booking
        date = moment.utc booking.date
        booking.parsed_date = date.format('MMMM Do, YYYY')
        angular.element("#calendar td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").addClass('booked').attr('booking', booking.id)

  $scope.exists = () ->
    _(_(_(_($scope.user.properties).map((p) -> p.bookings)).flatten())).find (b) -> b.id.toString() == $scope.selected_booking

  refresh_properties = ->
    $http.get('/data/properties', {params: {term: $scope.term, sort: $scope.sort}}).success (rsp) -> $scope.user.properties = rsp if $scope.user

]

app = angular.module('porter').controller('properties', PropertyHomeCtrl)
