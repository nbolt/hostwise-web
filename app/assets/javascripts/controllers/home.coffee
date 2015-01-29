HomeCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.option = 'house'
  $scope.bedrooms = 0
  $scope.bathrooms = 0
  $scope.price = '0.00'

  $http.get('/cost').success (rsp) ->
    $scope.cost = rsp

  $scope.expand = (target) ->
    angular.element('.' + target).slideDown(600)
    return true

  $scope.testimonials = [
    {text:'Lorem ipsum dolor sit amet conseceteur doli consuale. Lorem ipsum dolor. Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet conseceteur doli consuale. Lorem ipsum dolor. Lorem ipsum dolor sit amet.', thumb: '/images/testimonial_thumb.png', name: 'Matt L.', company: 'LuxPads'},
    {text:'Lorem ipsum dolor sit amet conseceteur doli consuale. Lorem ipsum dolor. Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet.', thumb: '/images/testimonial_thumb.png', name: 'Ryan A.', company: 'AirBnB'},
    {text:'Lorem ipsum dolor sit amet conseceteur doli consuale. Lorem ipsum dolor. Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet conseceteur doli consuale. Lorem ipsum dolor. Lorem ipsum dolor sit amet...', thumb: '/images/testimonial_thumb.png', name: 'Chris A.', company: 'HomeAway'}
  ]

  $scope.house = ->
    $scope.option = 'house'
    angular.element('.pricing .options .house').addClass('active')
    angular.element('.pricing .options .condo').removeClass('active')
    cal_price $scope.option, $scope.bedrooms, $scope.bathrooms

  $scope.condo = ->
    $scope.option = 'condo'
    angular.element('.pricing .options .condo').addClass('active')
    angular.element('.pricing .options .house').removeClass('active')
    cal_price $scope.option, $scope.bedrooms, $scope.bathrooms

  $scope.$watch 'bedrooms', (n,o) -> if o
    $scope.bedrooms = n
    angular.element('.pricing .sliders .bedrooms').text(n)
    cal_price $scope.option, $scope.bedrooms, $scope.bathrooms

  $scope.$watch 'bathrooms', (n,o) -> if o
    $scope.bathrooms = n
    angular.element('.pricing .sliders .bathrooms').text(n)
    cal_price $scope.option, $scope.bedrooms, $scope.bathrooms

  cal_price = (option, bedrooms, bathrooms) -> #need to replace the formula
    cost = $scope.cost[option][bedrooms][bathrooms]
    if cost
      $scope.price = cost.toFixed(2)
    else if bedrooms is 0 && bathrooms is 0
      $scope.price = '0.00'
    else
      $scope.price = 'call us'

]

app = angular.module('porter').controller('home', HomeCtrl)
