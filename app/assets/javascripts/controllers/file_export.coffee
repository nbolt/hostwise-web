FileExportCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  $scope.chosen_dates = {}
  $scope.form = {start_date: '', end_date: ''}

  $scope.export = ->
    if validate()
      url = '/data/transactions.csv?' + 'scope=' + $scope.current_tab + '&start_date=' + $scope.form.start_date + '&end_date=' + $scope.form.end_date
      window.location = url
      ngDialog.closeAll()

  $scope.calendar = (event) ->
    $(event.currentTarget).siblings('.calendar').toggle()
    return true

  $scope.calendar_options1 =
  {
    selectable: true
    clickable: true
    selected_class: 'chosen'
    disable_past: false
    onchange: () ->

    onclick: ($this) ->
      date = moment "#{$this.attr 'year'} #{$this.attr 'day'} #{parseInt($this.attr 'month')}", 'YYYY D MM'
      $scope.selected_start_date = date
      $scope.$apply -> $scope.form.start_date = date.format('MM/DD/YYYY')
      refresh_calendar($this.parents('.calendar'), date)
  }

  $scope.calendar_options2 =
  {
    selectable: true
    clickable: true
    selected_class: 'chosen'
    disable_past: false
    onchange: () ->

    onclick: ($this) ->
      date = moment "#{$this.attr 'year'} #{$this.attr 'day'} #{parseInt($this.attr 'month')}", 'YYYY D MM'
      $scope.selected_end_date = date
      $scope.$apply -> $scope.form.end_date = date.format('MM/DD/YYYY')
      refresh_calendar($this.parents('.calendar'), date)
  }

  refresh_calendar = (calendar, date) ->
    $scope.chosen_dates = {}
    $scope.chosen_dates["#{date.month()}-#{date.year()}"] = [date.date()]
    calendar.find("td.active.day").removeClass('chosen')
    calendar.find("td.active.day[month=#{date.month()}][year=#{date.year()}][day=#{date.date()}]").addClass('chosen')
    calendar.hide()

  validate = ->
    valid = true
    if $scope.form.start_date is ''
      flash 'failure', 'Please enter a start date'
      valid = false
    else if $scope.form.end_date is ''
      flash 'failure', 'Please enter an end date'
      valid = false
    else if moment($scope.selected_end_date).diff(moment($scope.selected_start_date), 'days') < 0
      flash 'failure', "End date can't be earlier than start date"
      valid = false
    return valid

  flash = (type, msg) ->
    el = angular.element('.modal .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0).removeClass('info success failure')
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)
]

app = angular.module('porter').controller('file-export', FileExportCtrl)
