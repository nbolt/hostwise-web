ContractorsCtrl = ['$scope', '$http', '$timeout', 'ngDialog', 'spinner', ($scope, $http, $timeout, ngDialog, spinner) ->

  promise = null

  $http.get('/data/markets').success (rsp) -> $scope.markets = rsp.markets

  $scope.fetch_contractors = ->
    spinner.startSpin()
    $http.get(window.location.href + '.json').success (rsp) ->
      $scope.users = rsp
      $scope.applicants = _($scope.users).filter (user) -> user.contractor_profile and user.contractor_profile.position_cd == 1
      $scope.contractors = _($scope.users).filter (user) -> user.contractor_profile and user.contractor_profile.position_cd == 2
      $scope.mentors = _($scope.users).filter (user) -> user.contractor_profile and user.contractor_profile.position_cd == 3
      _($scope.users).each (user) ->
        user.contract_status = if user.contractor_profile and user.contractor_profile.docusign_completed then 'Yes' else 'No'
        user.bgc_status = background_check_status(user)
      spinner.stopSpin()
      $timeout((->
        table = angular.element("#example-1").dataTable({
          aLengthMenu: [
            [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
          ]
        })
        $scope.table = table

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
      ),1000)

    $http.get('/dashboard/team_members').success (rsp) ->
      $scope.active_team_members   = rsp.active
      $scope.inactive_team_members = rsp.inactive
      $scope.new_team_members      = rsp.new
      $scope.highest_paid          = rsp.highest_paid

  $scope.show_signup = ->
    ngDialog.open template: 'sign-up', className: 'auth full'

  $scope.$watch 'search', (n,o) -> if o
    $timeout.cancel promise
    promise = $timeout (->
      $http.get('/data/contractors', {params: {term: n}}).success (rsp) -> $scope.users = rsp if $scope.users
    ), 400

  $scope.marketHash = ->
    {
    dropdownCssClass: 'details'
    minimumResultsForSearch: -1
    placeholder: 'Market'
    data: -> { results: _($scope.markets).map (market) -> { id: market.id, text: market.name } },
    initSelection: (el, cb) ->
    }

  $scope.$watch 'market', (n,o) -> if n
    angular.element('th.market input').val($scope.market.text).trigger($.Event 'change')

  background_check_status = (user) ->
    if user.background_check
      if user.background_check.status is 'clear'
        'Good'
      else if user.background_check.status is 'consider'
        'Flagged'
      else
        user.background_check.status
    else
      'N/A'

  flash = (type, msg, id) ->
    el = angular.element(id + ' .flash')
    el.removeClass('info success failure').addClass(type).css('opacity', 1).text(msg)
    $timeout((->
      el.css('opacity', 0)
    ), 3000)
    $timeout((->
      el.removeClass('info success failure')
    ), 4000)

  $scope.fetch_contractors()

]

app = angular.module('porter').controller('contractors', ContractorsCtrl)
