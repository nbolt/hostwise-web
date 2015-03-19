ContractorDashCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  $scope.newbie = -> if !$scope.user then false else if $scope.user.jobs[0] then false else true

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
    moment().weekday(3).add(1, 'weeks').format('ddd, MMM D')

]

app = angular.module('porter').controller('contractor_dash', ContractorDashCtrl)
