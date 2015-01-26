HelpCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.form = {}

  $scope.send = ->
    $http.post('/message', {
      form: $scope.form
    }).success (rsp) ->
      if rsp.success
        $scope.form.message = ''
        flash('info', 'Thanks for contacting us. We will get back to us shortly.')
      else
        flash('failure', rsp.message)

  $scope.chat = ->
    angular.element('.zopim').first().toggle()
    angular.element('.zopim').last().toggle()
    return true

  flash = (type, msg) ->
    el = angular.element('form .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

]

app = angular.module('porter').controller('help', HelpCtrl)
