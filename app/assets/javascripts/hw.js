// //Equal Height Column Containers (only runs if browser width is >= 768px)
// $(window).load(function(){
//   var pageWidth = $(window).width();
//   if (pageWidth >= 768) {
//     (function($) {
//       $.fn.eqHeights = function() {
//         var el = $(this);
//         if (el.length > 0 && !el.data('eqHeights')) {
//           $(window).bind('resize.eqHeights', function() {
//             el.eqHeights();
//           });
//           el.data('eqHeights', true);
//         }
//         return el.each(function() {
//           var curHighest = 0;
//           $(this).children().each(function() {
//             var el = $(this),
//               elHeight = el.height('auto').height();
//             if (elHeight > curHighest) {
//               curHighest = elHeight;
//             }
//           }).height(curHighest);
//         });
//       };
//       $('.pl .section').eqHeights();
//     }(jQuery));
//   };
// });


$(document).ready(function(){
  $('.t-slider').unslider({
    speed: 500,               //  The speed to animate each slide (in milliseconds)
    delay: 3000,              //  The delay between slide animations (in milliseconds)
    complete: function() {},  //  A function that gets called after every slide animation
    keys: true,               //  Enable keyboard (left, right) arrow shortcuts
    dots: false,               //  Display dot navigation
    fluid: true              //  Support responsive design. May break non-responsive designs
  });

  $(".x").typed({
    strings: ["Sleep", "Netflix", "Awesomeness", "Growth", "Family", "Friends", "Travel", "Exercise", "Eating", "Lounging", "Surfing", "Coffee", "Jogging", "Dancing", "Learning", "Acting", "Globetrotting", "Painting", "Tanning"],
    typeSpeed: 100,
    backSpeed: 30,
    startDelay: 0,
    backDelay: 1750,
    loop: true,
    loopCount: false
  });
});
