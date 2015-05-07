EditContractorCtrl = ['$scope', '$http', '$timeout', 'ngDialog', 'spinner', ($scope, $http, $timeout, ngDialog, spinner) ->

  url = window.location.href.split('/')
  $scope.id = url[url.length-2]

  $scope.fetch_contractor = ->
    unless $scope.contractor
      spinner.startSpin()
      $http.get(window.location.href + '.json').success (rsp) ->
        $scope.contractor = rsp.contractor
        $scope.contractor.contractor_profile.position = $scope.contractor.contractor_profile.current_position if $scope.contractor.contractor_profile
        $scope.contractor.total_completed_jobs = _($scope.contractor.jobs).filter((job) -> job.status_cd == 3).length
        $scope.contractor.total_cancelled_jobs = _($scope.contractor.jobs).filter((job) -> job.status_cd == 6).length
        $scope.contractor.jobs = _($scope.contractor.jobs).filter (job) -> !job.distribution
        _($scope.contractor.jobs).each (job) ->
          job.service_list = _(_(job.booking.services).map((service) -> service.name)).join ', '
          job.total_kings = job.booking.property.king_bed_count
          job.total_twins = job.booking.property.twin_beds
          job.total_toiletries = job.booking.property.bathrooms
          job.status = switch job.status_cd
            when 0 then 'open'
            when 1 then 'scheduled'
            when 2 then 'in progress'
            when 3 then 'completed'
            when 4 then 'past due'
            when 5 then "can't access"
            when 6 then 'cancelled'
          job.state = switch job.state_cd
            when 0 then 'normal'
            when 1 then 'vip'
            when 2 then 'hidden'

        spinner.stopSpin()
        $timeout((->
          table = angular.element("#example-1").dataTable({
            aLengthMenu: [
              [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
            ]
          })
        ),500)

  $scope.position = ->
    {
    dropdownCssClass: 'details'
    minimumResultsForSearch: -1
    data: [{id:'0',text:'FIRED'},{id:'1',text:'APPLICANT'},{id:'2',text:'CONTRACTOR'},{id:'3',text:'MENTOR'}]
    initSelection: (el, cb) ->
    }

  $scope.update_account = ->
    $http.put("/contractors/#{$scope.id}/update", {
      contractor_profile: _($scope.contractor.contractor_profile).clone(),
      contractor:
        email: $scope.contractor.email
        first_name: $scope.contractor.first_name
        last_name: $scope.contractor.last_name
        phone_number: $scope.contractor.phone_number
        secondary_phone: $scope.contractor.secondary_phone
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
      $scope.contractor = rsp.contractor
      $scope.contractor.contractor_profile.position = $scope.contractor.contractor_profile.current_position if $scope.contractor.contractor_profile
      angular.element('.status .steps').css('margin-left', -360)

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

  $scope.state_class = (job) ->
    switch job.state_cd
      when 0
        'badge-default'
      when 1
        'badge-warning'

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

  $scope.fetch_contractor()

]

app = angular.module('porter').controller('edit-contractor', EditContractorCtrl)
