ContractorDashCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  $scope.today = moment().format 'ddd, MMM D'

  $scope.done = (job) ->
    $http.post("/jobs/#{job.id}/complete").success (rsp) ->
      angular.element('.distribution .bottom').css 'max-height', 0

  $scope.pricing_class = (job) ->
    if job.staging
      'staging'
    else if job.state_cd is 1
      'vip'
    else
      ''

  $scope.job_class = (job) ->
    switch job.status_cd
      when 3 then 'complete'
      when 5 then 'couldnt_access'

  $scope.jobs_completed = ->
    if $scope.user && $scope.user.jobs_today
      if $scope.user.jobs_today[0]
        unfinished = _($scope.user.jobs_today).reject (job) -> job.status_cd == 3
        if unfinished[0]
          false
        else
          true
      else
        false
    else
      false

  $scope.next_payout = ->
    wed = moment().weekday(3)
    wed = wed.add(1, 'weeks') if moment().day() > 3
    wed.format('ddd, MMM D')

  $scope.goto = (job_id) ->
    window.location = "/jobs/#{job_id}"

]

app = angular.module('porter').controller('contractor_dash', ContractorDashCtrl)
