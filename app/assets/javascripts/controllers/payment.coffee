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
    angular.element('.payment.modal .content .payment-tab').removeClass 'active'
    if n.id == 'credit-card'
      angular.element('.payment.modal .content .payment-tab.credit-card').addClass 'active'
    else
      angular.element('.payment.modal .content .payment-tab.ach').addClass 'active'

  $scope.open = (bank_only) ->
    if bank_only
      ngDialog.open template: 'add-bank-account-modal', className: 'payment bank-acconut', scope: $scope
    else
      ngDialog.open template: 'add-payment-modal', className: 'payment', scope: $scope

  $scope.add_credit_card = ->
    Stripe.createToken
      number: angular.element(".payment-tab.credit-card input[data-stripe=number]").val()
      cvc: angular.element(".payment-tab.credit-card input[data-stripe=cvc]").val()
      exp_month: angular.element(".payment-tab.credit-card input[data-stripe=expiry]").val().split("/")[0]
      exp_year: angular.element(".payment-tab.credit-card input[data-stripe=expiry]").val().split("/")[1]
    , (_, rsp) ->
      if rsp.error
        flash 'failure', rsp.error.message
      else
        $http.post('/payments/add',{stripe_id:rsp.id,payment_method:$scope.payment_method}).success (rsp) ->
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
        $http.post('/payments/add',{balanced_id:rsp.bank_accounts[0].id,payment_method:$scope.payment_method}).success (rsp) ->
          if rsp.success
            $scope.card = {}
            $scope.bank = {}
            $scope.$emit 'fetch_user'
            ngDialog.closeAll()

  flash = (type, msg, parent) ->
    el = angular.element('.payment.modal .flash')
    el = angular.element('.payment-container .flash') if parent
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

]

app = angular.module('porter').controller('payment', PaymentCtrl)
