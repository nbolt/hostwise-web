AdminJobsCtrl = ['$scope', '$http', '$timeout', 'spinner', ($scope, $http, $timeout, spinner) ->

  promise = null
  $scope.metrics = {}
  $scope.filter = {id:'all',text:'All'}
  $scope.search = ''

  $http.get('/data/markets').success (rsp) -> $scope.markets = rsp.markets

  $http.get('/jobs/metrics').success (rsp) -> $scope.metrics = { total: rsp.total, next_ten: rsp.next_ten, unclaimed: rsp.unclaimed, completed: rsp.completed, growth: rsp.growth }

  $scope.export_csv = ->
    jobs = filtered_data('#example-1')
    $http.post('/jobs/export.csv', {jobs: jobs}).success (rsp) ->
      blob = new Blob([rsp],
        type: "application/octet-stream;charset=utf-8;",
      )
      saveAs(blob, "jobs.csv")

  filtered_data = (table) ->
    table = angular.element(table).dataTable()
    displayed = []
    currentlyDisplayed = table.fnSettings().aiDisplay
    _(currentlyDisplayed).each (index) -> displayed.push( table.fnGetData(index)[0].match(/>\d*</)[0].replace('>', '').replace('<', '') )
    displayed

  $scope.fetch_jobs = ->
    $timeout((->
      table = angular.element("#example-1").dataTable({
        aLengthMenu: [
          [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
        ],
        serverSide: true,
        ajax: (data, cb, settings) ->
          spinner.startSpin()
          $http.get('/jobs.json',{params: {search: $scope.search, filter: $scope.filter.id, data: data}}).success (rsp) ->
            $scope.jobs = rsp.jobs
            _($scope.jobs).each (job) ->
              job.display_date = 
              job.total_kings = job.booking.property.king_bed_count
              job.total_twins = job.booking.property.twin_beds
              job.total_toiletries = job.booking.property.bathrooms
              timeslot = if job.booking.timeslot_type_cd == 0 then 'Flex - ' else 'Specific - '
              job.formatted_time = timeslot + job.formatted_time
              job.linen_handling = switch job.booking.linen_handling_cd
                when 0 then 'purchase'
                when 1 then 'rental'
                when 2 then 'in-unit laundry'
              job.status = switch job.status_cd
                when 0 then 'open'
                when 1 then 'scheduled'
                when 2 then 'in progress'
                when 3 then 'completed'
                when 4 then 'past due'
                when 5 then "can't access"
                when 6 then 'cancelled'
              job.state = switch job.state_cd
                when 0 then 'normal'
                when 1 then 'vip'
                when 2 then 'hidden'
            spinner.stopSpin()
            # show new customers (.badge.badge-blue ng:show='is_new_customer(job.booking.user)' new)
            # show same day cancellation (.badge.badge-red ng:show='is_same_day_cancellation(job)' SDC)
            # show staging jobs
            data_jobs = _($scope.jobs).map (job) -> ["<a href='/jobs/#{job.id}' class='teal'>#{job.id}</a>", "<a href='/properties/#{job.booking.property.id}' class='teal'>#{job.booking.property.id}</a>", job.formatted_time, job.booking.property.zip_code.market.name, job.booking.property.property_size, job.linen_handling, job.display_date, job.booking.property.nickname, job.booking.property.neighborhood_address, "<a href='/hosts/#{job.booking.user.id}/edit' class='teal'>#{job.booking.user.name}</a>", job.booking.property.display_phone_number, job.status, "$#{job.booking.cost}", job.booking.service_list, job.total_kings, job.total_twins, job.total_toiletries, job.booking.extra_king_sets, job.booking.extra_twin_sets, job.booking.extra_toiletry_sets, job.contractor_names, job.state]
            cb({data:data_jobs,recordsTotal:rsp.meta.total,recordsFiltered:rsp.meta.filtered})
      })

      $scope.table = table

      $.fn.dataTable.ext.search.push (settings, data, index) ->
        start = angular.element("##{settings.nTable.id} thead.search th.date input:first-child").val()
        end   = angular.element("##{settings.nTable.id} thead.search th.date input:last-child").val()

        if !start || !end || start == '' || end == ''
          true
        else
          start_date = moment(start,   'MM/DD/YYYY')
          end_date   = moment(end,     'MM/DD/YYYY')
          date       = moment(data[6], 'MM/DD/YYYY')

          date >= start_date && date <= end_date

      angular.element('#example-1 thead.search th').each (index) ->
        unless angular.element(@).html() == ''
          if angular.element(@).html() == 'Date'
            angular.element(@).html "<input><input>"
            angular.element(@).children('input').on 'keyup change', -> table.fnDraw()
            angular.element(@).children('input').datepicker()
          else
            angular.element(@).html "<input>"
            angular.element(@).children('input').on 'keyup change', ->
              table.fnFilter angular.element(@).val(), index
    ),500)

  $scope.is_new_customer = (user) -> user.booking_count <= 5

  $scope.state_class = (job) ->
    switch job.state_cd
      when 0
        'badge-default'
      when 1
        'badge-warning'

  $scope.is_same_day_cancellation = (job) ->
    job.status_cd == 6 && job.booking.status_cd == 2

  convert_date = (date) ->
    moment(date, 'YYYY-MM-DD').toDate()

  $scope.search_property = (job) ->
    $scope.search = job.booking.property_id

  $scope.filterHash = ->
    {
      dropdownCssClass: 'filter'
      minimumResultsForSearch: -1
      data: [{id:'all',text:'All'},{id:'active',text:'Active'},{id:'future',text:'Future'}]
      initSelection: (el, cb) ->
    }

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
