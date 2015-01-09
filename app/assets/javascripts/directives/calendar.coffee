app = angular.module('porter').directive('calendar', [->
  link: (scope, element) ->
    days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
    months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
    _month_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    scope.chosen_dates = {}
    
    gen_cal = (cal, month, year) ->
      calendar = element.find('table')
      calendar.find('thead th.month').attr('month', month)
      calendar.find('thead th.month').attr('year', year)
      first_day = new Date(year, month, 1).getDay()
      month_name = months[month]
      month_days = _month_days[month]
      month_days = if month == 1 && (year % 4 == 0 && year % 100 != 0 || year % 400 == 0) then 29 else month_days
      prev_month_days = if month == 0 then _month_days[11] else _month_days[month-1]
      prev_month_days = if month == 2 && (year % 4 == 0 && year % 100 != 0 || year % 400 == 0) then 29 else prev_month_days
      num_rows = if month_days + first_day > 35 then 6 else if first_day == 0 && month_days == 28 then 4 else 5

      calendar.find('tbody').remove()
      calendar.find('thead').after('<tbody></tbody>')
      calendar.find('.month_header th.month').text(month_name + ' ' + year)

      current_day = 0
      for row in [1..6]
        calendar.find('tbody').append('<tr class="week">')
        for day, i in days
          day = (current_day + 1) + '-' + month + '-' + year
          html = '<td ' +
            (if row == 1 && i < first_day
              'class="inactive day">' + (prev_month_days - ((first_day-1) - i))
             else if current_day >= month_days
              ++current_day
              'class="inactive day">' + (current_day - month_days)
             else if moment().diff(new Date(year, month, current_day), 'days') > 0
              ++current_day
              'class="past day">' + current_day
             else
               ++current_day
               'day="' + current_day + '" month="' + month + '" year="' + year + '" class="active day">' + current_day) + '</td>'
          calendar.find('tbody').append html
        calendar.find('tbody').append '</tr>'

      key = "#{month}-#{year}"
      _(scope.chosen_dates[key]).each (day) ->
        calendar.find("td.day.active[day='#{day}']").addClass('chosen')

    gen_cals = (dir) ->
      if dir is 'prev'
        scope.month = scope.month == 0 && 11 || scope.month-1
        scope.year = scope.month == 11 && scope.year-1 || scope.year
      else if dir is 'next'
        scope.month = if scope.month == 11 then 0 else scope.month+1
        scope.year = scope.month == 0 && scope.year+1 || scope.year
      else
        scope.month = moment().month()
        scope.year = moment().year()
      gen_cal(0, scope.month, scope.year)

    gen_cals()

    element.find('.arrow.prev').click -> gen_cals 'prev'
    element.find('.arrow.next').click -> gen_cals 'next'

    element.on('click', 'td.active', ->
      $this = angular.element(@)
      $this.addClass('selecting')
      $this.on('mouseleave.selecting', ->
        $this.off('mouseleave.selecting')
        $this.removeClass('selecting')
        key = "#{$this.attr('month')}-#{$this.attr('year')}"
        if $this.hasClass('chosen')
          $this.removeClass('chosen')
          scope.chosen_dates[key] = scope.chosen_dates[key].filter (d) -> d != $this.attr('day')
        else
          $this.addClass('chosen')
          scope.chosen_dates[key] = [] unless scope.chosen_dates[key] && scope.chosen_dates[key][0]
          scope.chosen_dates[key].push $this.attr('day')
      )
    )


  restrict: 'E'
  template: "
    <div class='arrows'>
      <div class='arrow prev'><div class='typcn'></div></div>
      <div class='arrow next'><div class='typcn'></div></div>
    </div>
    <div class='table'>
      <table>
        <thead>
          <tr class='month_header'>
            <th class='month' colspan='7'></th>
        </thead>
        <tbody></tbody>
      </table>
    </div>
  "
])