PricingCtrl = ['$scope', '$http', '$timeout', 'ngDialog', ($scope, $http, $timeout, ngDialog) ->

    $http.get('/cost').success (rsp) ->
      $scope.pricing = rsp

    $scope.view_pricing = ->
      ngDialog.open template: 'full-pricing-modal', className: 'full-pricing'

    $scope.view_staging = ->
      ngDialog.open template: 'full-staging-modal', className: 'full-pricing'
]

app = angular.module('porter').controller('pricing', PricingCtrl)
