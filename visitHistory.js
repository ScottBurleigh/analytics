function plot_visit_history() {
    $.jqplot('visit-history',  <%= data %>, {
        seriesDefaults: {
            markerOptions: {
                size: 5
            }
        },
        axes: {
            xaxis: {
                renderer:$.jqplot.DateAxisRenderer,
                pad: 0,
                //tickInterval: 4, //this seemed to fry the browser
                tickOptions: {
                    formatString: "%b %Y"
                }
            },
            yaxis: {
                min: 0
            }
        },
        legend: {
            show: true, location: 'nw'
        },
        series: [
            {label: 'median weekday visitors'}
        ],
        highlighter: {
            show: true,
            sizeAdjust: 7.5
        }
    });
}
