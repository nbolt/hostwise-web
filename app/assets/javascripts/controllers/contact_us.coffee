ContactUsCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.posting = false
  $scope.form = {}

  $scope.submit = ->
    $http.post('', {
      form: $scope.form
    }).success (rsp) ->
      if rsp.success
        flash('info', 'Thanks for contacting us. We will get back to us shortly.')
      else
        flash('failure', rsp.message)

  flash = (type, msg) ->
    el = angular.element('.signin .flash, .signup .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

]

app = angular.module('porter').controller('contact_us', ContactUsCtrl)
