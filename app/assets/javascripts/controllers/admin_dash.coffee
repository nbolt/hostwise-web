AdminDashCtrl = ['$scope', '$http', '$timeout', '$interval', '$q', '$window', 'ngDialog', ($scope, $http, $timeout, $interval, $q, $window, ngDialog) ->

  DEFAULT_LINE_CONFIG =
    fillColor: "rgba(151,187,205,0.2)"
    strokeColor: "rgba(151,187,205,1)"
    pointColor: "rgba(151,187,205,1)"
    pointStrokeColor: "#fff"
    pointHighlightFill: "#fff"
    pointHighlightStroke: "rgba(151,187,205,1)"

  $http.get('/dashboard/revenue').success (rsp) ->
    data = { labels: [], datasets: [DEFAULT_LINE_CONFIG] }
    $scope.total_monthly_revenue = rsp.total
    _($scope.range(rsp.num_weeks)).each (_, i) -> data.labels.push "Week #{i+1}"
    data.datasets[0].label = 'Revenue'
    data.datasets[0].data = rsp.data
    $scope.init_revenue data

  $http.get('/dashboard/serviced').success (rsp) ->
    data = { labels: [], datasets: [DEFAULT_LINE_CONFIG] }
    $scope.total_jobs_serviced = rsp.total
    _($scope.range(rsp.num_weeks)).each (_, i) -> data.labels.push "Week #{i+1}"
    data.datasets[0].label = 'Serviced'
    data.datasets[0].data = rsp.data
    $scope.init_serviced data

  $http.get('/dashboard/properties').success (rsp) ->
    data = { labels: [], datasets: [DEFAULT_LINE_CONFIG] }
    $scope.total_properties_serviced = rsp.total
    _($scope.range(rsp.num_weeks)).each (_, i) -> data.labels.push "Week #{i+1}"
    data.datasets[0].label = 'Properties'
    data.datasets[0].data = rsp.data
    $scope.init_properties data

  $http.get('/dashboard/hosts').success (rsp) ->
    data = { labels: [], datasets: [DEFAULT_LINE_CONFIG] }
    $scope.total_hosts_serviced = rsp.total
    _($scope.range(rsp.num_weeks)).each (_, i) -> data.labels.push "Week #{i+1}"
    data.datasets[0].label = 'Hosts'
    data.datasets[0].data = rsp.data
    $scope.init_hosts data

  $scope.init_revenue = (data) ->
    ctx = document.getElementById('chart-revenue').getContext '2d'
    chart = new Chart(ctx).Line(data)

  $scope.init_serviced = (data) ->
    ctx = document.getElementById('chart-serviced').getContext '2d'
    chart = new Chart(ctx).Line(data)

  $scope.init_properties = (data) ->
    ctx = document.getElementById('chart-properties').getContext '2d'
    chart = new Chart(ctx).Line(data)

  $scope.init_hosts = (data) ->
    ctx = document.getElementById('chart-hosts').getContext '2d'
    chart = new Chart(ctx).Line(data)

  $scope.range = (n) -> if n then _.range 0, n else []

]

app = angular.module('porter').controller('admin_dash', AdminDashCtrl)
