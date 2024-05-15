$(function () {

  //////////////////////////
  // Handles all doc drawers
  //////////////////////////

  $('.more').hide();

  $('.open').show();

  $('.showmore').click(function () {
    var divmore = $(this).parent().children('.more');
    var arrow   = $(this).parent().children('.arrow');
    arrow.toggleClass('rotate');
    if(divmore.is(':hidden')) {
      divmore.slideDown("fast");
    }
    else {
      divmore.slideUp("fast");
    }
  });

  ///////////////////////
  // Collapsable nav tree
  ///////////////////////

  $('aside ul').hide();
  $('#main-nav').show();

  // Handling nav-open
  $('.nav-open').show();
  $('.nav-open').parent().children('.arrow').toggleClass('rotate');

  // We remove the arrow when the li has no ul inside
  $('aside li:not(:has(ul ul))').children('.arrow').hide();

  $('.shownav').click(function () {
    var ul    = $(this).parent().children('ul');
    var arrow = $(this);
    arrow.toggleClass('rotate');
    if(ul.is(':hidden')) {
      ul.slideDown("fast");
    }
    else {
      ul.slideUp("fast");
    }
  });

  // Show and hide all buttons

  function showall() {
    var el = $('.showall');
    $('.shownav:not(.rotate)').trigger('click');
    el.text('Hide all');
    el.off('click').on('click',showall);
    el.click(hideall);
  }

  function hideall() {
    var el = $('.showall');
    $('.shownav.rotate').trigger('click');
    el.text('Show all');
    el.off('click').on('click',hideall);
    el.click(showall);
  }

  $('.showall').click(showall);

  /////////////////////////////////
  // Handles menu for small screens
  /////////////////////////////////

  $('#nav-trigger').click(function () {
    $('aside').toggleClass('nav-visible');
    $(this).toggleClass('nav-visible');
  });

});
