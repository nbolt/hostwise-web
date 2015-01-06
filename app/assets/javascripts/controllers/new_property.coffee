NewPropertyCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.posting = false
  $scope.chosen_dates    = {}
  $scope.chosen_services = {}
  $scope.extras          = {}

  $http.get('/data/services').success (rsp) -> $scope.services = rsp
  $http.get('/data/payments').success (rsp) ->
    $scope.payments = rsp
    $scope.stripe_id = $scope.payments[0].stripe_id if $scope.payments[0]

  $scope.cities = ->
    {
      dropdownCssClass: 'cities'
      data: []
      initSelection: (el, cb) ->
      formatResult: (obj, container, query) -> "#{obj.text}<div class='state'>#{obj.county}, #{obj.state}</div>"
      ajax:
        url: "/data/cities"
        data: (term) -> { term: term }
        quietMillis: 400
        results: (data) -> { results: _(data).map (c) -> { id: c.id, text: c.name, state: c.state.abbr, county: c.county.name } }
    }

  $scope.bedrooms = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: 8
      data: [{id:'0',text:'None'},{id:'1',text:'1 Bedroom'},{id:'2',text:'2 Bedrooms'},{id:'3',text:'3 Bedrooms'},{id:'4',text:'4 Bedrooms'}]
      initSelection: (el, cb) ->
    }

  $scope.beds = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: 8
      data: [{id:'0',text:'None'},{id:'1',text:'1 Bed'},{id:'2',text:'2 Beds'},{id:'3',text:'3 Beds'},{id:'4',text:'4 Beds'}]
      initSelection: (el, cb) ->
    }

  $scope.accommodates = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: 8
      data: [{id:'1',text:'1 Person'},{id:'2',text:'2 People'},{id:'3',text:'3 People'},{id:'4',text:'4 People'}]
      initSelection: (el, cb) ->
    }

  $scope.show_existing = -> if $scope.stripe_id then true  else false
  $scope.show_new      = -> if $scope.stripe_id then false else true
  $scope.show_existing_class = -> if $scope.show_existing() then 'active' else 'inactive'
  $scope.show_new_class      = -> if $scope.show_new()      then 'active' else 'inactive'

  $scope.select_payment = (id) -> $scope.stripe_id = id

  $scope.tab = (tab) ->
    switch tab
      when 'existing'
        angular.element('.existing .payment input').iCheck('uncheck')
        angular.element('.existing .payment:eq(0) input').iCheck('check')
        $scope.stripe_id = $scope.payments[0].id
      when 'new'
        $scope.stripe_id = null

  $scope.skip = (n) ->
    switch n
      when 2
        angular.element('#property-form-container .steps').css('margin-left', -(4 * 600))
        angular.element('.step-circles .step').removeClass('active').eq(4).addClass('active')
    null

  $scope.step = (n) ->
    if validate(n)
      post = ->
        unless $scope.posting
          $scope.posting = true
          $http.post('/properties/build', {
            stage: n
            form: $scope.form
            property_id: $scope.property_id
            chosen_dates: $scope.chosen_dates
            chosen_services: $scope.chosen_services
            stripe_token: $scope.stripe_token
            stripe_id: $scope.stripe_id
            extras: $scope.extras
          }).success (rsp) ->
            $scope.posting = false
            _($scope.extras).extend(rsp.extras)
            if rsp.success
              success()
              $scope.property_id = rsp.property_id
              $scope.extras = {}
            else
              flash(rsp.type || 'failure', rsp.message)

      if n < 5
        success = ->
          angular.element('#property-form-container .steps').css('margin-left', -(n * 600))
          angular.element('.step-circles .step').removeClass('active').eq(n).addClass('active')
      else
        success = -> window.location = '/'

      angular.element('.existing .payment:eq(0) input').iCheck('check') if n == 3 && $scope.stripe_id
      if n == 4 && !$scope.stripe_id
        Stripe.createToken {
          number: angular.element('.new-payment input[data-stripe=number]').val()
          cvc: angular.element('.new-payment input[data-stripe=cvc]').val()
          exp_month: angular.element('.new-payment input[data-stripe=expiry]').val().split('/')[0]
          exp_year: angular.element('.new-payment input[data-stripe=expiry]').val().split('/')[1]
        }, (_, rsp) ->
          if rsp.error
            flash 'failure', rsp.error.message
          else
            $scope.stripe_token = rsp.id
            post()
      else
        post()

  flash = (type, msg) ->
    angular.element('#property-form-container .flash').removeClass('success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      angular.element('#property-form-container .flash').css('opacity', 0).removeClass('info success failure')
    ), 3000)

  validate = (n) ->
    switch n
      when 1
        step_num = 'one'
      when 2
        step_num = 'two'
      when 3
        step_num = 'three'
      when 4
        step_num = 'four'
    if _(angular.element('.step.' + step_num).find('input[required]')).filter((el) -> angular.element(el).val() == '')[0]
      flash('failure', 'Please fill in all required fields')
      false
    else
      true

]

app = angular.module('porter').controller('new_property', NewPropertyCtrl)
