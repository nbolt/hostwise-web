NewPropertyCtrl = ['$scope', '$http', '$timeout', '$upload', '$location', ($scope, $http, $timeout, $upload, $location) ->

  $scope.num_steps = 2
  $scope.posting = false
  $scope.extras = {}

  $scope.init = ->
    $scope.form = {zip: getParam('zip'), address1: getParam('address1')}

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

  $scope.type = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:'house',text:'House'},{id:'condo',text:'Condo'},{id:'apartment',text:'Apartment'}]
      initSelection: (el, cb) ->
    }

  $scope.previous = (n) ->
    angular.element('#property-form-container .flash').removeClass('info success failure').empty()
    angular.element('#property-form-container .steps').css('margin-left', -((n-1) * 768))
    angular.element('#property-form-container .steps .step.active').removeClass('active')
    angular.element('#property-form-container .steps .step').eq(n-1).addClass('active')
    angular.element('.step-nav .step').removeClass('active').eq(n-1).addClass('active')
    scroll 0
    return true

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
          angular.element('#property-form-container .steps').css('margin-left', -(n * 768))
          angular.element('#property-form-container .steps .step.active').removeClass('active')
          angular.element('#property-form-container .steps .step').eq(n).addClass('active')
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
          flash(rsp.type || 'failure', rsp.message)

      post()

  flash = (type, msg) ->
    angular.element('#property-form-container .step.active .flash').removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      angular.element('#property-form-container .step.active .flash').css('opacity', 0)
    ), 3000)
    $timeout((->
      angular.element('#property-form-container .step.active .flash').removeClass('info success failure')
    ), 4000)
    scroll 0

  validate = (n) ->
    switch n
      when 1
        step_num = 'one'
      when 2
        step_num = 'two'
    if _(angular.element('.step.' + step_num).find('input[required]')).filter((el) -> angular.element(el).val() == '')[0]
      flash('failure', 'Please fill in all required fields')
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
