PaymentCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  $scope.card = {}

  $scope.paymentMethodHash = ->
    {
    dropdownCssClass: 'payment'
    minimumResultsForSearch: -1
    data: [{id:'credit-card', text:'Credit Card'}]
    initSelection: (el, cb) -> cb {id:'credit-card', text:'Credit Card'}
    }

  $scope.make_default = (payment) ->
    $http.post("/payments/default/#{payment.id}").success (rsp) ->
      $scope.$emit 'fetch_user'
      flash 'ok', 'Changes updated successfully!', true

  $scope.open_deletion = (payment) ->
    $scope.payment = payment
    $scope.payment_info = angular.element("payment-#{payment.id}").find('.details span').text().replace('ending in', '****')
    ngDialog.open template: 'delete-payment-modal', controller: 'payment', className: 'warning full', scope: $scope

  $scope.cancel_deletion = -> ngDialog.closeAll()

  $scope.delete_payment = (payment) ->
    $http.post("/payments/delete/#{payment.id}").success (rsp) ->
      if rsp.success
        $scope.$emit 'fetch_user'
        ngDialog.closeAll()
      else
        flash 'failure', rsp.message

  $scope.add_payment = ->
    if $scope.payment_method.id == 'credit-card'
      $scope.add_credit_card()

  $scope.$watch 'payment_method', (n,o) -> if o
    el = angular.element('.payment.modal .steps .step.one')
    el.find('.content .payment-tab').removeClass 'active'
    el.find('.header').removeClass 'active'
    if n.id == 'credit-card'
      el.find('.content .payment-tab.credit-card').addClass 'active'
      el.find('.header.credit-card').addClass 'active'
    else
      el.find('.content .payment-tab.ach').addClass 'active'
      el.find('.header.ach').addClass 'active'

  $scope.open = ->
    ngDialog.open template: 'add-payment-modal', className: 'success payment full', scope: $scope

  $scope.make_payout = (payment) ->
    $http.post("/payments/payout/#{payment.id}").success (rsp) ->
      $scope.$emit 'fetch_user'
      flash 'ok', 'Changes updated successfully!', true

  $scope.add_credit_card = ->
    exp_date = angular.element(".payment-tab.credit-card input[data-stripe=expiry]").val()
    exp_month = exp_date.split("/")[0]
    exp_year = exp_date.split("/")[1]
    if exp_date is 'MM/YY'
      exp_month = ''
      exp_year =  ''
    Stripe.createToken
      number: angular.element(".payment-tab.credit-card input[data-stripe=number]").val()
      cvc: angular.element(".payment-tab.credit-card input[data-stripe=cvc]").val()
      exp_month: exp_month
      exp_year: exp_year
    , (_, rsp) ->
      if rsp.error
        flash 'failure', rsp.error.message
      else
        $http.post('/payments/add',{
          stripe_id: rsp.id,
          payment_method: $scope.payment_method,
          spinner: true
        }).success (rsp) ->
          if rsp.success
            $scope.card = {}
            $scope.$emit 'fetch_user'
            ngDialog.closeAll()
          else
            flash 'failure', rsp.message

  $scope.close = ->
    ngDialog.closeAll()

  validate = ->
    if _(angular.element('.payment.modal .step').find('input[required]')).filter((el) -> angular.element(el).val() == '')[0]
      false
    else
      true

  flash = (type, msg, parent) ->
    if parent
      classes = 'info ok warning bolt exclamation question'
      el = angular.element('.payment-container .alert')
      el.removeClass(classes).addClass(type).css('opacity', 1)
      el.find('i').removeClass().addClass("icon-alert-#{type}")
      el.find('.title').text msg
    else
      classes = 'info success failure'
      el = angular.element('.payment.modal .flash')
      el.removeClass(classes).addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass(classes)
    ), 4000)

]

app = angular.module('porter').controller('payment', PaymentCtrl)
