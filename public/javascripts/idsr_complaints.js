/*$(function(){
  var $cur = $('#pages .q');
  var $w = $('#pages .w');

  function hideButtons() {
    $cur = $('#pages .q');
    var index = $cur.index();
    if(index > 0) {
      $('#backButton').show();
    } else {
      $('#backButton').hide();
    }

    if(index < $w.length - 1) {
      $('#finishButton').show();
    } else {
      $('#finishButton').hide();
    }
  }

  hideButtons();

  $('#finishButton').click(function(){
    $cur.next().addClass('q');
    $cur.removeClass('q');
    hideButtons();
  });

  $('#backButton').click(function(){
    $cur.prev().addClass('q');
    $cur.removeClass('q');
    hideButtons();
  });
});*/

$( "#next" ).click(function() {
    if($(".q").length!=1){
        $( "#group:first-child" ).addClass("q");
    }

    $(".q").removeClass("q").hide().next().addClass("q").show();

    if($(".q").next().length!=1){
        $( "#next" ).hide();
    }

    $( "#prev" ).show();
});


$( "#prev" ).click(function() {
    if($(".q").length!=1){
        $( "#group:last-child" ).addClass("q");
    }

    $(".q").removeClass("q").hide().prev().addClass("q").show();

    if($(".q").prev().length!=1){
        $( "#prev" ).hide();
    }

    $( "#next" ).show();
});
