AdminDashCtrl = ['$scope', '$http', '$timeout', '$interval', '$q', '$window', 'ngDialog', ($scope, $http, $timeout, $interval, $q, $window, ngDialog) ->

  MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']

  DEFAULT_LINE_CONFIG =
    fillColor: "#2BAAB1"
    strokeColor: "#218588"

  $http.get('/dashboard/revenue').success (rsp) ->
    data = { labels: [], datasets: [DEFAULT_LINE_CONFIG] }
    $scope.total_revenue = rsp.total
    _(rsp.data).each (d) -> data.labels.push(MONTHS[d.month-1] + " '" + d.year)
    data.datasets[0].label = 'Revenue'
    data.datasets[0].data = _(rsp.data).map (d) -> d.revenue
    $scope.init_revenue data

  $http.get('/dashboard/payouts').success (rsp) ->
    data = { labels: [], datasets: [DEFAULT_LINE_CONFIG] }
    $scope.total_payouts = rsp.total
    _(rsp.data).each (d) -> data.labels.push(MONTHS[d.month-1] + " '" + d.year)
    data.datasets[0].label = 'Payouts'
    data.datasets[0].data = _(rsp.data).map (d) -> d.payouts
    $scope.init_payouts data

  $http.get('/dashboard/serviced').success (rsp) ->
    data = { labels: [], datasets: [DEFAULT_LINE_CONFIG] }
    $scope.total_jobs_serviced = rsp.total
    _(rsp.data).each (d) -> data.labels.push(MONTHS[d.month-1] + " '" + d.year)
    data.datasets[0].label = 'Serviced'
    data.datasets[0].data = _(rsp.data).map (d) -> d.serviced
    $scope.init_serviced data

  $http.get('/dashboard/properties').success (rsp) ->
    data = { labels: [], datasets: [DEFAULT_LINE_CONFIG] }
    $scope.total_properties_serviced = rsp.total
    _(rsp.data).each (d) -> data.labels.push(MONTHS[d.month-1] + " '" + d.year)
    data.datasets[0].label = 'Properties'
    data.datasets[0].data = _(rsp.data).map (d) -> d.properties
    $scope.init_properties data

  $http.get('/dashboard/hosts').success (rsp) ->
    data = { labels: [], datasets: [DEFAULT_LINE_CONFIG] }
    $scope.total_hosts_serviced = rsp.total
    _(rsp.data).each (d) -> data.labels.push(MONTHS[d.month-1] + " '" + d.year)
    data.datasets[0].label = 'Hosts'
    data.datasets[0].data = _(rsp.data).map (d) -> d.hosts
    $scope.init_hosts data

  $scope.init_revenue = (data) ->
    ctx = document.getElementById('chart-revenue').getContext '2d'
    chart = new Chart(ctx).Line(data, {bezierCurve: false, pointDot: false})

  $scope.init_payouts = (data) ->
    ctx = document.getElementById('chart-payouts').getContext '2d'
    chart = new Chart(ctx).Line(data, {bezierCurve: false, pointDot: false})

  $scope.init_serviced = (data) ->
    ctx = document.getElementById('chart-serviced').getContext '2d'
    chart = new Chart(ctx).Line(data, {bezierCurve: false, pointDot: false})

  $scope.init_properties = (data) ->
    ctx = document.getElementById('chart-properties').getContext '2d'
    chart = new Chart(ctx).Line(data, {bezierCurve: false, pointDot: false})

  $scope.init_hosts = (data) ->
    ctx = document.getElementById('chart-hosts').getContext '2d'
    chart = new Chart(ctx).Line(data, {bezierCurve: false, pointDot: false})

]

app = angular.module('porter').controller('admin_dash', AdminDashCtrl)
