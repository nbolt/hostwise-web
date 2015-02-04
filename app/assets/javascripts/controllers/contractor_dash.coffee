ContractorDashCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

  $scope.newbie = -> if !$scope.user then false else if $scope.user.jobs[0] then false else true 

  $scope.today = moment().format 'ddd, MMM D'

]

app = angular.module('porter').controller('contractor_dash', ContractorDashCtrl)
