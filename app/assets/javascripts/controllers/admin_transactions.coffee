AdminTransactionsCtrl = ['$scope', '$http', '$timeout', '$window', 'spinner', 'ngDialog', ($scope, $http, $timeout, $window, spinner, ngDialog) ->

  $scope.selected_payments = -> _($scope.bookings).filter (booking) -> booking.selected
  $scope.selected_payouts = -> _($scope.jobs).filter (job) -> job.selected

  $scope.check_booking = (booking) ->
    if angular.element("#check-#{booking.id}").prop('checked')
      booking.selected = true
    else
      booking.selected = false

  $scope.check_job = (job) ->
    if angular.element("#job-#{job.id}").prop('checked')
      job.selected = true
    else
      job.selected = false

  $scope.process_payments_modal = -> ngDialog.open template: 'process-payments-confirmation', className: 'info full', scope: $scope
  $scope.cancel_process = -> ngDialog.closeAll()

  $scope.process_payments = ->
    spinner.startSpin()
    $http.post('/transactions/process_payments', {bookings: _($scope.selected_payments()).map((b) -> b.id)}).success (rsp) ->
      $window.location = '/transactions'

  $scope.process_payouts_modal = -> ngDialog.open template: 'process-payouts-confirmation', className: 'info full', scope: $scope
  $scope.cancel_process = -> ngDialog.closeAll()

  $scope.process_payouts = ->
    spinner.startSpin()
    $http.post('/transactions/process_payouts', {jobs: _($scope.selected_payouts()).map((b) -> b.id)}).success (rsp) ->
      $window.location = '/transactions'

  $scope.fetch_bookings = ->
    spinner.startSpin()
    $http.get('/bookings.json?filter=complete').success (rsp) ->
      $scope.bookings = JSON.parse rsp.bookings
      _($scope.bookings).each (booking) ->
        booking.selected = false
        booking.status =
          switch booking.payment_status_cd
            when 0 then 'Open'
            when 1 then 'Received'
      spinner.stopSpin()
      $timeout((->
        angular.element("#example-1").dataTable({
          aLengthMenu: [
            [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
          ],
          aoColumns: [{bSortable:false},null,null,null,null,null,null,null]
        })

        $state = angular.element("#example-1 thead input[type='checkbox'], #example-1 tfoot input[type='checkbox']")
        cbr_replace()
        $state.trigger('change')

        angular.element('#example-1').on('draw.dt', ->
          cbr_replace()
          $state.trigger('change')
        )

        $state.on('change', (ev) ->
          $chcks = $("#example-1 tbody input[type='checkbox']");

          if($state.is(':checked'))
            $chcks.prop('checked', true).trigger('change');
          else
            $chcks.prop('checked', false).trigger('change');
        )
      ),500)

  $scope.fetch_jobs = ->
    spinner.startSpin()
    $http.get('/jobs.json?filter=complete').success (rsp) ->
      $scope.jobs = rsp.jobs
      _($scope.jobs).each (job) ->
        if job.payouts[0]
          job.total_payout = _(job.payouts).reduce(((acc, payout) -> acc + payout.amount), 0)
          job.total_payout = "$#{job.total_payout/100}"
        else
          job.total_payout = 'Pending'

        if !job.payouts[0] || _(job.payouts).find((payout) -> payout.status_cd != 2)
          job.status = 'Open'
        else
          job.status = 'Paid'

      spinner.stopSpin()
      $timeout((->
        angular.element("#example-2").dataTable({
          aLengthMenu: [
            [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
          ],
          aoColumns: [{bSortable:false},null,null,null,null,null,null,null]
        })

        $state = angular.element("#example-2 thead input[type='checkbox'], #example-2 tfoot input[type='checkbox']")
        cbr_replace()
        $state.trigger('change')

        angular.element('#example-2').on('draw.dt', ->
          cbr_replace()
          $state.trigger('change')
        )

        $state.on('change', (ev) ->
          $chcks = $("#example-2 tbody input[type='checkbox']");

          if($state.is(':checked'))
            $chcks.prop('checked', true).trigger('change');
          else
            $chcks.prop('checked', false).trigger('change');
        )
      ),500)

  $scope.fetch_bookings()
  $scope.fetch_jobs()

]

app = angular.module('porter').controller('admin_transactions', AdminTransactionsCtrl)
