ContractorSignUpCtrl = ['$scope', '$http', '$timeout', '$upload', ($scope, $http, $timeout, $upload) ->

  $scope.contractor_profile = {}
  $scope.files = []

  url = window.location.href.split('/')
  $scope.token = url[url.length-2]

  $scope.setup_account = ->
    if validate()
      $http.put('/users/' + $scope.token + '/activated', {
        user: $scope.user
        contractor_profile: $scope.contractor_profile
      }).success (rsp) ->
        if rsp.success
          window.location = rsp.redirect_to
        else
          flash('failure', rsp.message)
    else
      flash('failure', 'Please fill in all required fields')

  $scope.$watch 'files', ->
    if $scope.files.length
      file = $scope.files[0]
      $scope.upload = $upload.upload(
        url: '/users/' + $scope.token + '/avatar'
        data:
          step: 'photo'
        method: 'PUT'
        file: file
      ).success((rsp, status, headers, config) ->
        if rsp.success
          window.location = window.location.href
        else
          flash('failure', rsp.message)
      )

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
