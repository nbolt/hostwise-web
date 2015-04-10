ContractorsCtrl = ['$scope', '$http', '$timeout', 'ngDialog', 'spinner', ($scope, $http, $timeout, ngDialog, spinner) ->

  promise = null

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
        angular.element("#example-1").dataTable({
          aLengthMenu: [
            [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
          ]
        })
      ),1000)

  $scope.show_signup = ->
    ngDialog.open template: 'sign-up', className: 'auth full'

  $scope.$watch 'search', (n,o) -> if o
    $timeout.cancel promise
    promise = $timeout (->
      $http.get('/data/contractors', {params: {term: n}}).success (rsp) -> $scope.users = rsp if $scope.users
    ), 400

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
