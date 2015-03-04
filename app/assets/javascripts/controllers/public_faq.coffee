PublicFaqCtrl = ['$scope', '$http', ($scope, $http) ->

  $http.get('/data/faq.yml').success (rsp) ->
    $scope.faqs = jsyaml.load(rsp)
    _($scope.faqs).each (faq) -> faq.count = faq.questions.length
    
    $scope.faqs.unshift
      name: 'all'
      display: 'All'
      count: _($scope.faqs).reduce(((acc, faq) -> acc + faq.questions.length), 0)
      questions: _(_($scope.faqs).map((faq) -> faq.questions)).flatten()

    $scope.chosen_faq = _($scope.faqs[0]).clone()
    $scope.chosen_faq.questions = _($scope.faqs[0].questions).clone()

  $scope.active = (faq) -> faq.name == $scope.chosen_faq.name && 'active' || ''

  $scope.toggle = (faq) ->
    $scope.chosen_faq = _(_($scope.faqs).find (f) -> f.name == faq.name).clone()
    $scope.chosen_faq.questions = _($scope.chosen_faq.questions).clone()

  $scope.search = ->
    $scope.chosen_faq.questions = _($scope.chosen_faq.questions).filter (faq) -> faq.question.match($scope.term) || faq.answer.match($scope.term)
    angular.element('body').scrollTo( angular.element("#faq"), 600 )

]

app = angular.module('porter').controller('public_faq', PublicFaqCtrl)
