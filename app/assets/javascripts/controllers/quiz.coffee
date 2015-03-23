QuizCtrl = ['$scope', '$http', 'spinner', ($scope, $http, spinner) ->

  $scope.selected_answers = {}
  $scope.current_q = 1
  $scope.max_q = 1
  $scope.passing_score = 100

  $http.get('/quiz/type').success (rsp) ->
    quiz_type = rsp.type
    $http.get('/data/quiz.yml').success (rsp) ->
      $scope.quizzes = jsyaml.load(rsp)
      _($scope.quizzes).each (quiz) -> quiz.count = quiz.questions.length
      if quiz_type is 'basic'
        $scope.chosen_quizzes = _($scope.quizzes[0]).clone()
        $scope.chosen_quizzes.questions = _($scope.quizzes[0].questions).clone()
      else #advanced
        $scope.chosen_quizzes = _($scope.quizzes[1]).clone()
        $scope.chosen_quizzes.questions = _($scope.quizzes[1].questions).clone()
      $scope.chosen_quizzes.questions = _($scope.chosen_quizzes.questions).shuffle()
      $scope.chosen_quizzes.questions = _($scope.chosen_quizzes.questions).first($scope.max_q)

  $scope.total_q = ->
    return new Array($scope.max_q)

  $scope.question_class = (index) ->
    if index is 1
      "q#{index} active"
    else
      "q#{index}"

  $scope.next = ->
    if $scope.current_q is $scope.max_q
      report()
    else
      $scope.current_q++
      show()
    scroll 0
    return false

  $scope.last = ->
    unless $scope.current_q is 1
      $scope.current_q--
      show()
    scroll 0
    return false

  $scope.claim = ->
    spinner.startSpin()
    window.location = '/jobs'

  $scope.retake = ->
    spinner.startSpin()
    window.location = '/quiz'

  calculate_score = ->
    score = 0
    _($scope.chosen_quizzes.questions).each (question) ->
      answers = $scope.selected_answers[question.id]
      correct_answers = _(question.answers).map((answer) -> answer.toString())
      if _.isEqual(answers, correct_answers)
        score += $scope.passing_score / $scope.max_q
    return score

  report = ->
    $scope.score = calculate_score()
    pass = $scope.score >= $scope.passing_score
    angular.element('.step1').hide()
    angular.element('.progress .bar').addClass('active')
    $http.post('/quiz/report', { score: $scope.score, pass: pass }).success (rsp) ->
      if pass
        angular.element('.report.pass').show()
      else
        angular.element('.report.fail').show()

  show = ->
    angular.element('.questions .q').removeClass('active')
    angular.element(".questions .q.q#{$scope.current_q}").addClass('active')
    angular.element('.progress .bar').removeClass('active')
    angular.element(".progress .bar:lt(#{$scope.current_q})").addClass('active')

  scroll = (position) ->
    angular.element('body, html').animate
      scrollTop: position
    , 'fast'

]

app = angular.module('porter').controller('quiz', QuizCtrl)
