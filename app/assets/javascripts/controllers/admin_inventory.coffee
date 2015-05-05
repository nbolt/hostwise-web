AdminInventoryCtrl = ['$scope', '$http', '$timeout', 'spinner', ($scope, $http, $timeout, spinner) ->

  $scope.export_csv = ->
    inventory = filtered_data('#example-1')
    $http.post('/inventory/export.csv', {inventory: inventory}).success (rsp) ->
      blob = new Blob([rsp],
        type: "application/octet-stream;charset=utf-8;",
      )
      saveAs(blob, "inventory.csv")

  filtered_data = (table) ->
    table = angular.element(table).dataTable()
    displayed = []
    currentlyDisplayed = table.fnSettings().aiDisplay
    _(currentlyDisplayed).each (index) -> displayed.push( table.fnGetData(index)[0] )
    #_(currentlyDisplayed).each (index) -> displayed.push( table.fnGetData(index)[0].match(/check-\d*/)[0].replace('check-', '') )
    displayed

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

]

app = angular.module('porter').controller('admin_inventory', AdminInventoryCtrl)