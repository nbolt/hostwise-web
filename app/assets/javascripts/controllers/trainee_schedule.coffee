TraineeScheduleCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  $scope.done = (job) ->
    $http.post("/jobs/#{job.id}/complete").success (rsp) ->
      angular.element('.distribution .bottom').css 'max-height', 0

  $scope.jobs_completed = (training) ->
    unfinished = _(training.jobs).reject (job) -> job.status_cd == 3
    if unfinished[0]
      false
    else
      true

  $scope.next_payout = ->
    moment().weekday(3).add(1, 'weeks').format('ddd, MMM D')

  $scope.pricing_class = (job) ->
    if job.staging
      'staging'
    else if job.state_cd is 1
      'vip'
    else
      ''

]

app = angular.module('porter').controller('trainee_schedule', TraineeScheduleCtrl)
