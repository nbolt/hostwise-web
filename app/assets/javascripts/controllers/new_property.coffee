NewPropertyCtrl = ['$scope', '$http', '$timeout', '$upload', '$location', ($scope, $http, $timeout, $upload, $location) ->

  $scope.num_steps = 3
  $scope.posting = false
  $scope.extras = {}
  $scope.form = {}

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
      data: [{id:'0',text:'0'},{id:'1',text:'1'},{id:'2',text:'2'},{id:'3',text:'3'},{id:'4',text:'4'},{id:'5',text:'5'}]
      initSelection: (el, cb) ->
    }

  $scope.beds = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:'0',text:'0'},{id:'1',text:'1'},{id:'2',text:'2'},{id:'3',text:'3'},{id:'4',text:'4'},{id:'5',text:'5'}]
      initSelection: (el, cb) ->
    }

  $scope.property_type = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:0,text:'House'},{id:1,text:'Condo'},{id:2,text:'Apartment'}]
      initSelection: (el, cb) ->
    }

  $scope.rental_type = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:0,text:'Full-time'},{id:1,text:'Part-time'}]
      initSelection: (el, cb) ->
    }

  $scope.goto = (n) ->
    angular.element('.property-form-container .flash').removeClass('info success failure').empty()
    angular.element('.property-form-container .steps').css('margin-left', -((n-1) * 900))
    angular.element('.property-form-container .steps .step.active').removeClass('active')
    angular.element('.property-form-container .steps .step').eq(n-1).addClass('active')
    angular.element('.step-nav .step').removeClass('active').eq(n-1).addClass('active')
    scroll 0
    return true

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
          angular.element('.property-form-container .steps').css('margin-left', -(n * 900))
          angular.element('.property-form-container .steps .step.active').removeClass('active')
          angular.element('.property-form-container .steps .step').eq(n).addClass('active')
          angular.element('.step-nav .step.active').addClass('complete')
          angular.element('.step-nav .step').removeClass('active').eq(n).addClass('active')
          scroll 0
      else
        success = -> window.location = '/'

      success_wrap = (rsp) ->
        $scope.posting = false
        _($scope.extras).extend(rsp.extras)
        if rsp.success
          success()
          $scope.extras = {}
        else
          $scope.goto(1) if rsp.message.indexOf('address') > 0 or rsp.message.indexOf('photo') > 0
          flash(rsp.type || 'failure', rsp.message)

      post()
    else
      flash 'failure', 'Please fill in all required fields'
      return true

  flash = (type, msg) ->
    angular.element('.property-form-container .step.active .flash').removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      angular.element('.property-form-container .step.active .flash').css('opacity', 0)
    ), 3000)
    $timeout((->
      angular.element('.property-form-container .step.active .flash').removeClass('info success failure')
    ), 4000)
    scroll 0

  validate = (n) ->
    switch n
      when 1
        step_num = 'one'
      when 2
        step_num = 'two'
      when 3
        step_num = 'three'
    if _(angular.element('.step.' + step_num).find('input[required], textarea[required]')).filter((el) -> angular.element(el).val() == '')[0]
      false
    else
      true

  scroll = (position) ->
    angular.element('body, html').animate
      scrollTop: position
    , 'fast'

  getParam = (name) ->
    decodeURIComponent name[1] if name = (new RegExp("[?&]" + encodeURIComponent(name) + "=([^&]*)")).exec(location.search)

]

app = angular.module('porter').controller('new_property', NewPropertyCtrl)
