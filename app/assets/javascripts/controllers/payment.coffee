PaymentCtrl = ['$scope', '$http', '$timeout', 'spinner', 'ngDialog', ($scope, $http, $timeout, spinner, ngDialog) ->

  $scope.card = {}
  $scope.bank = {}

  refresh_recipient = ->
    $scope.user_fetched.promise.then ->
      $http.get('/stripe_recipient').success (rsp) -> $scope.recipient = rsp.recipient

  $scope.$on 'refresh_recipient', -> refresh_recipient()

  refresh_recipient()

  $scope.paymentMethodHash = ->
    {
      dropdownCssClass: 'payment'
      minimumResultsForSearch: -1
      data: [{id:'credit-card', text:'Credit Card'}]
      initSelection: (el, cb) -> cb {id:'credit-card', text:'Credit Card'}
    }

  $scope.payoutMethodHash = ->
    {
      dropdownCssClass: 'payment'
      minimumResultsForSearch: -1
      data: [{id:'bank-account', text:'Bank Account'}]
      initSelection: (el, cb) -> cb {id:'bank-account', text:'Bank Account'}
    }

  $scope.make_default = (payment) ->
    $http.post("/payments/default/#{payment.id}").success (rsp) ->
      $scope.$emit 'fetch_user'
      flash 'ok', 'Changes updated successfully!', true

  $scope.open_deletion = (payment) ->
    ngDialog.open template: 'delete-payment-modal', controller: 'payment', className: 'warning full', scope: $scope

  $scope.cancel_deletion = -> ngDialog.closeAll()

  $scope.delete_payment = () ->
    $http.post("/payments/remove").success (rsp) ->
      if rsp.success
        $scope.$emit 'fetch_user'
        ngDialog.closeAll()
      else
        flash 'failure', rsp.message

  $scope.add_payment = ->
    if $scope.payment_method.id == 'credit-card'
      $scope.add_credit_card()
    else if $scope.payment_method.id == 'bank-account'
      $scope.add_bank_account()

  $scope.$watch 'payment_method', (n,o) -> if o
    el = angular.element('.payment.modal .steps .step.one')
    el.find('.content .payment-tab').removeClass 'active'
    el.find('.header').removeClass 'active'
    if n.id == 'credit-card'
      el.find('.content .payment-tab.credit-card').addClass 'active'
      el.find('.header.credit-card').addClass 'active'
    else
      el.find('.content .payment-tab.bank-account').addClass 'active'
      el.find('.header.ach').addClass 'active'

  $scope.open = ->
    ngDialog.open template: 'add-payment-modal', className: 'success payment full', scope: $scope

  $scope.open_payout = ->
    ngDialog.open template: 'add-payout-modal', className: 'success payment full', scope: $scope

  $scope.make_payout = (payment) ->
    $http.post("/payments/payout/#{payment.id}").success (rsp) ->
      $scope.$emit 'fetch_user'
      flash 'ok', 'Changes updated successfully!', true

  $scope.add_credit_card = ->
    spinner.startSpin()
    exp_date = angular.element(".payment-tab.credit-card input[data-stripe=expiry]").val()
    exp_month = exp_date.split("/")[0]
    exp_year = exp_date.split("/")[1]
    if exp_date is 'MM/YY'
      exp_month = ''
      exp_year =  ''
    Stripe.card.createToken
      number: angular.element(".payment-tab.credit-card input[data-stripe=number]").val()
      cvc: angular.element(".payment-tab.credit-card input[data-stripe=cvc]").val()
      exp_month: exp_month
      exp_year: exp_year
    , (_, rsp) ->
      if rsp.error
        spinner.stopSpin()
        flash 'failure', rsp.error.message
      else
        $http.post('/payments/add',{
          stripe_id: rsp.id,
          payment_method: $scope.payment_method
        }).success (rsp) ->
          spinner.stopSpin()
          if rsp.success
            $scope.card = {}
            $scope.$emit 'refresh_recipient'
            $scope.$emit 'fetch_user'
            ngDialog.closeAll()
          else
            flash 'failure', rsp.message

  $scope.add_bank_account = ->
    spinner.startSpin()
    Stripe.bankAccount.createToken
      country: 'US'
      routing_number: $scope.bank.routing_number
      account_number: $scope.bank.account_number
    , (_, rsp) ->
      if rsp.error
        flash 'failure', rsp.error.message
        spinner.stopSpin()
      else
        $http.post('/payments/add',{
          stripe_id: rsp.id,
          payment_method: $scope.payment_method
        }).success (rsp) ->
          spinner.stopSpin()
          if rsp.success
            $scope.bank = {}
            $scope.$emit 'refresh_recipient'
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
