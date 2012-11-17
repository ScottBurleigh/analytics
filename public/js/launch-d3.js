top_chart = function() {
  "use strict";

  var path;
  var data;
  var container = {width: 700, height: 300};
  var margins = {top: 10, right: 20, bottom: 30, left: 50}
  var chart;

  // x-axis count from launch date
  var count_extent = d3.extent([0,40]);
  
  function count_axis() {
    return d3.svg.axis()
      .scale(count_scale())
      .ticks(6)
    ;
  }

  function count_scale() {
    return d3.scale.linear()
      .domain(count_extent)
      .range([margins.left, chart_dim().width]);
  }

  function chart_dim() {
    return {
      width: container.width - margins.left - margins.right,
      height: container.height - margins.top - margins.bottom
    };    
  }
  function draw_points() {
    chart.append("g")
      .selectAll("circle.view")
      .data(series())
      .enter()
      .append("circle")
      .attr("class", "view")
    ;
    d3.selectAll("circle.view")
      .attr("cy", function(d){ return view_scale()(d.views);})
      .attr("cx", function(d){ return count_scale()(d.count);})
      .attr("r", 2);
  }
  
  function draw_line() {
    var line = d3.svg.line()
      .x(function(d){return count_scale()(d.count)})
      .y(function(d){return view_scale()(d.views)})
    ;
    chart.append("path")
      .attr("d", line(series()))
      .attr("class", "views")
    ;
  }

  function apply_mouseover_behavior() {
    d3.selectAll("circle.view")
      .on("mouseover.tooltip", function(d) {
        d3.select("#tooltip").remove();
        d3.select("g.chart")
          .append("text")
          .text(d.views)
          .attr("x", count_scale()(d.count) + 10)
          .attr("y", view_scale()(d.views) - 20)
          .attr("id", "tooltip")
      });

    d3.selectAll("circle.view")
      .on("mouseout.tooltip", function(d) {
        d3.select('#tooltip')
          .transition()
          .duration(200)
          .style("opacity", 0)
          .remove();
      });
  }

  function add_label_to_view_axis() {
    chart.select(".y.axis")
      .append("text")
      .attr("text_anchor", "middle")
      .text("uniques")
      .attr("transform", "rotate(-270, 0, 0)")
      .attr("x", container.height/2)
      .attr("y", 50)
    ;
  }

  function add_x_axis() {
    chart.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + chart_dim().height + ")")
      .call(count_axis())
    ;
  }
  function add_y_axis() {
    function view_axis() {
      return d3.svg.axis()
        .scale(view_scale())
        .ticks(5)
        .orient("left")
      ;
    }
    
    chart.append("g")
      .attr("class", "y axis")
      .attr("transform", "translate(" + margins.left + ",0)")
      .call(view_axis())
    ;
    add_label_to_view_axis();
  }

  function layout_chart_container() {
    chart = d3.select(".graph")
      .append("svg")
      .attr("width", container.width)
      .attr("height", container.height)
      .append("g")
      .attr("class", "chart")
      .attr("transform", "translate(" + margins.left + "," 
            + margins.top + ")"
           )
    ;
  }
  function series() {
    return data[path].data;
  }


  // y-axis number of page views
  function view_extent() {
    return d3.extent([0, d3.max(series(), function(d){return d.views})]);
  }

  function view_scale() {
    return d3.scale.linear()
      .domain(view_extent())
      .range([chart_dim().height, margins.top])
      .nice()
    ;
  }
  
  self.render_container = function() {
    layout_chart_container();
    return self;
  }

  self.draw = function() {
    draw_line();
    draw_points();
    add_x_axis();
    add_y_axis();
    apply_mouseover_behavior();
    return self;
  }

  self.path = function(arg) {
    if (!arguments.length) return path;
    path = arg;
    return self;
  }

  self.data = function(arg) {
    if (!arguments.length) return data;
    data = arg;
    return self;
  }

  function self() {
    return self;
  }

  return self;
}();

$(function() {
  d3.json("/analytics/launch.json", function(d) {
    top_chart.data(d);
    top_chart.path("/articles/nosqlKeyPoints.html");
    //top_chart.path("/articles/agileFluency.html");
    top_chart.render_container();
    top_chart.draw();
   })
});