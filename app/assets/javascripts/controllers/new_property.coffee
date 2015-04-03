NewPropertyCtrl = ['$scope', '$http', '$timeout', '$upload', '$location', 'spinner', 'ngDialog', ($scope, $http, $timeout, $upload, $location, spinner, ngDialog) ->

  $scope.num_steps = 3
  $scope.posting = false
  $scope.extras = {}
  $scope.form = {rental_type_cd: 0, property_type_cd: 0}
  $scope.form.twin_beds = {id:'0', text:'0'}
  $scope.form.full_beds = {id:'0', text:'0'}
  $scope.form.queen_beds = {id:'0', text:'0'}
  $scope.form.king_beds = {id:'0', text:'0'}

  $http.get('/user').success (rsp) ->
    if rsp
      $scope.user = rsp
      $scope.form.phone_number = $scope.user.phone_number

  $scope.init = ->
    $scope.form.zip = getParam('zip')

  $scope.rooms = ->
    {
    dropdownCssClass: 'details'
    minimumResultsForSearch: -1
    data: [{id:'0',text:'0'},{id:'1',text:'1'},{id:'2',text:'2'},{id:'3',text:'3'},{id:'4',text:'4'},{id:'5',text:'5'},{id:'6',text:'6'},{id:'7',text:'7'},{id:'8',text:'8'},{id:'9',text:'9'},{id:'10',text:'10'}]
    initSelection: (el, cb) ->
    }

  $scope.beds = ->
    {
    dropdownCssClass: 'details'
    minimumResultsForSearch: -1
    data: [{id:'0',text:'0'},{id:'1',text:'1'},{id:'2',text:'2'},{id:'3',text:'3'},{id:'4',text:'4'},{id:'5',text:'5'},{id:'6',text:'6'},{id:'7',text:'7'},{id:'8',text:'8'},{id:'9',text:'9'},{id:'10',text:'10'}]
    initSelection: (el, cb) ->
    }

  $scope.goto = (n) ->
    if n is 3
      return false if !validate(1) or !validate(2)
    else if n is 2
      return false if !validate(1)
    angular.element('.property-form-container .flash').removeClass('info success failure').empty()
    angular.element('.property-form-container .steps .step.active').removeClass('active').find('form').hide()
    angular.element('.property-form-container .steps .step').eq(n-1).addClass('active').find('form').show()
    angular.element('.property-form-container .step .step-nav').removeClass('active').eq(n-1).addClass('active')
    scrollToAccordion n
    return true

  $scope.$watch 'files', ->
    if $scope.files && $scope.files[0]
      spinner.startSpin()
      $upload.upload(
        url: '/properties/upload'
        file: $scope.files[0]
      ).success (rsp) ->
        spinner.stopSpin()
        if rsp.success
          angular.element('.preview').attr('src', rsp.image)
        else
          flash 'failure', rsp.message

  $scope.step = (n) ->
    if validate(n)
      if n == 3
        if !validate(1)
          $scope.goto(1)
          return
        else if !validate(2)
          $scope.goto(2)
          return

      post = ->
        unless $scope.posting
          $scope.posting = true
          spinner.startSpin()
          if $scope.files && $scope.files[0]
            $upload.upload(
              url: '/properties/build'
              file: $scope.files[0]
              data:
                stage: n
                form: $scope.form
                extras: $scope.extras
            ).success success_wrap
          else
            $http(
              url: '/properties/build'
              method: 'POST'
              data:
                stage: n
                form: $scope.form
                extras: $scope.extras
            ).success success_wrap

      if n < $scope.num_steps
        success = ->
          spinner.stopSpin()
          angular.element('.property-form-container .steps .step.active').removeClass('active').find('form').hide()
          angular.element('.property-form-container .steps .step').eq(n).addClass('active').find('form').show()
          angular.element('.property-form-container .step-nav.active').addClass('complete')
          angular.element('.property-form-container .step-nav').removeClass('active').eq(n).addClass('active')
          scrollToAccordion n
      else
        success = -> window.location = '/?f=1'

      success_wrap = (rsp) ->
        $scope.posting = false
        _($scope.extras).extend(rsp.extras)
        if rsp.success
          if rsp.slug
            $http.get("/properties/#{rsp.slug}.json").success (rsp) -> $scope.property = rsp
            analytics.track('Added a Property', {property_id: rsp.id})
          success()
          $scope.extras = {}
        else
          spinner.stopSpin()
          $scope.goto(1) if rsp.message.indexOf('address') > 0 or rsp.message.indexOf('photo') > 0
          flash(rsp.type || 'failure', rsp.message)

      post()
    else
      flash 'failure', 'Please fill in all required fields'
      return true

  $scope.address = (property) ->
    if property
      parts = property.full_address.split ','
      return parts[0] + ", <span class='city_state'>" + parts[1] + ", " + parts[2] + "</span>"

  $scope.add_property = -> window.location = '/properties/new'

  $scope.toProperty = (property) -> window.location = "/properties/#{property.slug}"

  $scope.quick_add = (property) ->
    $scope.redirect_to = '/'
    ngDialog.open template: 'booking-modal', className: 'booking', scope: $scope, closeByDocument: false
    $scope.property = property

    $timeout((->
      angular.element('.booking.modal .content.side').removeClass 'active'
      angular.element('.booking.modal .content.side.calendar').addClass 'active'
      $scope.$broadcast 'booking_selection'
    ),100)

  $scope.modal_calendar_options =
  {
    selectable: true
    clickable: true
    disable_past: true
    onchange: () ->
      if $scope.property
        _($scope.property.active_bookings).each (booking) ->
          date = moment.utc(booking.date)
          if $('.booking.modal')[0]
            angular.element(".booking.modal .calendar td.active.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive').attr('booking', booking.id)
          else
            $timeout((->
              angular.element(".booking.modal .calendar td.active.day[month=#{date.month()+1}][year=#{date.year()}][day=#{date.date()}]").removeClass('active').addClass('inactive').attr('booking', booking.id)
            ),100)

    onclick: ($this) ->
      return if $this.hasClass('chosen')
      $scope.selected_date = moment "#{$this.attr 'year'} #{$this.attr 'day'} #{parseInt($this.attr 'month')}", 'YYYY D MM'
      days_diff = $scope.selected_date.diff(moment().startOf('day'), 'days')
      hour = moment().hours()
      minute = moment().minutes()
      if days_diff == 0 and hour <= 14 and minute <= 59 #same day booking before 3pm
        $scope.$broadcast 'same_day_confirmation'
      else if days_diff == 1 and hour >= 22 #next day booking after 10pm
        $scope.$broadcast 'next_day_confirmation'
  }

  flash = (type, msg, el) ->
    el = angular.element('.property-form-container .step.active .flash') if !el
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)
    scroll 0

  validate = (n) ->
    if _(angular.element('.step.' + step(n)).find('input[required], textarea[required]')).filter((el) -> angular.element(el).val() == '')[0]
      false
    else
      return false if n is 2 and _(angular.element('.step.' + step(n)).find('.bed-types input')).filter((el) -> parseInt(angular.element(el).val()) > 0).length is 0
      true

  step = (n) ->
    switch n
      when 1
        step_num = 'one'
      when 2
        step_num = 'two'
      when 3
        step_num = 'three'
    return step_num

  scrollToAccordion = (n) ->
    scroll angular.element('.property-form-container .steps').find(".#{step(n)}").offset().top - 70

  scroll = (position) ->
    angular.element('body, html').animate
      scrollTop: position
    , 'fast'

  getParam = (name) ->
    decodeURIComponent name[1] if name = (new RegExp("[?&]" + encodeURIComponent(name) + "=([^&]*)")).exec(location.search)

]

app = angular.module('porter').controller('new_property', NewPropertyCtrl)
