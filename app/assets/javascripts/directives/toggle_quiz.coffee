app = angular.module('porter').directive('toggleQuiz', [-> (scope, element, attrs) ->
  element.on 'change', ->
    arr = attrs.toggleQuiz.split '.'
    question_idx = arr[0]
    answer_idx = arr[1]
    if element.is(':checked')
      arr = scope.selected_answers[question_idx]
      scope.selected_answers[question_idx] = [] unless arr
      scope.$apply -> scope.selected_answers[question_idx].push answer_idx
    else
      scope.selected_answers[question_idx] = _.without(scope.selected_answers[question_idx], answer_idx)
])
