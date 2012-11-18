
top_chart = launch_top_chart();

$(function() {
    $('.sparkline-20d').sparkline('html', {
        chartRangeMin: '0',
        chartRangeMax: '10',
        disableInteraction: true
    });

  d3.json("/analytics/launch.json", function(d) {
    top_chart.data(d);
    top_chart.render_container();
  });
  $("span.plot").click(function( e ) {
    top_chart.show($(this).attr('data-path'));
    //alert("hello: " + $(this).attr('data-path'));
  });


});
