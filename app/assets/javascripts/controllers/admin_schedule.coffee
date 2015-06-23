AdminScheduleCtrl = ['$scope', '$http', '$timeout', 'spinner', ($scope, $http, $timeout, spinner) ->

  promise = null
  $scope.metrics = {}
  $scope.filter = {id:'all',text:'All'}
  $scope.search = ''

  $http.get('/data/markets').success (rsp) -> $scope.markets = rsp.markets

  $http.get('/jobs/metrics').success (rsp) -> $scope.metrics = { total: rsp.total, next_ten: rsp.next_ten, unclaimed: rsp.unclaimed, completed: rsp.completed, growth: rsp.growth }

  $scope.fetch_jobs = ->
    table = angular.element("#example-1").dataTable({
      aLengthMenu: [
        [-1], ["All"]
      ]
      aoColumns: [{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false}]
      serverSide: true
      fnInitComplete: ->
        angular.element('#example-1 thead.search th').each (index) ->
          unless angular.element(@).html() == ''
            angular.element(@).html "<input>"
            angular.element(@).children('input').on 'keyup change', ->
              table.fnFilter angular.element(@).val(), index
      ajax: (data, cb, settings) ->
        $http.get('/today.json',{params: {search: $scope.search, filter: $scope.filter.id, data: data}}).success (rsp) ->
          data_jobs = []
          $scope.jobs = rsp.jobs
          _(range(14)).each (i) ->
            time = i + 9
            data_jobs.push(["<strong>#{display_time(time-1)}</strong>", open_jobs(time), scheduled_jobs(time), in_progress_jobs(time), completed_jobs(time)])
          cb({data:data_jobs,recordsTotal:rsp.meta.total,recordsFiltered:rsp.meta.filtered})
    })
    $scope.table = table

  $scope.marketHash = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      placeholder: 'Market'
      data: -> { results: _($scope.markets).map (market) -> { id: market.id, text: market.name } },
      initSelection: (el, cb) ->
    }

  $scope.$watch 'market', (n,o) -> if n
    angular.element('th.location input').val($scope.market.text).trigger($.Event 'change')

  $scope.$watch 'search', (n,o) -> if o != undefined && o != n
    $timeout.cancel promise
    promise = $timeout (->
      $scope.search = n
      $scope.fetch_jobs()
    ), 400

  $scope.fetch_jobs()

  display_time = (time) ->
    if time < 12 then meridian = 'A' else meridian = 'P'
    time -= 12 if time > 12
    "#{time} #{meridian}M"

  range = (n) -> if n then _.range 0, n else []

  open_jobs = (time) ->
    jobs = _($scope.jobs).filter (job) -> job.status_cd == 0 && (job.booking.timeslot == time || !job.booking.timeslot)
    _(jobs).map((job) -> "<a href='/jobs/#{job.id}'>[#{job.booking.property.neighborhood} - #{job.booking.property.nickname} - #{job.id}]</a>").join ' - '

  scheduled_jobs = (time) ->
    jobs = _($scope.jobs).filter (job) -> job.status_cd == 1 && job.booking.timeslot == time
    _(jobs).map((job) -> "<a href='/jobs/#{job.id}'>[#{job.booking.property.neighborhood} - #{job.booking.property.nickname} - #{job.id} - #{job.contractor_names}]</a>").join ' - '

  in_progress_jobs = (time) ->
    jobs = _($scope.jobs).filter (job) -> job.status_cd == 2 && job.booking.timeslot == time
    _(jobs).map((job) -> "<a href='/jobs/#{job.id}'>[#{job.booking.property.neighborhood} - #{job.booking.property.nickname} - #{job.id} - #{job.contractor_names}]</a>").join ' - '

  completed_jobs = (time) ->
    jobs = _($scope.jobs).filter (job) -> (job.status_cd == 3 || job.status_cd == 5) && job.booking.timeslot == time
    _(jobs).map((job) -> "<a href='/jobs/#{job.id}'>[#{job.booking.property.neighborhood} - #{job.booking.property.nickname} - #{job.id} - #{job.contractor_names}]</a>").join ' - '

]

app = angular.module('porter').controller('admin_schedule', AdminScheduleCtrl)
