CouponsCtrl = ['$scope', '$http', '$timeout', '$window', 'ngDialog', 'spinner', ($scope, $http, $timeout, $window, ngDialog, spinner) ->

  $scope.coupon = {status_cd:1}

  $scope.create_coupon_modal = ->
    $scope.coupon = {status_cd:1}
    ngDialog.open template: 'create-coupon-modal', className: 'coupon info full', scope: $scope
  $scope.edit_coupon_modal = (coupon) ->
    $scope.coupon = coupon
    ngDialog.open template: 'edit-coupon-modal', className: 'coupon info full', scope: $scope
  $scope.cancel_process = -> ngDialog.closeAll()

  $scope.amount_class = ->
    switch $scope.coupon and $scope.coupon.discount_type_cd
      when '0'
        'dollar'
      when '1'
        'percentage'

  $scope.create_coupon = ->
    spinner.startSpin()
    $http.post('/coupons/create', {coupon: $scope.coupon}).success (rsp) ->
      #spinner.stopSpin()
      if rsp.success
        $window.location = '/coupons'

  $scope.update_coupon = ->
    spinner.startSpin()
    $http.post("/coupons/#{$scope.coupon.id}/update", {coupon: $scope.coupon}).success (rsp) ->
      #spinner.stopSpin()
      if rsp.success
        $window.location = '/coupons'

  $scope.selectHash = ->
    {
      data: []
      tags: true
      initSelection: (el, cb) ->
      formatResult: (data) -> data.text
      ajax:
        url: '/data/coupon_users'
        quietMillis: 400
        data: (term) -> { term: term }
        results: (data) -> { results: _(data.data).map((user) -> { id: user.id, text: user.name }) }
    }

  $scope.fetch_coupons = ->
    spinner.startSpin()
    $http.get('/coupons.json').success (rsp) ->
      $scope.coupons = rsp.coupons
      _($scope.coupons).each (coupon) ->
        coupon.expiration = moment(coupon.expiration, 'YYYY-MM-DD').format('MM/DD/YYYY') if coupon.expiration
        coupon.amount = coupon.amount / 100 if coupon.discount_type_cd == 0
        coupon.customers = _(coupon.users).map (customer) -> { id: customer.id, text: customer.name }
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
            date       = moment(data[6], 'MM/DD/YYYY')

            date >= start_date && date <= end_date

        angular.element('#example-1 thead.search th').each (index) ->
          unless angular.element(@).html() == ''
            if angular.element(@).html() == 'Expiration'
              angular.element(@).html "<input><input>"
              angular.element(@).children('input').on 'keyup change', -> table.fnDraw()
              angular.element(@).children('input').datepicker()
            else
              angular.element(@).html "<input>"
              angular.element(@).children('input').on 'keyup change', ->
                table.fnFilter angular.element(@).val(), index
      ),500)

  $scope.fetch_coupons()

]

app = angular.module('porter').controller('coupons', CouponsCtrl)
