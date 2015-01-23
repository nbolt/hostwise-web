JobsCtrl = ['$scope', '$http', 'ngDialog', ($scope, $http, ngDialog) ->
  
  $scope.tabs = [{name:'open'},{name:'upcoming'},{name:'past'}]
  $scope.filter = {id:'recent',text:'Most Recent'}

  $scope.tab = (name) ->
    angular.element('#jobs .tabs .tab').removeClass 'active'
    angular.element('#jobs .tab-content .tab').removeClass 'active'
    angular.element("#jobs .tabs .tab.#{name}").addClass 'active'
    angular.element("#jobs .tab-content .tab.#{name}").addClass 'active'
    null

  $scope.filters = ->
    {
      dropdownCssClass: 'details'
      minimumResultsForSearch: -1
      data: [{id:'recent',text:'Most Recent'}]
      initSelection: (el, cb) ->
    }

  refresh_jobs = ->
    _($scope.tabs).each (tab) ->
      $http.get('/data/jobs', {params: {scope: tab.name}}).success (rsp) ->
        if tab.name == 'open' && !tab.days # there's a better way to do this
          angular.element('.tab-content .tab:eq(0)').addClass 'active'
        tab.days = rsp
        _(tab.days).each (day) ->
          day.push {}
          date = moment.utc(day[0],"YYYY-MM-DD")
          date_text = date.format("ddd, MMM D")
          if date.month() == moment().month()
            if date.date() == moment().date()
              date_text += ', Today'
            else if date.date() == moment().date() + 1
              date_text += ', Tomorrow'
          day[2].date_text = date_text



  $scope.$watch 'filter', (n,o) -> if o
    refresh_jobs()

]

app = angular.module('porter').controller('jobs', JobsCtrl)
