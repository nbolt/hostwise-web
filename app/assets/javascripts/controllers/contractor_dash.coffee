ContractorDashCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  $scope.newbie = -> if !$scope.user then false else if $scope.user.jobs[0] then false else true 

  $scope.today = moment().format 'ddd, MMM D'

  $scope.done = (job) ->
    $http.post("/jobs/#{job.id}/complete").success (rsp) ->
      angular.element('.distribution .bottom').css 'max-height', 0

  $scope.jobs_completed = ->
    unfinished = _($scope.user.jobs_today).reject (job) -> job.status_cd == 3
    if unfinished[0]
      false
    else
      true

]

app = angular.module('porter').controller('contractor_dash', ContractorDashCtrl)
