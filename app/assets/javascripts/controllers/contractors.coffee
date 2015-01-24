ContractorsCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  $scope.form = {email: '', first_name: '', last_name: '', phone_number: ''}

  $scope.$on 'fetch_contractors', ->
    $http.get(window.location.href + '.json').success (rsp) ->
      $scope.users = rsp

  $scope.$emit 'fetch_contractors'

  $scope.sorters = ->
    {
    dropdownCssClass: 'sorters'
    minimumResultsForSearch: -1
    data: [{id:'sort_by',text:'Sort By'},{id:'name',text:'Name'},{id:'status',text:'Status'},{id:'recently_joined',text:'Recently Joined'}]
    initSelection: (el, cb) -> cb {id:'sort_by',text:'Sort By'}
    }

  $scope.show_signup = ->
    ngDialog.open template: 'sign-up', className: 'auth'

  $scope.add_contractor = ->
    $http.post('/contractor/signup', {
      form: $scope.form
    }).success (rsp) ->
      if rsp.success
        window.location = window.location.href
      else
        flash('failure', rsp.message, '.default')

  flash = (type, msg, id) ->
    el = angular.element(id + ' .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

]

app = angular.module('porter').controller('contractors', ContractorsCtrl)
