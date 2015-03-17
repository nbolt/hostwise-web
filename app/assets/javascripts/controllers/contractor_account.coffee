ContractorAccountCtrl = ['$scope', '$http', '$timeout', '$upload', 'ngDialog', 'spinner', ($scope, $http, $timeout, $upload, ngDialog, spinner) ->

  $scope.contractor_profile = {}
  $scope.files = []

  url = window.location.href.split('/')
  $scope.token = url[url.length-2]

  $scope.setup_account = ->
    if validate(1)
      if $scope.user.tos == 'yes'
        $http.put('/users/' + $scope.token + '/activated', {
          user: $scope.user
          contractor_profile: $scope.contractor_profile
          spinner: true
        }).success (rsp) ->
          if rsp.success
            spinner.startSpin()
            send_contract()
            submit_background_check()
            spinner.stopSpin()
            scroll 0
            goto 'two'
          else
            flash 'failure', rsp.message
      else
        flash 'failure', 'Please accept our terms & conditions'
    else
      flash 'failure', 'Please fill in all required fields'

  $scope.update_account = (step) ->
    $http.put('/user/update', {
      user: $scope.user
      step: step
    }).success (rsp) ->
      if rsp.success
        message = 'Your profile'
        if step is 'password'
          message = 'Password'
          $scope.user.password = ''
          $scope.user.password_confirmation = ''
          $scope.user.current_password = ''
        message += ' updated successfully!'
        flash 'info', message
      else
        flash 'failure', rsp.message

  $scope.skip = ->
    spinner.startSpin()
    window.location = '/jobs'

  $scope.setup_availability = ->
    $http.post('/availability/add', {
      form: $scope.form
    }).success (rsp) ->
      if rsp.success
        goto 'three'
      else
        flash 'failure', rsp.message

  $scope.change = (id) ->
    lbl = angular.element('.availability-container form label[for=' + id + ']')
    if lbl.hasClass('checked')
      lbl.removeClass('checked')
    else
      lbl.addClass('checked')
    return true

  $scope.open_deactivation = ->
    ngDialog.open template: 'account-deactivation-modal', controller: 'account', className: 'warning full', scope: $scope

  $scope.$watch 'files', ->
    if $scope.files.length
      file = $scope.files[0]
      post_url = if activation() then '/users/' + $scope.token + '/avatar' else '/user/update'
      $scope.upload = $upload.upload(
        url: post_url
        data:
          step: 'photo'
        method: 'PUT'
        file: file
      ).success((rsp, status, headers, config) ->
        if rsp.success
          spinner.startSpin()
          window.location = window.location.href
        else
          flash 'failure', rsp.message
      )

  submit_background_check = ->
    $http.post('/background_checks').success (rsp) ->

  send_contract = ->
    $http.post('/docusign/send').success (rsp) ->

  activation = ->
    return angular.element('.activate').length

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

  goto = (step) ->
    el_step = angular.element(".contractor-account.activate .steps .step.#{step}")
    el = angular.element('.contractor-account.activate .steps .step')
    $timeout((->
      el.css 'display', 'none'
      el_step.css 'display', 'block'
      el.removeClass('active')
      $timeout((->el_step.addClass('active')),50)
    ), 400)

  scroll = (position) ->
    angular.element('body, html').animate
      scrollTop: position
    , 'fast'

]

app = angular.module('porter').controller('contractor-account', ContractorAccountCtrl)
