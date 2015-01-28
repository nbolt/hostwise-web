AvailabilityCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.form = {}

  $scope.init = ->
    $http.get(window.location.href + '.json').success (rsp) ->
      if rsp.availability
        $scope.form = {
          mon: rsp.availability.mon,
          tues: rsp.availability.tues,
          wed: rsp.availability.wed,
          thurs: rsp.availability.thurs,
          fri: rsp.availability.fri,
          sat: rsp.availability.sat,
          sun: rsp.availability.sun
        }
        $scope.change('mon') if rsp.availability.mon
        $scope.change('tues') if rsp.availability.tues
        $scope.change('wed') if rsp.availability.wed
        $scope.change('thurs') if rsp.availability.thurs
        $scope.change('fri') if rsp.availability.fri
        $scope.change('sat') if rsp.availability.sat
        $scope.change('sun') if rsp.availability.sun

  $scope.save = ->
    $http.post('/availability/add', {
      form: $scope.form
    }).success (rsp) ->
      if rsp.success
        flash 'info', 'Your changes have been saved!'
      else
        flash 'failure', rsp.message

  $scope.change = (id) ->
    lbl = angular.element('.availability-container form label[for=' + id + ']')
    if lbl.hasClass('checked')
      lbl.removeClass('checked')
    else
      lbl.addClass('checked')
    return true

  flash = (type, msg) ->
    el = angular.element('.availability-container form .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

]

app = angular.module('porter').controller('availability', AvailabilityCtrl)
