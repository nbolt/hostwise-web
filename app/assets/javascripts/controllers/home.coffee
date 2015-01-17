HomeCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.option = 'house'
  $scope.bedrooms = 0
  $scope.bathrooms = 0
  $scope.price = '0.00'

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
    if option is 'house'
      $scope.cost = bedrooms * 15 + bathrooms * 10
    else if option is 'condo'
      $scope.cost = bedrooms * 13 + bathrooms * 8
    $scope.price = $scope.cost.toFixed(2)

]

app = angular.module('porter').controller('home', HomeCtrl)
