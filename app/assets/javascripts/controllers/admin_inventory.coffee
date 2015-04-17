AdminInventoryCtrl = ['$scope', '$http', '$timeout', 'spinner', ($scope, $http, $timeout, spinner) ->

  promise = null
  $scope.filter = {id:'all',text:'All'}
  $scope.search = ''

  $scope.fetch_jobs = ->
    spinner.startSpin()
    $http.get('/inventory.json',{params: {search: $scope.search, filter: $scope.filter.id}}).success (rsp) ->
      $scope.jobs = rsp.inventory

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
            date       = moment(data[3], 'MM/DD/YYYY')

            date >= start_date && date <= end_date

        angular.element('#example-1 thead.search th').each (index) ->
          unless angular.element(@).html() == ''
            if angular.element(@).html() == 'Date'
              angular.element(@).html "<input><input>"
              angular.element(@).children('input').on 'keyup change', -> table.fnDraw()
              angular.element(@).children('input').datepicker()
            else
              angular.element(@).html "<input>"
              angular.element(@).children('input').on 'keyup change', ->
                table.fnFilter angular.element(@).val(), index
      ),500)


  $scope.$watch 'filter.id', (n,o) -> $scope.fetch_jobs() if o != undefined && o != n

  $scope.$watch 'search', (n,o) -> if o != undefined && o != n
    $timeout.cancel promise
    promise = $timeout (->
      $scope.search = n
      $scope.fetch_jobs()
    ), 400

  $scope.fetch_jobs()

]

app = angular.module('porter').controller('admin_inventory', AdminInventoryCtrl)