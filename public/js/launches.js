$(function() {
    $('.sparkline-20d').sparkline('html', {
        chartRangeMin: '0',
        chartRangeMax: '10',
        disableInteraction: true
    });
    plot_visit_history();
});
