/*
next step is to figure out what it means to draw the y axis based on
adding a path
*/

top_chart = function() {
  var path;
  var data;
  var container = {width: 700, height: 300};
  var margins = {top: 10, right: 20, bottom: 30, left: 50}
  var chart_dim = {
    width: container.width - margins.left - margins.right,
    height: container.height - margins.top - margins.bottom
  };
  // x-axis count from launch date
  var count_extent = d3.extent([0,40]);

  var count_scale = d3.scale.linear()
    .domain(count_extent)
    .range([margins.left, chart_dim.width]);

  var count_axis = d3.svg.axis()
    .scale(count_scale)
    .ticks(6)
  ;


  
  
  function draw() {
    "use strict";

    var series = data[path].data;



    // y-axis number of page views
    var view_extent = d3.extent([0, d3.max(series, function(d){return d.views})]);
    var view_scale = d3.scale.linear()
        .domain(view_extent)
        .range([chart_dim.height, margins.top])
        .nice()
    ;
    var view_axis = d3.svg.axis()
        .scale(view_scale)
        .ticks(5)
        .orient("left")
    ;

    var line = d3.svg.line()
        .x(function(d){return count_scale(d.count)})
        .y(function(d){return view_scale(d.views)})
    ;


    // layout the chart area
    var chart = d3.select(".graph")
        .append("svg")
        .attr("width", container.width)
        .attr("height", container.height)
        .append("g")
        .attr("class", "chart")
        .attr("transform", "translate(" + margins.left + "," 
                                        + margins.top + ")"
             )
    ;


    chart.append("g")
        .selectAll("circle.view")
        .data(series)
        .enter()
        .append("circle")
        .attr("class", "view")
    ;

    chart.append("path")
        .attr("d", line(series))
        .attr("class", "views")
    ;

    chart.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + chart_dim.height + ")")
        .call(count_axis)
    ;

    chart.append("g")
        .attr("class", "y axis")
        .attr("transform", "translate(" + margins.left + ",0)")
        .call(view_axis)
    ;

    chart.select(".y.axis")
        .append("text")
        .attr("text_anchor", "middle")
        .text("uniques")
        .attr("transform", "rotate(-270, 0, 0)")
        .attr("x", container.height/2)
        .attr("y", 50)
    ;


    d3.selectAll("circle")
        .attr("cy", function(d){ return view_scale(d.views);})
        .attr("cx", function(d){ return count_scale((d.count));})
        .attr("r", 2);

    d3.selectAll("circle")
        .on("mouseover.tooltip", function(d) {
            d3.select("#tooltip").remove();
            d3.select("g.chart")
                .append("text")
                .text(d.views)
                .attr("x", count_scale(d.count) + 10)
                .attr("y", view_scale(d.views) - 20)
                .attr("id", "tooltip")
        });

    d3.selectAll("circle")
        .on("mouseout.tooltip", function(d) {
            d3.select('#tooltip')
                .transition()
                .duration(200)
                .style("opacity", 0)
                .remove();
        });
  }

  draw.path = function(arg) {
    if (!arguments.length) return path;
    path = arg;
    return draw;
  }

  draw.data = function(arg) {
    if (!arguments.length) return data;
    data = arg;
    return draw;
  }




  return draw;
}();

$(function() {
  d3.json("/analytics/launch.json", function(d) {
    top_chart.data(d);
    //top_chart.path("/articles/nosqlKeyPoints.html")();
    top_chart.path("/articles/agileFluency.html")();
  })
});