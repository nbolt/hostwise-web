ContractorSignUpCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.contractor_profile = {}

  $scope.setup_account = ->
    if validate()
      url = window.location.href.split('/')
      token = url[url.length-2]
      $http.put('/users/' + token + '/activated', {
        user: $scope.user
        contractor_profile: $scope.contractor_profile
      }).success (rsp) ->
        if rsp.success
          window.location = rsp.redirect_to
        else
          flash('failure', rsp.message)
    else
      flash('failure', 'Please fill in all required fields')

  validate = ->
    return !(_(angular.element('form').find('input[required]')).filter((el) -> angular.element(el).val() == '')[0])

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

app = angular.module('porter').controller('contractor-signup', ContractorSignUpCtrl)
