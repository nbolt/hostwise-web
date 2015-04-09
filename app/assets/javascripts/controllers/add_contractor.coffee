AddContractorCtrl = ['$scope', '$http', '$timeout', 'ngDialog', 'spinner', ($scope, $http, $timeout, ngDialog, spinner) ->

  $scope.form = {email: '', first_name: '', last_name: '', phone_number: ''}

  $scope.add_contractor = ->
    spinner.startSpin()
    $http.post('/contractors/signup', {
      form: $scope.form
    }).success (rsp) ->
      if rsp.success
        window.location = window.location.href
      else
        spinner.stopSpin()
        flash('failure', rsp.message)

  flash = (type, msg) ->
    el = angular.element('.default.modal .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

]

app = angular.module('porter').controller('add-contractor', AddContractorCtrl)
