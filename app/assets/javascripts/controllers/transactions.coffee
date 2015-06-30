TransactionsCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  $scope.tabs = [{name:'completed'},{name:'upcoming'}]

  $scope.$on 'fetch_transactions', ->
    _($scope.tabs).each (tab) ->
      $http.get('/data/transactions.json', {params: {scope: tab.name}}).success (rsp) ->
        if tab.name is 'completed'
          tab.transactions = rsp
          $scope.tab tab.name
          _(tab.transactions).each (transaction) ->
            transaction.bookings = _(transaction.bookings).select (booking) -> booking.user.id == $scope.user.id
            transaction.date = transaction.charged_at || transaction.created_at
            transaction.properties = _(transaction.bookings).map((booking) -> booking.property.nickname).join ', '
            transaction.payment = transaction.bookings[0].payment
            transaction.total = (transaction.amount / 100).toFixed(2)
        else if tab.name is 'upcoming'
          tab.transactions = JSON.parse(rsp.properties)
          tab.transactions = tab.transactions.concat JSON.parse(rsp.bookings)
          _(tab.transactions).each (transaction) ->
            transaction.nickname = transaction.property.nickname if transaction.property
            transaction.payment = transaction.user.primary_payment unless transaction.payment
            transaction.date = transaction.purchase_date if transaction.purchase_date
            transaction.total = transaction.cost || 299 * transaction.beds

  $scope.user_fetched.promise.then -> $scope.$emit 'fetch_transactions'

  $scope.tab = (name) ->
    tabs = angular.element('.transaction-container .tabs')
    tabs.find('.tab').removeClass 'active'
    tabs.find(".tab.#{name}").addClass 'active'
    tab_content = angular.element('.transaction-container .tab-content')
    tab_content.find('.tab').removeClass 'active'
    tab_content.find(".tab.#{name}").addClass 'active'
    $scope.current_tab = name
    return true

  $scope.open_export = ->
    ngDialog.open template: 'file-export-modal', className: 'export full', scope: $scope

  $scope.breakdown_modal = (transaction) ->
    $http.get("/transactions/#{transaction.id}").success (rsp) ->
      $scope.booking = rsp.booking
      #$scope.total = _($scope.bookings).reduce(((acc, booking) -> acc + booking.cost), 0)
      ngDialog.open template: 'transaction-breakdown-modal', className: 'edit full', scope: $scope

  $scope.service_cost = (booking, service) -> booking["#{service.name}_cost"]

  $scope.cancel_process = -> ngDialog.closeAll()

  booked_services = (services) ->
    arr = []
    _(services).each (service) -> arr.push service.display
    return arr.join ', '
]

app = angular.module('porter').controller('transactions', TransactionsCtrl)
