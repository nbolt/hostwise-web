// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require angular
//= require angular-cookies.min
//= require angular-file-upload
//= require angular-carousel.min
//= require angular-touch
//= require angular-timer
//= require angular-sanitize.min
//= require dirPagination
//= require mask
//= require select2.min
//= require select2
//= require underscore-min
//= require ngDialog.min
//= require slider
//= require jquery.scrollTo
//= require jquery.cookie
//= require unslider.min
//= require typed
//= require hw
//= require app
//= require_tree ./controllers
//= require_tree .


String.prototype.capitalize = function(){return this.charAt(0).toUpperCase() + this.slice(1)}

$.cookie.json = true

_.mixin({
  rotate: function(array, n, guard) {
    var head, tail
    n = (n == null) || guard ? 1 : n
    n = n % array.length
    tail = array.slice(n)
    head = array.slice(0, n)
    return tail.concat(head)
  }
})
