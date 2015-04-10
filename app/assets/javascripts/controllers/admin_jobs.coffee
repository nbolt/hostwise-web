AdminJobsCtrl = ['$scope', '$http', '$timeout', 'spinner', ($scope, $http, $timeout, spinner) ->

  promise = null
  $scope.sort = {id:'date',text:'Date'}
  $scope.filter = {id:'future',text:'Future'}
  $scope.search = ''

  $scope.fetch_jobs = ->
    spinner.startSpin()
    $http.get('/jobs.json',{params: {sort: $scope.sort.id, search: $scope.search, filter: $scope.filter.id}}).success (rsp) ->
      $scope.jobs = rsp.jobs
      _($scope.jobs).each (job) ->
        job.contractor_list = _(job.contractors).map((contractor) -> contractor.name).join(', ')
        job.status = switch job.status_cd
          when 0 then 'open'
          when 1 then 'scheduled'
          when 2 then 'in progress'
          when 3 then 'completed'
          when 4 then 'past due'
          when 5 then "can't access"
          when 6 then 'cancelled'
      spinner.stopSpin()

  $scope.search_property = (job) ->
    $scope.search = job.booking.property_id

  $scope.filterHash = ->
    {
      dropdownCssClass: 'filter'
      minimumResultsForSearch: -1
      data: [{id:'all',text:'All'},{id:'active',text:'Active'},{id:'future',text:'Future'}]
      initSelection: (el, cb) ->
    }

  $scope.$watch 'sort.id', (n,o) -> $scope.fetch_jobs() if o != undefined && o != n
  $scope.$watch 'filter.id', (n,o) -> $scope.fetch_jobs() if o != undefined && o != n

  $scope.$watch 'search', (n,o) -> if o != undefined && o != n
    $timeout.cancel promise
    promise = $timeout (->
      $scope.search = n
      $scope.fetch_jobs()
    ), 400

  $scope.fetch_jobs()

]

app = angular.module('porter').controller('admin_jobs', AdminJobsCtrl)
