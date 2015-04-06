EditContractorCtrl = ['$scope', '$http', '$timeout', 'ngDialog', 'spinner', ($scope, $http, $timeout, ngDialog, spinner) ->

  url = window.location.href.split('/')
  $scope.id = url[url.length-2]

  $scope.$on 'fetch_contractor', ->
    $http.get(window.location.href + '.json').success (rsp) ->
      $scope.contractor = rsp
      $scope.contractor.contractor_profile.position = $scope.contractor.contractor_profile.current_position if $scope.contractor.contractor_profile

  $scope.$emit 'fetch_contractor'

  $scope.position = ->
    {
    dropdownCssClass: 'details'
    minimumResultsForSearch: -1
    data: [{id:'0',text:'FIRED'},{id:'1',text:'APPLICANT'},{id:'2',text:'CONTRACTOR'},{id:'3',text:'MENTOR'}]
    initSelection: (el, cb) ->
    }

  $scope.update_account = ->
    $http.put("/contractors/#{$scope.id}/update", {
      contractor: $scope.contractor
    }).success (rsp) ->
      if rsp.success
        spinner.startSpin()
        window.location = window.location.href
      else
        flash 'failure', rsp.message

  $scope.change_status = ->
    $scope.selected_status = angular.element('.position').select2('data')
    $scope.warning = if $scope.contractor.contractor_profile.test_session_completed then '' else 'This applicant has not finished test & tips session.'
    ngDialog.open template: 'change-status-modal', controller: 'edit-contractor', className: 'status full', scope: $scope

  $scope.cancel_status = ->
    ngDialog.closeAll()

  $scope.confirm_status = ->
    $http.put("/contractors/#{$scope.id}/update", {
      contractor: $scope.contractor
      status: $scope.selected_status.text
    }).success (rsp) ->
      if rsp.success
        $scope.$emit 'fetch_contractor'
        angular.element('.status .steps').css('margin-left', -360)
      else
        flash 'failure', rsp.message, true

  $scope.complete_contract = ->
    ngDialog.open template: 'complete-contract-modal', controller: 'edit-contractor', className: 'success full', scope: $scope

  $scope.cancel_contract = ->
    ngDialog.closeAll()

  $scope.confirm_contract = ->
    $http.post("/contractors/#{$scope.id}/complete_contract").success (rsp) ->
      spinner.startSpin()
      window.location = window.location.href

  $scope.open_deactivation = ->
    $scope.current_name = "#{$scope.contractor.first_name}'s"
    ngDialog.open template: 'account-deactivation-modal', controller: 'edit-contractor', className: 'warning full', scope: $scope

  $scope.open_reactivation = ->
    $scope.current_name = "#{$scope.contractor.first_name}'s"
    ngDialog.open template: 'account-reactivation-modal', controller: 'edit-contractor', className: 'warning full', scope: $scope

  $scope.open_deletion = ->
    $scope.current_name = "#{$scope.contractor.first_name}'s"
    ngDialog.open template: 'account-deletion-modal', controller: 'edit-contractor', className: 'warning full', scope: $scope

  $scope.cancel_deactivation = ->
    ngDialog.closeAll()

  $scope.confirm_deactivation = ->
    spinner.startSpin()
    $http.post("/contractors/#{$scope.id}/deactivate").success (rsp) ->
      window.location = window.location.href if rsp.success

  $scope.confirm_reactivation = ->
    spinner.startSpin()
    $http.post("/contractors/#{$scope.id}/reactivate").success (rsp) ->
      window.location = window.location.href if rsp.success

  $scope.confirm_deletion = ->
    spinner.startSpin()
    $http.post("/contractors/#{$scope.id}/delete").success (rsp) ->
      window.location = '/contractors' if rsp.success

  $scope.show_bgc_link = ->
    $scope.contractor and $scope.contractor.contractor_profile and $scope.contractor.contractor_profile.docusign_completed and $scope.contractor.background_check and $scope.contractor.background_check.status_cd != 1 and $scope.contractor.background_check.status_cd != 3

  $scope.approve_bgc_modal = ->
    ngDialog.open template: 'approve-bgc-modal', controller: 'edit-contractor', className: 'success full', scope: $scope

  $scope.deny_bgc_modal = ->
    ngDialog.open template: 'deny-bgc-modal', controller: 'edit-contractor', className: 'warning full', scope: $scope

  $scope.bgc = (status) ->
    $http.post("/contractors/#{$scope.id}/background_check", {status: status}).success (rsp) ->
      spinner.startSpin()
      window.location = window.location.href if rsp.success

  flash = (type, msg, modal) ->
    el = if modal then angular.element('.modal .flash') else angular.element('form .flash')
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

app = angular.module('porter').controller('edit-contractor', EditContractorCtrl)
