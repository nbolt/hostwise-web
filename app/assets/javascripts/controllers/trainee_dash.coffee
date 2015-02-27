TraineeDashCtrl = ['$scope', '$http', '$window', ($scope, $http, $window) ->

  $scope.dates = []
  $scope.selected_dates = []

  $http.get('/trainee/available_jobs').success (rsp) ->
    _(rsp).each (job) ->
      date = {}
      date.job = job.id
      date.moment = moment.utc job.date
      date.day = date.moment.format 'D'
      date.month = date.moment.format 'MMM'
      date.time = '9:45 AM'
      $scope.dates.push date

  $scope.no_dates = -> $scope.dates.length < 2

  $scope.dates_selected = -> $scope.selected_dates.length == 2 && 'active' || 'inactive'

  $scope.date_selected = (date) ->
    if (_($scope.selected_dates).find (d) -> d == date)
      'chosen'
    else if $scope.selected_dates.length == 2
      'inactive'
    else
      'active'

  $scope.select_date = (date) ->
    if (_($scope.selected_dates).find (d) -> d == date)
      $scope.selected_dates = _($scope.selected_dates).reject (d) -> d == date
    else if $scope.selected_dates.length < 2
      $scope.selected_dates.push date

  $scope.select_dates = ->
    $http.post("/trainee/claim_jobs", {jobs: $scope.selected_dates}).success (rsp) ->
      if rsp.success
        $window.location = '/'
      else
        $http.get('/trainee/available_jobs').success (rsp) ->
          $scope.dates = []
          $scope.selected_dates = []
          _(rsp).each (job) ->
            date = {}
            date.job = job.id
            date.moment = moment.utc job.date
            date.day = date.moment.format 'D'
            date.month = date.moment.format 'MMM'
            date.time = '9:45 AM'
            $scope.dates.push date

]

app = angular.module('porter').controller('trainee_dash', TraineeDashCtrl)
