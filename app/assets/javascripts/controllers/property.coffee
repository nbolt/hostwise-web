PropertyCtrl = ['$scope', '$http', '$window', '$timeout', ($scope, $http, $window, $timeout) ->

  $scope.form = {}

  $http.get($window.location.href + '.json').success (rsp) ->
    $scope.property = rsp
    _($scope.property.bookings).each (booking) ->
      booking.parsed_date = moment.utc(booking.date).format('MMMM Do, YYYY')
    bedrooms_text = if rsp.bedrooms == 0 then 'None' else if rsp.bedrooms == 1 then 'Bedroom' else 'Bedrooms'
    $scope.form.bedrooms = { id: rsp.bedrooms.toString(), text: "#{rsp.bedrooms} #{bedrooms_text}" }
    beds_text = if rsp.beds == 0 then 'None' else if rsp.beds == 1 then 'Bed' else 'Beds'
    $scope.form.beds = { id: rsp.beds.toString(), text: "#{rsp.beds} #{beds_text}" }
    accommodates_text = if rsp.accommodates == 0 then 'None' else if rsp.accommodates == 1 then 'Person' else 'People'
    $scope.form.accommodates = { id: rsp.accommodates.toString(), text: "#{rsp.accommodates} #{accommodates_text}" }

  $scope.tab = (section) ->
    angular.element('#tabs .tab').removeClass('active')
    angular.element('#tab-content .tab').removeClass('active')
    angular.element('#tabs .tab.' + section).addClass('active')
    angular.element('#tab-content .tab.' + section).addClass('active')
    null

  $scope.cancel = (booking) ->
    $http.post($window.location.href + '/cancel', {booking: booking.id}).success (rsp) ->
      if rsp.success
        angular.element("#booking-#{booking.id}").fadeOut()

  $scope.$watch 'form.bedrooms.id', (n,o) -> if o
    $http.post($window.location.href, {form: { bedrooms: n }}).success (rsp) ->
      if rsp.success
        flash('success', 'Changes saved')
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.beds.id', (n,o) -> if o
    $http.post($window.location.href, {form: { beds: n }}).success (rsp) ->
      if rsp.success
        flash('success', 'Changes saved')
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.accommodates.id', (n,o) -> if o
    $http.post($window.location.href, {form: { accommodates: n }}).success (rsp) ->
      if rsp.success
        flash('success', 'Changes saved')
      else
        flash('failure', rsp.message)

  flash = (type, msg) ->
    angular.element('#property .flash').removeClass('success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      angular.element('#property .flash').css('opacity', 0).removeClass('info success failure')
    ), 3000)

  $scope.bedrooms = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: 8
      data: [{id:'0',text:'None'},{id:'1',text:'1 Bedroom'},{id:'2',text:'2 Bedrooms'},{id:'3',text:'3 Bedrooms'},{id:'4',text:'4 Bedrooms'}]
      initSelection: (el, cb) ->
    }

  $scope.beds = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: 8
      data: [{id:'0',text:'None'},{id:'1',text:'1 Bed'},{id:'2',text:'2 Beds'},{id:'3',text:'3 Beds'},{id:'4',text:'4 Beds'}]
      initSelection: (el, cb) ->
    }

  $scope.accommodates = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: 8
      data: [{id:'1',text:'1 Person'},{id:'2',text:'2 People'},{id:'3',text:'3 People'},{id:'4',text:'4 People'}]
      initSelection: (el, cb) ->
    }

]

app = angular.module('porter').controller('property', PropertyCtrl)
