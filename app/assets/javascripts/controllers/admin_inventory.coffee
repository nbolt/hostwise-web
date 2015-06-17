AdminInventoryCtrl = ['$scope', '$http', '$timeout', 'spinner', ($scope, $http, $timeout, spinner) ->

  $scope.fetch_properties = ->
    spinner.startSpin()
    $http.get('/properties.json').success (rsp) ->
      $scope.properties = rsp
      $scope.total_linen_sets = _(rsp).reduce(((a, p) -> a + p.linen_count),0)
      spinner.stopSpin()
      $timeout((->
        angular.element("#example-1").dataTable({
          aLengthMenu: [
            [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
          ]
        })
      ),1000)

  $scope.fetch_jobs = ->
    table = angular.element("#example-2").dataTable({
      aLengthMenu: [
        [10, 25, 50, 100, -1], [10, 25, 50, 100, "All"]
      ]
      aoColumns: [{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false},{bSortable:false}]
      serverSide: true
      ajax: (data, cb, settings) ->
        $http.post('/inventory/jobs.json', {data:data}).success (rsp) ->
          $scope.jobs = JSON.parse rsp.jobs
          data_jobs = _($scope.jobs).map (job) -> ["<a href='/jobs/#{job.id}' class='teal'>#{job.id}</a>", "<a href='/properties/#{job.booking.property.id}' class='teal'>#{job.booking.property.nickname}</a>", job.booking.property.property_size, job.booking.property.neighborhood_address, job.booking.service_list, job.date, job.contractor_names, "#{job.king_bed_count} / #{job.soiled_king_count}", "#{job.twin_bed_count} / #{job.soiled_twin_count}", "#{job.pillow_count} / #{job.soiled_pillow_count}", "#{job.bath_towel_count} / #{job.soiled_bath_towel_count}", "#{job.bath_mat_count} / #{job.soiled_mat_count}", "#{job.hand_towel_count} / #{job.soiled_hand_count}", "#{job.face_towel_count} / #{job.soiled_face_count}"]
          cb({data:data_jobs,recordsTotal:rsp.total,recordsFiltered:rsp.filtered})
    })

  $scope.fetch_jobs()
  $scope.fetch_properties()

]

app = angular.module('porter').controller('admin_inventory', AdminInventoryCtrl)
