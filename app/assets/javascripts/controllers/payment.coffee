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

  $scope.delete_payment = (id) ->
    $http.put('/payments/delete', {
      payment_id: id
    }).success (rsp) ->
      if rsp.success
        $scope.$emit 'fetch_user'
      else
        flash 'failure', rsp.message, true

  $scope.add_payment = ->
    if $scope.payment_method.id == 'credit-card'
      Stripe.createToken
        number: angular.element(".payment-tab.credit-card input[data-stripe=number]").val()
        cvc: angular.element(".payment-tab.credit-card input[data-stripe=cvc]").val()
        exp_month: angular.element(".payment-tab.credit-card input[data-stripe=expiry]").val().split("/")[0]
        exp_year: angular.element(".payment-tab.credit-card input[data-stripe=expiry]").val().split("/")[1]
      , (_, rsp) ->
        if rsp.error
          flash "failure", rsp.error.message
        else
          $http.post('/payments/add',{stripe_id:rsp.id,payment_method:$scope.payment_method}).success (rsp) ->
            if rsp.success
              $scope.card = {}
              $scope.bank = {}
              $scope.$emit 'fetch_user'
              ngDialog.closeAll()
            else
              flash 'failure', rsp.message
    else
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

  $scope.$watch 'payment_method', (n,o) -> if o
    angular.element('.payment.modal .content .payment-tab').removeClass 'active'
    if n.id == 'credit-card'
      angular.element('.payment.modal .content.payment-tab.credit-card').addClass 'active'
    else
      angular.element('.payment.modal .content .payment-tab.ach').addClass 'active'

  $scope.open = ->
    ngDialog.open template: 'add-payment-modal', className: 'payment', scope: $scope

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
