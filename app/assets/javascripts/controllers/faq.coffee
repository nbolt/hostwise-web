FaqCtrl = ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.expand = (q) ->
    elh = angular.element('.h' + q)
    elc = angular.element('.c' + q)
    if elc.hasClass('active')
      elc.removeClass('active')
      elc.slideUp 400
      elh.find('.fa').removeClass('fa-chevron-down').addClass('fa-chevron-right')
    else
      elc.addClass('active')
      elc.slideDown 400
      elh.find('.fa').removeClass('fa-chevron-right').addClass('fa-chevron-down')
    return true

]

app = angular.module('porter').controller('faq', FaqCtrl)
