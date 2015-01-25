ContractorSignUpCtrl = ['$scope', '$http', '$timeout', '$upload', ($scope, $http, $timeout, $upload) ->

  $scope.contractor_profile = {}
  $scope.bank = {}
  $scope.files = []

  url = window.location.href.split('/')
  $scope.token = url[url.length-2]

  $scope.setup_account = ->
    if validate(1)
      if $scope.user.tos == 'yes'
        $http.put('/users/' + $scope.token + '/activated', {
          user: $scope.user
          contractor_profile: $scope.contractor_profile
        }).success (rsp) ->
          if rsp.success
            scroll 0
            angular.element('.steps').css('margin-left', -900)
          else
            flash 'failure', rsp.message
      else
        flash 'failure', 'Please accept our terms & conditions'
    else
      flash 'failure', 'Please fill in all required fields'

  $scope.add_bank_account = ->
    if validate(2)
      balanced.bankAccount.create $scope.bank, (rsp) ->
        if rsp.status_code != 201
          flash 'failure', rsp.errors[0].description
        else
          $http.post('/payments/add',{balanced_id:rsp.bank_accounts[0].id}).success (rsp) ->
            window.location = '/jobs' if rsp.success
    else
      flash 'failure', 'Please fill in all required fields'

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
          flash 'failure', rsp.message
      )

  validate = (step) ->
    cls = (if step is 1 then '.step.one form' else '.step.two form')
    return !(_(angular.element(cls).find('input[required]')).filter((el) -> angular.element(el).val() == '')[0])

  flash = (type, msg) ->
    el = angular.element('form .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    scroll 0
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

  scroll = (position) ->
    angular.element('body, html').animate
      scrollTop: position
    , 'fast'

]

app = angular.module('porter').controller('contractor-signup', ContractorSignUpCtrl)
