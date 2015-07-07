AdminTransactionsCtrl = ['$scope', '$http', '$timeout', '$window', 'spinner', 'ngDialog', ($scope, $http, $timeout, $window, spinner, ngDialog) ->

  $scope.payout  = { discount: { percentage: 0, amount: 0, reason: '' }, overage: { percentage: 0, amount: 0, reason: '' } }
  $scope.payment = { discount: { percentage: 0, amount: 0, reason: '' }, overage: { percentage: 0, amount: 0, reason: '' } }
  $scope.refund  = { percentage: 0, amount: 0, reason: '' }

  $http.get('/dashboard/revenue').success (rsp) ->
    $scope.total_revenue      = rsp.total
    $scope.monthly_revenue    = rsp.this_month
    $scope.monthly_growth     = rsp.growth

  $http.get('/dashboard/payouts').success (rsp) ->
    $scope.total_payouts      = rsp.total
    $scope.monthly_payouts    = rsp.this_month
    $scope.pending_payouts    = rsp.pending

  $scope.activate_customers = ->
    angular.element('.metrics').removeClass 'active'
    angular.element('#customer-metrics').addClass 'active'
    null

  $scope.activate_contractors = ->
    angular.element('.metrics').removeClass 'active'
    angular.element('#contractor-metrics').addClass 'active'
    null

  $scope.export_bookings = ->
    bookings = filtered_data('#example-1', 'booking')
    $http.post('/transactions/export_bookings.csv', {bookings: bookings}).success (rsp) ->
      blob = new Blob([rsp],
        type: "application/octet-stream;charset=utf-8;",
      )
      saveAs(blob, "bookings.csv")

  $scope.export_jobs = ->
    jobs = filtered_data('#example-2', 'job')
    $http.post('/transactions/export_jobs.csv', {jobs: jobs}).success (rsp) ->
      blob = new Blob([rsp],
        type: "application/octet-stream;charset=utf-8;",
      )
      saveAs(blob, "jobs.csv")

  filtered_data = (table, prefix) ->
    table = angular.element(table).dataTable()
    displayed = []
    currentlyDisplayed = table.fnSettings().aiDisplay
    _(currentlyDisplayed).each (index) ->
      switch prefix
        when 'booking'
          displayed.push( table.fnGetData(index)[1] )
        when 'job'
          displayed.push( table.fnGetData(index)[1].match(/>\d*</)[0].replace('>', '').replace('<', '') )
    displayed

  $scope.selected_payments = -> _(angular.element('#example-1 .cbr:checked')).map (el) -> angular.element(el).attr('id').replace('booking-', '')
  $scope.selected_payouts = -> _(angular.element('#example-2 .cbr:checked')).map (el) -> angular.element(el).attr('id').replace('job-', '')

  $scope.check_booking = (booking) ->
    if angular.element("#booking-#{booking.id}").prop('checked')
      booking.selected = true
    else
      booking.selected = false

  $scope.check_job = (job) ->
    if angular.element("#job-#{job.id}").prop('checked')
      job.selected = true
    else
      job.selected = false

  $scope.job_status_class = (job) ->
    if job.status == 'Paid'
      'btn-secondary'
    else
      'btn-white'

  $scope.status_class = (booking) ->
    if booking.status == 'Open'
      'btn-white'
    else
      'btn-secondary'

  $scope.refund_class = (booking) ->
    if booking.refunded
      'btn-primary disabled'
    else
      'btn-gray'

  $scope.refund_text = (booking) ->
    if booking.refunded
      'Refunded'
    else
      'Refund'

  $scope.refund_modal = (booking) ->
    unless booking.refunded
      booking = _($scope.bookings).find (b) -> b.id == booking
      $scope.selected_payment = booking
      $scope.refund  = { amount: booking.refunded_cost / 100, reason: booking.refunded_reason }
      $scope.refund_amount_update()
      ngDialog.open template: 'refund-payment-modal', className: 'edit-pay info full', scope: $scope

  $scope.refund_payment = ->
    spinner.startSpin()
    $http.post("/bookings/#{$scope.selected_payment.id}/refund", {refunded_cost: $scope.refund.amount, refunded_reason: $scope.refund.reason}).success (rsp) ->
      ngDialog.closeAll()
      spinner.stopSpin()
      $scope.selected_payment.cost            = rsp.cost
      $scope.selected_payment.refunded        = rsp.refunded
      $scope.selected_payment.adjusted        = rsp.adjusted
      $scope.selected_payment.refunded_cost   = rsp.refunded_cost
      $scope.selected_payment.refunded_reason = rsp.refunded_reason

      $scope.selected_payment.adjusted_cost = rsp.adjusted_cost / 100
      if $scope.selected_payment.adjusted_cost >= 0
        $scope.selected_payment.adjusted_cost = "$#{$scope.selected_payment.adjusted_cost.toFixed(2)}"
      else
        $scope.selected_payment.adjusted_cost = "(-$#{($scope.selected_payment.adjusted_cost * -1).toFixed(2)})"
      angular.element($scope.bookings_table).DataTable().ajax.reload()

  $scope.process_payments_modal = -> ngDialog.open template: 'process-payments-confirmation', className: 'info full', scope: $scope
  $scope.cancel_process = -> ngDialog.closeAll()

  $scope.process_payments = ->
    spinner.startSpin()
    $http.post('/transactions/process_payments', {bookings: $scope.selected_payments()}).success (rsp) ->
      $scope.bookings_table.DataTable().ajax.reload()
      ngDialog.closeAll()
      spinner.stopSpin()

  $scope.process_payouts_modal = -> ngDialog.open template: 'process-payouts-confirmation', className: 'info full', scope: $scope
  $scope.cancel_process = -> ngDialog.closeAll()

  $scope.process_payouts = ->
    spinner.startSpin()
    $http.post('/transactions/process_payouts', {jobs: $scope.selected_payouts()}).success (rsp) ->
      $scope.jobs_table.DataTable().ajax.reload()
      ngDialog.closeAll()
      spinner.stopSpin()

  $scope.edit_payout_modal = (job) ->
    job = _($scope.jobs).find (j) -> j.id == job
    $scope.selected_payout = job
    $http.get("/jobs/#{job.id}/contractors").success (rsp) ->
      $scope.contractors = rsp.contractors
      _($scope.contractors).each (contractor) ->
        contractor.payout = _(contractor.payouts).find (payout) -> payout.job_id == job.id
      if $scope.contractors.length == 1
        $scope.select_contractor $scope.contractors[0]
      else
        $scope.selected_contractor = null
      ngDialog.open template: 'edit-payout-modal', className: 'edit-pay info full', scope: $scope

  $scope.edit_payment_modal = (booking) ->
    booking = _($scope.bookings).find (b) -> b.id == booking
    $scope.selected_payment = booking
    $scope.payment = { discount: { amount: booking.discounted_cost / 100, reason: booking.discounted_reason }, overage: { amount: booking.overage_cost / 100, reason: booking.overage_reason } }
    $scope.payment_discount_amount_update()
    $scope.payment_overage_amount_update()
    ngDialog.open template: 'edit-payment-modal', className: 'edit-pay info full', scope: $scope

  $scope.select_contractor = (contractor) ->
    $scope.selected_contractor = contractor
    $scope.payout = { discount: { amount: contractor.payout.subtracted_amount / 100, reason: contractor.payout.subtracted_reason }, overage: { amount: contractor.payout.additional_amount / 100, reason: contractor.payout.additional_reason } }
    $scope.payout_discount_amount_update()
    $scope.payout_overage_amount_update()
    angular.element('.ngdialog .content > .caption').hide()
    angular.element('.ngdialog .content > .contractor').hide()
    angular.element("#contractor-#{contractor.id}").show()
    null

  $scope.contractor_class = (contractor) -> contractor == $scope.selected_contractor && 'selected' || ''
  $scope.modified_payment = (booking) -> booking.adjusted && 'modified' || ''
  $scope.modified_payout  = (job) ->
    if _(job.payouts).find((payout) -> payout.adjusted)
      'modified'
    else
      ''

  $scope.edit_payment = (booking) ->
    $http.post("/bookings/#{booking.id}/edit_payment", {adjusted_cost: adjusted_payment(), overage_cost: $scope.payment.overage.amount, discounted_cost: $scope.payment.discount.amount, overage_reason: $scope.payment.overage.reason, discounted_reason: $scope.payment.discount.reason}).success (rsp) ->
      if rsp.success
        ngDialog.closeAll()
        angular.element("#payment-#{booking.id} td:last-child a").text "$#{$scope.updated_payment()}"
        angular.element("#payment-#{booking.id} td:nth-last-child(2)").text "$#{adjusted_payment()}"
        angular.element("#payment-#{booking.id} td:last-child").addClass 'modified'
        angular.element("#payment-#{booking.id} td:nth-last-child(2)").addClass 'modified'
        booking.discounted_cost   = parseFloat($scope.payment.discount.amount) * 100
        booking.discounted_reason = $scope.payment.discount.reason
        booking.overage_cost      = parseFloat($scope.payment.overage.amount) * 100
        booking.overage_reason    = $scope.payment.overage.reason
        angular.element($scope.bookings_table).DataTable().ajax.reload()

  $scope.edit_payout = (job) ->
    $http.post("/jobs/#{job.id}/edit_payout", {payout_id: $scope.selected_contractor.payout.id, adjusted_cost: adjusted_payout(), overage_cost: $scope.payout.overage.amount, discounted_cost: $scope.payout.discount.amount, overage_reason: $scope.payout.overage.reason, discounted_reason: $scope.payout.discount.reason}).success (rsp) ->
      if rsp.success
        ngDialog.closeAll()
        angular.element("#payout-#{job.id} td:nth-last-child(2)").addClass 'modified'
        angular.element("#payout-#{job.id} td:last-child").addClass 'modified'
        job.total_payout = rsp.total_payout
        job.total_payout = "$#{job.total_payout.toFixed(2)}"
        job.adjusted_payout = rsp.adjusted_payout
        if job.adjusted_payout >= 0
          job.adjusted_payout = "$#{job.adjusted_payout.toFixed(2)}"
        else
          job.adjusted_payout = "(-$#{(job.adjusted_payout * -1).toFixed(2)})"
        angular.element($scope.jobs_table).DataTable().ajax.reload()

  $scope.fetch_bookings = ->
    table = angular.element("#example-1").dataTable({
      aLengthMenu: [
        [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
      ]
      aoColumns: [{bSortable:false},null,null,null,null,{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false}]
      serverSide: true
      fnInitComplete: (->
        angular.element('#example-1 thead.search th').each (index) ->
          unless angular.element(@).html() == ''
            if angular.element(@).html() == 'Date'
              angular.element(@).html "<input><input>"
              angular.element(@).children('input').on 'keyup change', ->
                start = angular.element("#example-1 thead.search th.date input:first-child").val()
                end   = angular.element("#example-1 thead.search th.date input:last-child").val()
                table.fnFilter "#{start}|#{end}", index
              angular.element(@).children('input').datepicker()
            else
              angular.element(@).html "<input>"
              angular.element(@).children('input').on 'keyup change', ->
                table.fnFilter angular.element(@).val(), index

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
      )
      ajax: (data, cb, settings) ->
        $http.get('/bookings.json', {params: {data: data}}).success (rsp) ->
          $scope.bookings = _(rsp.transactions).map (transaction) -> JSON.parse transaction
          _($scope.bookings).each (booking) ->
            if booking.properties
              booking.status = 'Received'
              booking.cost = (booking.amount / 100.0).toFixed 2
            else
              booking.adjusted_cost = booking.adjusted_cost / 100
              if booking.adjusted_cost >= 0
                booking.adjusted_cost = "$#{booking.adjusted_cost.toFixed(2)}"
              else
                booking.adjusted_cost = "(-$#{(booking.adjusted_cost * -1).toFixed(2)})"
              booking.cost = booking.cost.toFixed 2
              booking.selected = false
              booking.status =
                switch booking.payment_status_cd
                  when 0 then 'Open'
                  when 1 then 'Received'
          data_bookings = _($scope.bookings).map (booking) -> [(if booking.payment_status_cd == 0 then "<div style='text-align:center'><input class='cbr' type='checkbox' id='booking-#{booking.id}' /></div>" else null), booking.id, (if booking.properties then null else "<a href='/jobs/#{booking.job.id}' class='teal'>#{booking.job.id}</a>"), "<a href='/properties/#{booking.properties && booking.properties[0].id || booking.property.id}' class='teal'>#{booking.properties && booking.properties[0].id || booking.property.id}</a>", "<a href='/hosts/#{booking.properties && booking.properties[0].user.id || booking.user.id}/edit' class='teal'>#{booking.properties && booking.properties[0].user.id || booking.user.id}</a>", booking.properties && booking.charged_at || booking.date, "<a href='/hosts/#{booking.properties && booking.properties[0].user.id || booking.user.id}/edit' class='teal'>#{booking.properties && booking.properties[0].user.name || booking.user.name}</a>", booking.status, (if booking.payment_status_cd == 1 then "<div class='btn btn-xs #{$scope.refund_class(booking)}' onclick='javascript:$(this).scope().refund_modal(#{booking.id})'>#{$scope.refund_text(booking)}</div>" else null), (if booking.properties then null else booking.adjusted_cost), (if booking.properties then "<span>$#{booking.cost}</span>" else if booking.payment_status_cd == 0 then "<a class='teal' href='javascript:void(0)' onclick='javascript:$(this).scope().edit_payment_modal(#{booking.id})'>$#{booking.cost}</a>" else "<span>$#{booking.cost}</span>")]
          cb({data:data_bookings,recordsTotal:rsp.meta.total,recordsFiltered:rsp.meta.filtered})
    })
    $scope.bookings_table = table

  $scope.fetch_jobs = ->
    table = angular.element("#example-2").dataTable({
      aLengthMenu: [
        [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
      ]
      aoColumns: [{bSortable:false},null,null,null,null,{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false}]
      serverSide: true
      fnInitComplete: (->
        angular.element('#example-2 thead.search th').each (index) ->
          unless angular.element(@).html() == ''
            if angular.element(@).html() == 'Date'
              angular.element(@).html "<input><input>"
              angular.element(@).children('input').on 'keyup change', ->
                start = angular.element("#example-2 thead.search th.date input:first-child").val()
                end   = angular.element("#example-2 thead.search th.date input:last-child").val()
                table.fnFilter "#{start}|#{end}", index
              angular.element(@).children('input').datepicker()
            else
              angular.element(@).html "<input>"
              angular.element(@).children('input').on 'keyup change', ->
                table.fnFilter angular.element(@).val(), index

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
      )
      ajax: (data, cb, settings) ->
        $http.get('/jobs.json?filter=complete', {params: {data:data}}).success (rsp) ->
          $scope.jobs = rsp.jobs
          _($scope.jobs).each (job) ->
            if job.payouts[0]
              job.total_payout = _(job.payouts).reduce(((acc, payout) -> acc + payout.total), 0)
              job.total_payout = "$#{(job.total_payout/100).toFixed(2)}"
              job.adjusted_payout = _(job.payouts).reduce(((acc, payout) -> acc + payout.adjusted_amount), 0) / 100
              if job.adjusted_payout >= 0
                job.adjusted_payout = "$#{job.adjusted_payout.toFixed(2)}"
              else
                job.adjusted_payout = "(-$#{(job.adjusted_payout * -1).toFixed(2)})"
            else
              job.adjusted_payout = '$0.00'
              job.total_payout = 'Pending'

            if !job.payouts[0] || _(job.payouts).find((payout) -> payout.status_cd != 2)
              job.status = 'Open'
            else
              job.status = 'Paid'
          data_jobs = _($scope.jobs).map (job) -> [(if job.total_payout != "Pending" && job.status != "Paid" then "<div style='text-align:center'><input class='cbr' type='checkbox' id='job-#{job.id}' /></div>" else ''), "<a href='/jobs/#{job.id}' class='teal'>#{job.id}</a>", "<a href='/properties/#{job.booking.property.id}' class='teal'>#{job.booking.property.id}</a>", "<a href='/hosts/#{job.booking.user.id}/edit' class='teal'>#{job.booking.user.id}</a>", job.date, "<a href='/hosts/#{job.booking.user.id}/edit' class='teal'>#{job.booking.user.name}</a>", job.contractor_names, job.status, job.adjusted_payout, (if job.total_payout != "Pending" && job.status != "Paid" then "<a class='teal' href='javascript:void(0)' onclick='javascript:$(this).scope().edit_payout_modal(#{job.id})'>#{job.total_payout}</a>" else "<span>#{job.total_payout}</span>"), job.contractor_payouts]
          cb({data:data_jobs,recordsTotal:rsp.meta.total,recordsFiltered:rsp.meta.filtered})
    })
    $scope.jobs_table = table

  $scope.fetch_bookings()
  $scope.fetch_jobs()

  adjusted_payment = ->
    parseFloat($scope.updated_payment()) - $scope.selected_payment.original_cost

  adjusted_payout = ->
    parseFloat($scope.updated_payout()) - ($scope.selected_contractor.payout.amount / 100)

  $scope.updated_cost = ->
    updated_cost = $scope.selected_payment.original_cost - (parseFloat($scope.refund.amount) || 0)
    updated_cost.toFixed 2

  $scope.updated_payment = ->
    updated_cost = $scope.selected_payment.original_cost - (parseFloat($scope.payment.discount.amount) || 0)
    updated_cost = updated_cost + (parseFloat($scope.payment.overage.amount) || 0)
    updated_cost.toFixed 2

  $scope.updated_payout = ->
    if $scope.selected_contractor
      updated_cost = ($scope.selected_contractor.payout.amount / 100) - (parseFloat($scope.payout.discount.amount) || 0)
      updated_cost = updated_cost + (parseFloat($scope.payout.overage.amount) || 0)
      updated_cost.toFixed 2
    else
      0

  $scope.refund_percentage_update = ->
    amount = $scope.selected_payment.original_cost
    new_amount = amount * ($scope.refund.percentage / 100)
    $scope.refund.amount = new_amount.toFixed 2

  $scope.refund_amount_update = ->
    amount = $scope.selected_payment.original_cost
    new_percentage = (1 - (amount - $scope.refund.amount) / amount) * 100
    $scope.refund.percentage = new_percentage.toFixed 2

  $scope.payout_discount_percentage_update = ->
    amount = ($scope.selected_contractor.payout.amount / 100)
    new_amount = amount * ($scope.payout.discount.percentage / 100)
    $scope.payout.discount.amount = new_amount.toFixed 2

  $scope.payout_discount_amount_update = ->
    amount = ($scope.selected_contractor.payout.amount / 100)
    new_percentage = (1 - (amount - $scope.payout.discount.amount) / amount) * 100
    $scope.payout.discount.percentage = new_percentage.toFixed 2

  $scope.payout_overage_percentage_update = ->
    amount = ($scope.selected_contractor.payout.amount / 100)
    new_amount = amount * ($scope.payout.overage.percentage / 100)
    $scope.payout.overage.amount = new_amount.toFixed 2

  $scope.payout_overage_amount_update = ->
    amount = ($scope.selected_contractor.payout.amount / 100)
    new_percentage = (1 - (amount - $scope.payout.overage.amount) / amount) * 100
    $scope.payout.overage.percentage = new_percentage.toFixed 2

  $scope.payment_discount_percentage_update = ->
    new_amount = $scope.selected_payment.original_cost * ($scope.payment.discount.percentage / 100)
    $scope.payment.discount.amount = new_amount.toFixed 2

  $scope.payment_discount_amount_update = ->
    new_percentage = (1 - ($scope.selected_payment.original_cost - $scope.payment.discount.amount) / $scope.selected_payment.original_cost) * 100
    $scope.payment.discount.percentage = new_percentage.toFixed 2

  $scope.payment_overage_percentage_update = ->
    new_amount = $scope.selected_payment.original_cost * ($scope.payment.overage.percentage / 100)
    $scope.payment.overage.amount = new_amount.toFixed 2

  $scope.payment_overage_amount_update = ->
    new_percentage = (1 - ($scope.selected_payment.original_cost - $scope.payment.overage.amount) / $scope.selected_payment.original_cost) * 100
    $scope.payment.overage.percentage = new_percentage.toFixed 2

]

app = angular.module('porter').controller('admin_transactions', AdminTransactionsCtrl)
