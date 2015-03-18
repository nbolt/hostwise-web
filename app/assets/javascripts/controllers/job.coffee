JobCtrl = ['$scope', '$http', '$timeout', '$interval', '$window', '$q', '$upload', 'ngDialog', ($scope, $http, $timeout, $interval, $window, $q, $upload, ngDialog) ->

  $scope.jobQ = $q.defer()
  $scope.job_status = 'blocked'
  $scope.active_bedroom = 1
  $scope.active_bathroom = 1

  $http.get($window.location.href + '.json').success (rsp) ->
    $scope.job = rsp
    $scope.next_job = rsp.next_job.id if rsp.next_job
    $scope.job.contractor_count = $scope.job.contractors.length
    $scope.job.date_text = moment(rsp.date, 'YYYY-MM-DD').format 'ddd, MMM D'
    $scope.job.date_text_2 = moment(rsp.date, 'YYYY-MM-DD').format 'MMMM Do, YYYY'
    $scope.job.standard_services = _(rsp.booking.services).reject (s) -> s.extra
    $scope.job.extra_services = _(rsp.booking.services).filter (s) -> s.extra
    $scope.staging = _($scope.job.standard_services).find (s) -> s.display == 'Staging'
    $scope.vip = $scope.job.state_cd == 1 unless $scope.staging #always show staging if it is a staging and vip job
    $timeout -> $scope.jobQ.resolve()
    $scope.user_fetched.promise.then -> $scope.job.contractors = _($scope.job.contractors).reject (user) -> user.id == $scope.user.id

    $http.get($window.location.href + '/status').success (rsp) ->
      $scope.job.status = rsp.status
      $scope.job.blocker = rsp.blocker

    $http.get('/man_hrs').success (rsp) ->
      man_hrs = rsp[$scope.job.booking.property.property_type][$scope.job.booking.property.bedrooms][$scope.job.booking.property.bathrooms]
      $scope.man_hrs = "#{man_hrs} hours (est.)" if man_hrs

    load_mapbox = null
    load_mapbox = $interval((->
      if $window.loaded_mapbox
        $interval.cancel(load_mapbox)
        map = L.mapbox.map('map', 'useporter.l02en9o9',
          dragging: false
          touchZoom: false
          scrollWheelZoom: false
          doubleClickZoom: false
          attributionControl: false)
        markers = new L.LayerGroup().addTo(map)
        geocoder = L.mapbox.geocoder 'mapbox.places'
        geocoder.query $scope.job.booking.property.full_address, (err, data) ->
          if data.latlng
            map.setView([data.latlng[0], data.latlng[1]], 14)
            markers.clearLayers() # always clear previous markers
            L.marker([data.latlng[0], data.latlng[1]], {
              icon: L.icon({
                iconUrl: '/images/pin.png',
                iconSize: [28, 49],
              })
            }).addTo markers
    ), 200)

    $scope.user_fetched.promise.then ->
      $http.post('/checklist', { contractor_id: $scope.user.id, job_id: $scope.job.id }).success (rsp) ->
        $scope.checklist = rsp
        _($scope.checklist.checklist_settings).each (v,k) ->
          _(v).each (v2, k2) ->
            $scope.$watch "checklist.checklist_settings.#{k}.#{k2}", (n,o) -> if n != o
              $http.post('/checklist/update', {
                contractor_id: $scope.user.id,
                job_id: $scope.job.id,
                type: 'setting',
                category: k,
                item: k2
                value: n
              })


  $scope.completed_job = ->
    $scope.job and $scope.job.status_cd == 3

  $scope.arrived = ->
    angular.element('.arrived-dropdown').css 'max-height', 80
    null

  $scope.start = ->
    $http.post("/jobs/#{$scope.job.id}/begin").success (rsp) -> $scope.job.status_cd = rsp.status_cd
    angular.element('.actions .phase.active').removeClass('active').addClass('complete').find('.header .text').text 'Job in Progress...'
    angular.element('.actions .phase.arrival').addClass('active')
    null

  $scope.in_progress = ->
    if $scope.job
      $scope.job.status_cd == 2 && 'active' || ''
    else
      ''

  $scope.cancel_modal = ->
    ngDialog.open template: 'cancel-job-modal', className: 'warning full', scope: $scope

  $scope.close_cancellation = ->
    ngDialog.closeAll()

  $scope.confirm_cancellation = ->
    $http.post("/jobs/#{$scope.job.id}/drop").success (rsp) -> $window.location = '/'

  $scope.pricing_class = ->
    if $scope.staging
      'staging'
    else if $scope.vip
      'vip'
    else
      ''

  $scope.in_arrival_tasks = ->
    unless $scope.arrival_tasks() && $scope.damage_inspection() && $scope.inventory_count()
      true
    else
      false

  $scope.check = (task) -> task && 'complete' || ''

  $scope.arrival_tasks = ->
    if $scope.checklist && $scope.checklist.checklist_settings && $scope.checklist.checklist_settings.arrival_tasks
      if _($scope.checklist.checklist_settings.arrival_tasks).filter((v,k) -> v).length < 2 then false else true
    else
      false

  $scope.damage_inspection = ->
    if $scope.checklist && $scope.checklist.checklist_settings && $scope.checklist.checklist_settings.damage_inspection
      if $scope.checklist.checklist_settings.damage_inspection.damage
        if $scope.checklist.contractor_photos[0]
          true
        else
          false
      else
        true
    else
      false

  $scope.inventory_count = ->
    if $scope.checklist && $scope.checklist.checklist_settings && $scope.checklist.checklist_settings.inventory_count
      $scope.checklist.checklist_settings.inventory_count.complete
    else
      false

  $scope.arrival_class = ->
    if $scope.job && $scope.job.status_cd == 3
      'hidden'
    else if $scope.in_progress()
      if $scope.in_arrival_tasks()
        'active'
      else if $scope.inventory_count()
        'complete'
      else
        ''

  $scope.cleaning_class = ->
    if $scope.job && $scope.job.status_cd == 3
      'hidden'
    else if $scope.in_progress() && $scope.inventory_count()
      if $scope.checklist.checklist_settings.cleaning.cleaned
        'complete'
      else
        'active'
    else
      ''

  $scope.qa_class = ->
    if $scope.job && $scope.job.status_cd == 3
      'hidden'
    else if $scope.in_progress() && $scope.checklist && $scope.checklist.checklist_settings
      if $scope.checklist.checklist_settings.cleaning.cleaned then 'active' else ''
    else
      ''

  $scope.damage_class = -> if $scope.in_progress() && $scope.arrival_tasks() then '' else 'disabled'
  $scope.inventory_class = -> if $scope.in_progress() && $scope.damage_inspection() then '' else 'disabled'
  $scope.begin_cleaning_class = ->
    if $scope.checklist && $scope.checklist.checklist_settings && $scope.checklist.checklist_settings.inventory_count
      inventory = $scope.checklist.checklist_settings.inventory_count
      sheets = inventory.king_sheets > 0 || inventory.twin_sheets > 0
      pillows = inventory.pillow_count > 0
      towels = inventory.bath_towels > 0 || inventory.hand_towels > 0 || inventory.face_towels > 0 || inventory.bath_mats > 0
      if towels && sheets && pillows then '' else 'disabled'
    else
      'disabled'

  $scope.complete_cleaning_class = -> ''

  $scope.damage_photos_class = ->
    if $scope.checklist && $scope.checklist.checklist_settings && $scope.checklist.checklist_settings.damage_inspection
      if $scope.checklist.checklist_settings.damage_inspection.damage
        'active'
      else
        ''
    else
      ''

  $scope.photos_class = ->
    if $scope.checklist && $scope.checklist.kitchen_photo.url && $scope.checklist.bedroom_photo.url && $scope.checklist.bathroom_photo.url
      ''
    else
      'disabled'

  $scope.bedroom_class = (num) ->
    if $scope.checklist && $scope.checklist.checklist_settings
      if _($scope.checklist.checklist_settings["bedroom_#{num}"]).filter((v,k) -> v).length == 9
        ''
      else
        'disabled'
    else
      'disabled'

  $scope.bathroom_class = (num) ->
    if $scope.checklist && $scope.checklist.checklist_settings
      if _($scope.checklist.checklist_settings["bathroom_#{num}"]).filter((v,k) -> v).length == 9
        ''
      else
        'disabled'
    else
      'disabled'

  $scope.kitchen_class = ->
    if $scope.checklist && $scope.checklist.checklist_settings
      if _($scope.checklist.checklist_settings.kitchen).filter((v,k) -> v).length == 11
        ''
      else
        'disabled'
    else
      'disabled'

  $scope.living_class = ->
    if $scope.checklist && $scope.checklist.checklist_settings
      if _($scope.checklist.checklist_settings.living_room).filter((v,k) -> v).length == 3
        ''
      else
        'disabled'
    else
      'disabled'

  $scope.complete_class = ->
    if $scope.checklist && $scope.checklist.checklist_settings
      if $scope.living_class() == '' && $scope.kitchen_class() == '' && $scope.photos_class() == '' &&
         $scope.bathroom_class($scope.job.booking.property.bathrooms) == '' &&
         $scope.bedroom_class($scope.job.booking.property.bedrooms) == ''
        ''
      else
        'disabled'
    else
      'disabled'

  $scope.to_tab = (tab, phase) ->
    angular.element(".phase.#{phase} .tab").removeClass 'active'
    angular.element(".phase.#{phase} .tab.#{tab}").addClass 'active'
    null

  $scope.to_damage = ->
    if $scope.damage_class() == ''
      angular.element(".phase.arrival .tab").removeClass 'active'
      angular.element(".phase.arrival .tab.damage").addClass 'active'
      null

  $scope.to_inventory = ->
    if $scope.inventory_class() == ''
      angular.element(".phase.arrival .tab").removeClass 'active'
      angular.element(".phase.arrival .tab.inventory").addClass 'active'
      null

  $scope.to_cleaning = ->
    if $scope.begin_cleaning_class() == ''
      $scope.checklist.checklist_settings.inventory_count.complete = true

  $scope.complete_cleaning = -> $scope.checklist.checklist_settings.cleaning.cleaned = true

  $scope.complete_bedroom = (num) ->
    if num == $scope.job.booking.property.bedrooms
      angular.element('.phase.qa .tab').removeClass 'active'
      angular.element('.phase.qa .tab.bathrooms').addClass 'active'
      null
    else
      $scope.active_bedroom += 1

  $scope.complete_bathroom = (num) ->
    if num == $scope.job.booking.property.bathrooms
      angular.element('.phase.qa .tab').removeClass 'active'
      angular.element('.phase.qa .tab.kitchen').addClass 'active'
      null
    else
      $scope.active_bathroom += 1

  $scope.complete_kitchen = ->
    angular.element('.phase.qa .tab').removeClass 'active'
    angular.element('.phase.qa .tab.living-room').addClass 'active'
    null

  $scope.complete_living = ->
    angular.element('.phase.qa .tab').removeClass 'active'
    angular.element('.phase.qa .tab.photos').addClass 'active'
    null

  $scope.complete_job = ->
    $http.post("/jobs/#{$scope.job.id}/complete").success (_rsp) ->
      $scope.next_job = _rsp.next_job

      $http.get($window.location.href + '/status').success (rsp) ->
        $scope.job.status_cd = _rsp.status_cd
        $scope.job.status = rsp.status
        $scope.job.blocker = rsp.blocker

  $scope.range = (n) -> if n then _.range 0, n else []

  $scope.bedroom_checklist_class = (n) -> if n == $scope.active_bedroom then 'active' else ''
  $scope.bathroom_checklist_class = (n) -> if n == $scope.active_bathroom then 'active' else ''

  $scope.$watch 'damage_photo', ->
    if $scope.damage_photo && $scope.damage_photo[0]
      $upload.upload(
        url: '/checklist/damage_photo'
        data: { contractor_id: $scope.user.id, job_id: $scope.job.id }
        file: $scope.damage_photo[0]
        headers:
          spinner: true
      ).success (rsp) ->
        if rsp.success
          $scope.checklist.contractor_photos = rsp.contractor_photos
        else
          flash 'failure', rsp.message

  $scope.$watch 'kitchen_photo', ->
    if $scope.kitchen_photo && $scope.kitchen_photo[0]
      $upload.upload(
        url: '/checklist/snap_photo'
        data: { contractor_id: $scope.user.id, job_id: $scope.job.id, room: 'kitchen' }
        file: $scope.kitchen_photo[0]
        headers:
          spinner: true
      ).success (rsp) ->
        if rsp.success
          $scope.checklist["kitchen_photo"] = rsp.photo
        else
          flash 'failure', rsp.message

  $scope.$watch 'bedroom_photo', ->
    if $scope.bedroom_photo && $scope.bedroom_photo[0]
      $upload.upload(
        url: '/checklist/snap_photo'
        data: { contractor_id: $scope.user.id, job_id: $scope.job.id, room: 'bedroom' }
        file: $scope.bedroom_photo[0]
        headers:
          spinner: true
      ).success (rsp) ->
        if rsp.success
          $scope.checklist["bedroom_photo"] = rsp.photo
        else
          flash 'failure', rsp.message

  $scope.$watch 'bathroom_photo', ->
    if $scope.bathroom_photo && $scope.bathroom_photo[0]
      $upload.upload(
        url: '/checklist/snap_photo'
        data: { contractor_id: $scope.user.id, job_id: $scope.job.id, room: 'bathroom' }
        file: $scope.bathroom_photo[0]
        headers:
          spinner: true
      ).success (rsp) ->
        if rsp.success
          $scope.checklist["bathroom_photo"] = rsp.photo
        else
          flash 'failure', rsp.message

]

app = angular.module('porter').controller('job', JobCtrl)
