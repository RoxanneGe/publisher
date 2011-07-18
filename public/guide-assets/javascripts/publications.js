$(function () {
  $('.publication-nav').tabs();
  $('#save-edition').submit(function () {
    $('form.edition').trigger('submit');
    return false;
  });
  
  $('#edition_title')[0].focus();
  
  var submitted_main_form = false;
  
  $('.also_save_edition').submit(function () {
    var main_form = $('#edition_edit');
    var this_form = $(this);

    if (! submitted_main_form) {
      $.post(
        main_form.attr('action'), 
        main_form.serialize(), 
        function (data, textStatus, jqXHR) {
          submitted_main_form = true;
          this_form.trigger('submit');
        }
      );
    }
  });
});