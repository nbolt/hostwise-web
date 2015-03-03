FirstPropertyCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.submit = ->
    if validate()
      $http.get('/data/service_available', {params: {zip: $scope.zip}}).success (rsp) ->
        if rsp
          window.location = '/properties/new?zip=' + encodeURIComponent($scope.zip)
        else
          angular.element('.first-property form .section.notify').slideDown 600
          $http.post('/service_notifications/create', { zip: $scope.zip })
    else
      flash 'failure', 'Please fill in all required fields'

  $scope.cancel = ->
    hide_notification()
    return true

  $scope.notify = ->
    $http.post('/service_notifications/create', { zip: $scope.zip }).success (rsp) ->
      hide_notification()
    return true

  hide_notification = ->
    angular.element('.first-property form .section.notify').slideUp 600

  validate = ->
    return !(_(angular.element('.first-property form').find('input[required]')).filter((el) -> angular.element(el).val() == '')[0])

  flash = (type, msg) ->
    el = angular.element('.first-property form .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

]

app = angular.module('porter').controller('first_property', FirstPropertyCtrl)
