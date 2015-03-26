TraineeDashCtrl = ['$scope', '$http', '$window', ($scope, $http, $window) ->

  $scope.dates = []

  $http.get('/trainee/available_jobs').success (rsp) ->
    _(rsp).each (job) ->
      date = {}
      date.job = job.id
      date.moment = moment.utc job.date
      date.day = date.moment.format 'D'
      date.month = date.moment.format 'MMM'
      date.time = '9:30 AM'
      date.selected = false
      $scope.dates.push date

  $http.get('/trainee/bgc').success (rsp) -> $scope.bgc = rsp

  $scope.num_dates = -> 2 - $scope.selected_dates().length - ($scope.user && $scope.user.training_jobs.length || 0)

  $scope.no_dates = ->
    if $scope.user
      $scope.dates.length + $scope.user.training_jobs.length < 2
    else
      $scope.dates.length < 2

  $scope.no_bgc = ->
    if $scope.bgc
      if $scope.bgc.status_cd == 1
        false
      else
        true
    else
      true

  $scope.bgc && $scope.bgc.status_cd != 1

  $scope.selected_dates = -> _($scope.dates).filter (date) -> date.selected

  $scope.dates_selected = -> $scope.selected_dates().length + ($scope.user && $scope.user.training_jobs.length || 0) == 2 && 'active' || 'inactive'

  $scope.date_selected = (date) ->
    if date.selected
      'chosen'
    else if $scope.selected_dates().length + ($scope.user && $scope.user.training_jobs.length || 0) == 2
      'inactive'
    else
      'active'

  $scope.select_dates = ->
    $http.post("/trainee/claim_jobs", {jobs: $scope.selected_dates()}).success (rsp) ->
      if rsp.success
        $window.location = '/'
      else
        $http.get('/trainee/available_jobs').success (rsp) ->
          $scope.dates = []
          _(rsp).each (job) ->
            date = {}
            date.job = job.id
            date.moment = moment.utc job.date
            date.day = date.moment.format 'D'
            date.month = date.moment.format 'MMM'
            date.time = '9:30 AM'
            $scope.dates.push date

]

app = angular.module('porter').controller('trainee_dash', TraineeDashCtrl)
