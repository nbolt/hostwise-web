AdminJobsCtrl = ['$scope', '$http', '$timeout', 'spinner', ($scope, $http, $timeout, spinner) ->

  promise = null
  $scope.filter = {id:'all',text:'All'}
  $scope.search = ''

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
    spinner.startSpin()
    $http.get('/jobs.json',{params: {search: $scope.search, filter: $scope.filter.id}}).success (rsp) ->
      $scope.jobs = rsp.jobs
      _($scope.jobs).each (job) ->
        job.total_kings = job.booking.property.king_bed_count
        job.total_twins = job.booking.property.twin_beds
        job.total_toiletries = job.booking.property.bathrooms
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
      $timeout((->
        table = angular.element("#example-1").dataTable({
          aLengthMenu: [
            [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
          ]
        })

        $.fn.dataTable.ext.search.push (settings, data, index) ->
          start = angular.element("##{settings.nTable.id} thead.search th.date input:first-child").val()
          end   = angular.element("##{settings.nTable.id} thead.search th.date input:last-child").val()

          if !start || !end || start == '' || end == ''
            true
          else
            start_date = moment(start,   'MM/DD/YYYY')
            end_date   = moment(end,     'MM/DD/YYYY')
            date       = moment(data[3], 'MM/DD/YYYY')

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

  $scope.next_ten_days_jobs = (jobs) ->
    count = 0
    current_date = new Date()
    _(jobs).each (job) ->
      converted_date = convert_date(job.date)
      if (converted_date > current_date) && (converted_date <= (current_date.setDate(current_date.getDate() + 10)) )
        count += 1
    return count

  $scope.unclaimed_next_two_days_jobs = (jobs) ->
    count = 0
    current_date = new Date()
    _(jobs).each (job) ->
      converted_date = convert_date(job.date)
      if (converted_date > current_date) && (converted_date <= (current_date.setDate(current_date.getDate() + 2)) ) && (job.status_cd == 0)
        count += 1
    return count

  $scope.completed_last_month = (jobs) ->
    current_date = new Date()
    last_month = current_date.getMonth() - 1
    count = 0
    _(jobs).each (job) ->
      converted_date = convert_date(job.date)
      if (converted_date.getMonth() == last_month) && (job.status_cd == 3)
        count += 1
    return count

  $scope.cancelled_last_month = (jobs) ->
    current_date = new Date()
    last_month = current_date.getMonth() - 1
    count = 0
    _(jobs).each (job) ->
      converted_date = convert_date(job.date)
      if (converted_date.getMonth() == last_month) && (job.status_cd == 6)
        count += 1
    return count

  $scope.percent_growth = (jobs) ->
    monthly_growth = []
    date = new Date()
    month_subtractor = [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
    _(month_subtractor).each (subtractor) ->
      date.setMonth(date.getMonth() - subtractor)
    return monthly_growth
    

  $scope.search_property = (job) ->
    $scope.search = job.booking.property_id

  $scope.filterHash = ->
    {
      dropdownCssClass: 'filter'
      minimumResultsForSearch: -1
      data: [{id:'all',text:'All'},{id:'active',text:'Active'},{id:'future',text:'Future'}]
      initSelection: (el, cb) ->
    }

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
