TransactionsCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.tabs = [{name:'completed'},{name:'upcoming'}]

  $scope.$on 'fetch_transactions', ->
    _($scope.tabs).each (tab) ->
      $http.get('/data/transactions', {params: {scope: tab.name}}).success (rsp) ->
        tab.transactions = rsp
        if tab.name is 'completed'
          $scope.tab tab.name
          _(tab.transactions).each (transaction) ->
            transaction.date = transaction.booking.date
            transaction.property = transaction.booking.property.nickname
            transaction.services = booked_services transaction.booking.services
            transaction.payment = transaction.booking.payment.last4
            transaction.total = (transaction.amount / 100).toFixed(2)
        else if tab.name is 'upcoming'
          _(tab.transactions).each (transaction) ->
            transaction.date = transaction.date
            transaction.property = transaction.property.nickname
            transaction.services = booked_services transaction.services
            transaction.payment = transaction.payment.last4
            transaction.total = transaction.cost.toFixed(2)

  $scope.$emit 'fetch_transactions'

  $scope.tab = (name) ->
    tabs = angular.element('.transaction-container .tabs')
    tabs.find('.tab').removeClass 'active'
    tabs.find(".tab.#{name}").addClass 'active'
    tab_content = angular.element('.transaction-container .tab-content')
    tab_content.find('.tab').removeClass 'active'
    tab_content.find(".tab.#{name}").addClass 'active'
    return true

  booked_services = (services) ->
    arr = []
    _(services).each (service) -> arr.push service.display
    return arr.join ', '
]

app = angular.module('porter').controller('transactions', TransactionsCtrl)
