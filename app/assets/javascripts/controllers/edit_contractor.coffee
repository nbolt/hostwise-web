EditContractorCtrl = ['$scope', '$http', '$timeout', '$window', 'ngDialog', 'spinner', ($scope, $http, $timeout, $window, ngDialog, spinner) ->

  url = $window.location.href.split('/')
  $scope.id = url[url.length-2]

  $scope.payment_modal = -> ngDialog.open template: 'transfer-modal', className: 'info full', scope: $scope

  $scope.send_payment = ->
    spinner.startSpin()
    $http.post("/hosts/#{$scope.contractor.id}/transfer", {amount: $scope.amount, reason: $scope.reason}).success (rsp) ->
      $scope.amount = null
      $scope.reason = null
      $scope.cancel_status()
      spinner.stopSpin()

  $scope.show_times = (job) ->
    offset = angular.element("#job-#{job.id} .line.edit").position()
    $scope.chosen_job = job
    $http.post("/jobs/#{job.id}/available_times").success (rsp) ->
      $scope.times = rsp.times
      angular.element('#times').css('top', offset.top).css('left', offset.left).css 'opacity', 1

  $scope.choose_time = (time) ->
    $http.post("/jobs/#{$scope.chosen_job.id}/edit_time", {contractor_id: $scope.contractor.id, time: time}).success (rsp) ->
      angular.element('#times').css('top', 0).css('left', 0).css 'opacity', 0
      $scope.times = {}
      if rsp.meta.success
        date = moment($scope.chosen_job.date).format('dddd, MMMM Do')
        day = _($scope.contractor.days).find (a) -> a[0] == date
        day[1] = rsp.jobs

  $scope.fetch_contractor = ->
    unless $scope.contractor
      spinner.startSpin()
      $http.get("/contractors/#{$scope.id}/edit.json").success (rsp) ->
        spinner.stopSpin()
        $scope.markets = rsp.meta.markets
        $scope.contractor = rsp.contractor
        $scope.contractor.contractor_profile.position = $scope.contractor.contractor_profile.current_position if $scope.contractor.contractor_profile
        $scope.contractor.total_completed_jobs = _($scope.contractor.jobs).filter((job) -> job.status_cd == 3).length
        $scope.contractor.total_cancelled_jobs = _($scope.contractor.jobs).filter((job) -> job.status_cd == 6).length
        $scope.contractor.jobs = _($scope.contractor.jobs).filter (job) -> !job.distribution || job.occasion_cd == 0
        _($scope.contractor.jobs).each (job) ->
          unless job.distribution
            job.service_list = job.booking.service_list
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
        $scope.contractor.days = _(_(_($scope.contractor.jobs).groupBy((job) -> job.date)).map((jobs, date) -> [date, jobs])).sortBy (day) -> -day[0]
        $scope.contractor.days = _($scope.contractor.days).map (day) -> [moment(day[0]).format('dddd, MMMM Do'), _(day[1]).sortBy (job) -> _(job.contractor_jobs).find((cj) -> cj.user_id == $scope.contractor.id && cj.job_id == job.id).priority]
        _($scope.contractor.days).each (day) -> [day[0], _(day[1]).each (job) -> job.payout = _(job.payouts).find((payout) -> payout.user_id == $scope.contractor.id)]
        $scope.contractor.days = _($scope.contractor.days).map (day, i) -> [day[0], day[1], {
          id: i
          job_count: _(day[1]).filter((job) -> !job.distribution).length
        }]
        $scope.contractor.days = _($scope.contractor.days).sortBy (day) -> moment(day[0], 'dddd, MMMM Do')
        $timeout((->
          job = $("#job-#{window.location.hash[1..-1]}")
          $.scrollTo(job, 400) if window.location.hash != ''
          job.click()
        ),50)

  $scope.open_day = (day) ->
    angular.element('.day').removeClass 'active'
    angular.element("#day-#{day[2].id}").addClass 'active'
    angular.element('#times').css('top', 0).css('left', 0).css 'opacity', 0
    $scope.times = {}

  $scope.position = ->
    {
    dropdownCssClass: 'details'
    minimumResultsForSearch: -1
    data: [{id:'0',text:'FIRED'},{id:'1',text:'APPLICANT'},{id:'2',text:'CONTRACTOR'},{id:'3',text:'MENTOR'}]
    initSelection: (el, cb) ->
    }

  $scope.marketHash = ->
    {
    dropdownCssClass: 'details'
    minimumResultsForSearch: -1
    data: -> { results: _($scope.markets).map (market) -> { id: market.id, text: market.name } },
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

  $scope.change_market = ->
    $scope.selected_market = angular.element('.market').select2('data')
    ngDialog.open template: 'change-market-modal', controller: 'edit-contractor', className: 'status full', scope: $scope

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

  $scope.confirm_market = ->
    $http.put("/contractors/#{$scope.id}/update", {
      contractor: $scope.contractor
      market: $scope.selected_market.id
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
