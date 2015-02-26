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

]

app = angular.module('porter').controller('trainee_schedule', TraineeScheduleCtrl)
