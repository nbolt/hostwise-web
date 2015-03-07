AdminJobsCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  promise = null
  $scope.sort = {id:'id',text:'ID'}
  $scope.filter = {id:'all',text:'All'}
  $scope.search = ''

  $scope.fetch_jobs = ->
    $http.get('/jobs.json',{params:{sort: $scope.sort.id,search: $scope.search,filter: $scope.filter.id}}).success (rsp) ->
      $scope.jobs = rsp
      _($scope.jobs).each (job) ->
        job.contractor_list = _(job.contractors).map((contractor) -> contractor.name).join(', ')
        job.status = switch job.status_cd
          when 0 then 'open'
          when 1 then 'scheduled'
          when 2 then 'in progress'
          when 3 then 'completed'
          when 4 then 'past due'

  $scope.sortHash = ->
    {
      dropdownCssClass: 'sort'
      minimumResultsForSearch: -1
      data: [{id:'id',text:'ID'},{id:'date',text:'Date'}]
      initSelection: (el, cb) ->
    }

  $scope.filterHash = ->
    {
      dropdownCssClass: 'filter'
      minimumResultsForSearch: -1
      data: [{id:'all',text:'All'},{id:'active',text:'Active'},{id:'future',text:'Future'}]
      initSelection: (el, cb) ->
    }

  $scope.$watch 'sort.id', (n,o) -> $scope.fetch_jobs() if o
  $scope.$watch 'filter.id', (n,o) -> $scope.fetch_jobs() if o

  $scope.$watch 'search', (n,o) -> if o
    $timeout.cancel promise
    promise = $timeout (->
      $scope.search = n
      $scope.fetch_jobs()
    ), 400

  $scope.fetch_jobs()

]

app = angular.module('porter').controller('admin_jobs', AdminJobsCtrl)