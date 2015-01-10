NewPropertyCtrl = ['$scope', '$http', '$timeout', '$upload', ($scope, $http, $timeout, $upload) ->

  $scope.posting = false
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

  $scope.type = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: 8
      data: [{id:'house',text:'House'},{id:'townhouse',text:'Townhouse'},{id:'apartment',text:'Apartment'}]
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
        angular.element('#property-form-container .steps').css('margin-left', -(4 * 768))
        angular.element('.step-circles .step').removeClass('active').eq(4).addClass('active')
    null

  $scope.step = (n) ->
    if validate(n)
      post = ->
        unless $scope.posting
          $scope.posting = true
          if $scope.files && $scope.files[0]
            $upload.upload(
              url: '/properties/build'
              file: $scope.files[0]
              data:
                stage: n
                form: $scope.form
                property_id: $scope.property_id
                stripe_token: $scope.stripe_token
                stripe_id: $scope.stripe_id
                extras: $scope.extras
            ).success success_wrap
          else
            $http(
              url: '/properties/build'
              method: 'POST'
              data:
                stage: n
                form: $scope.form
                property_id: $scope.property_id
                stripe_token: $scope.stripe_token
                stripe_id: $scope.stripe_id
                extras: $scope.extras
            ).success success_wrap

      if n < 3
        success = ->
          angular.element('#property-form-container .steps').css('margin-left', -(n * 768))
          angular.element('#property-form-container .steps .step.active').removeClass('active')
          angular.element('#property-form-container .steps .step').eq(n).addClass('active')
          angular.element('.step-nav .step.active').addClass('complete')
          angular.element('.step-nav .step').removeClass('active').eq(n).addClass('active')
      else
        success = -> window.location = '/'

      success_wrap = (rsp) ->
        $scope.posting = false
        _($scope.extras).extend(rsp.extras)
        if rsp.success
          success()
          $scope.property_id = rsp.property_id
          $scope.extras = {}
        else
          flash(rsp.type || 'failure', rsp.message)

      angular.element('.existing .payment:eq(0) input').iCheck('check') if n == 3 && $scope.stripe_id
      if n == 3 && !$scope.stripe_id
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
    angular.element('#property-form-container .step.active .flash').removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      angular.element('#property-form-container .step.active .flash').css('opacity', 0)
    ), 3000)
    $timeout((->
      angular.element('#property-form-container .step.active .flash').removeClass('info success failure')
    ), 4000)

  validate = (n) ->
    switch n
      when 1
        step_num = 'one'
      when 2
        step_num = 'two'
      when 3
        step_num = 'three'
    if _(angular.element('.step.' + step_num).find('input[required]')).filter((el) -> angular.element(el).val() == '')[0]
      flash('failure', 'Please fill in all required fields')
      false
    else
      true

]

app = angular.module('porter').controller('new_property', NewPropertyCtrl)
