PropertyCtrl = ['$scope', '$http', '$window', '$timeout', ($scope, $http, $window, $timeout) ->

  $scope.form = {}

  $http.get($window.location.href + '.json').success (rsp) ->
    $scope.property = rsp
    _($scope.property.bookings).each (booking) ->
      booking.parsed_date = moment.utc(booking.date).format('MMMM Do, YYYY')
    bedrooms_text = if rsp.bedrooms == 0 then 'None' else if rsp.bedrooms == 1 then 'Bedroom' else 'Bedrooms'
    $scope.form.bedrooms = { id: rsp.bedrooms.toString(), text: "#{rsp.bedrooms} #{bedrooms_text}" }
    bathrooms_text = if rsp.bathrooms == 0 then 'None' else if rsp.bathrooms == 1 then 'Bath' else 'Bathrooms'
    $scope.form.bathrooms = { id: rsp.bathrooms.toString(), text: "#{rsp.bathrooms} #{bathrooms_text}" }
    twin_beds_text = if rsp.twin_beds == 0 then 'None' else if rsp.twin_beds == 1 then 'Bed' else 'Beds'
    $scope.form.twin_beds = { id: rsp.twin_beds.toString(), text: "#{rsp.twin_beds} #{twin_beds_text}" }
    full_beds_text = if rsp.full_beds == 0 then 'None' else if rsp.full_beds == 1 then 'Bed' else 'Beds'
    $scope.form.full_beds = { id: rsp.full_beds.toString(), text: "#{rsp.full_beds} #{full_beds_text}" }
    queen_beds_text = if rsp.queen_beds == 0 then 'None' else if rsp.queen_beds == 1 then 'Bed' else 'Beds'
    $scope.form.queen_beds = { id: rsp.queen_beds.toString(), text: "#{rsp.queen_beds} #{queen_beds_text}" }
    king_beds_text = if rsp.king_beds == 0 then 'None' else if rsp.king_beds == 1 then 'Bed' else 'Beds'
    $scope.form.king_beds = { id: rsp.king_beds.toString(), text: "#{rsp.king_beds} #{king_beds_text}" }

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

  $scope.$watch 'form.bathrooms.id', (n,o) -> if o
    $http.post($window.location.href, {form: { bathrooms: n }}).success (rsp) ->
      if rsp.success
        flash('success', 'Changes saved')
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.twin_beds.id', (n,o) -> if o
    $http.post($window.location.href, {form: { twin_beds: n }}).success (rsp) ->
      if rsp.success
        flash('success', 'Changes saved')
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.full_beds.id', (n,o) -> if o
    $http.post($window.location.href, {form: { full_beds: n }}).success (rsp) ->
      if rsp.success
        flash('success', 'Changes saved')
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.queen_beds.id', (n,o) -> if o
    $http.post($window.location.href, {form: { queen_beds: n }}).success (rsp) ->
      if rsp.success
        flash('success', 'Changes saved')
      else
        flash('failure', rsp.message)

  $scope.$watch 'form.king_beds.id', (n,o) -> if o
    $http.post($window.location.href, {form: { king_beds: n }}).success (rsp) ->
      if rsp.success
        flash('success', 'Changes saved')
      else
        flash('failure', rsp.message)

  flash = (type, msg) ->
    angular.element('#property .flash').removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      angular.element('#property .flash').css('opacity', 0).removeClass('info success failure')
    ), 3000)
    $timeout((->
      angular.element('#property .flash').removeClass('info success failure')
    ), 4000)

  $scope.rooms = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: 8
      data: [{id:'0',text:'None'},{id:'1',text:'1'},{id:'2',text:'2'},{id:'3',text:'3'},{id:'4',text:'4'},{id:'5',text:'5'},{id:'6',text:'6'},{id:'7',text:'7'},{id:'8',text:'8'},{id:'9',text:'9'},{id:'10',text:'10'}]
      initSelection: (el, cb) ->
    }

  $scope.beds = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: 8
      data: [{id:'0',text:'None'},{id:'1',text:'1'},{id:'2',text:'2'},{id:'3',text:'3'},{id:'4',text:'4'},{id:'5',text:'5'},{id:'6',text:'6'},{id:'7',text:'7'},{id:'8',text:'8'},{id:'9',text:'9'},{id:'10',text:'10'}]
      initSelection: (el, cb) ->
    }

]

app = angular.module('porter').controller('property', PropertyCtrl)
