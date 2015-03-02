PaymentCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  $scope.card = {}
  $scope.bank = {}

  $scope.paymentMethodHash = ->
    {
    dropdownCssClass: 'payment'
    minimumResultsForSearch: -1
    data: [{id:'credit-card', text:'Credit Card'},{id:'ach', text: 'ACH Bank Transfer'}]
    initSelection: (el, cb) -> cb {id:'credit-card', text:'Credit Card'}
    }

  $scope.make_default = (id) ->
    $http.put('/payments/default', {
      payment_id: id
    }).success (rsp) ->
      $scope.$emit 'fetch_user'
      flash 'ok', 'Changes updated successfully!', true

  $scope.open_deletion = (event) ->
    $scope.payment_id = $(event.currentTarget).parent().attr('id').split('-')[1]
    $scope.payment_info = $(event.currentTarget).parents('li').find('.details span').text().replace('ending in', '****')
    ngDialog.open template: 'delete-payment-modal', controller: 'payment', className: 'warning', scope: $scope

  $scope.cancel_deletion = -> ngDialog.closeAll()

  $scope.delete_payment = (id) ->
    $http.put('/payments/delete', {
      payment_id: id
    }).success (rsp) ->
      if rsp.success
        $scope.$emit 'fetch_user'
        ngDialog.closeAll()
      else
        flash 'failure', rsp.message

  $scope.add_payment = ->
    if $scope.payment_method.id == 'credit-card'
      $scope.add_credit_card()
    else
      $scope.add_bank_account()

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

  $scope.open = (bank_only) ->
    if bank_only
      ngDialog.open template: 'add-bank-account-modal', className: 'success payment bank-acconut', scope: $scope
    else
      ngDialog.open template: 'add-payment-modal', className: 'success payment', scope: $scope

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
            $scope.bank = {}
            $scope.$emit 'fetch_user'
            ngDialog.closeAll()
          else
            flash 'failure', rsp.message

  $scope.add_bank_account = ->
    balanced.bankAccount.create $scope.bank, (rsp) ->
      if rsp.status_code != 201
        flash 'failure', rsp.errors[0].description
      else
        $http.post('/payments/add',{
          balanced_id: rsp.bank_accounts[0].id,
          payment_method: $scope.payment_method,
          spinner: true
        }).success (rsp) ->
          if rsp.success
            $scope.card = {}
            $scope.bank = {}
            $scope.$emit 'fetch_user'
            if $scope.user.role is 'host'
              angular.element('.payment.modal .steps .step.one').removeClass('active').addClass('hide')
              angular.element('.payment.modal .steps .step.two').removeClass('hide').addClass('active')
            else
              ngDialog.closeAll()

  $scope.open_verify = (event) ->
    $scope.payment_id = $(event.currentTarget).parent().attr('id').split('-')[1]
    ngDialog.open template: 'ach-verification-modal', className: 'success payment', scope: $scope

  $scope.verify = (id) ->
    if validate()
      $http.post('/payments/verify', {
        payment_id: id
        deposit1: $scope.deposit1,
        deposit2: $scope.deposit2,
        spinner: true
      }).success (rsp) ->
        if rsp.success
          $scope.$emit 'fetch_user'
          angular.element('.payment.modal .steps .step.one').removeClass('active').addClass('hide')
          angular.element('.payment.modal .steps .step.two').removeClass('hide').addClass('active')
        else
          flash 'failure', rsp.message
    else
      flash 'failure', 'Please fill in all required fields'

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
