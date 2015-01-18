FirstPropertyCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.form = {}

  $scope.submit = ->
    if validate()
      $http.post('/properties/address', {
        form: $scope.form
      }).success (rsp) ->
        if rsp.success
          window.location = '/properties/new?zip=' + encodeURIComponent($scope.form.zip) + '&address1=' + encodeURIComponent($scope.form.address1)
        else
          flash('failure', rsp.message)
    else
      flash('failure', 'Please fill in all required fields')

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
