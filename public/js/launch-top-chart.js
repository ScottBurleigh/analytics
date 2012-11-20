function launch_top_chart() {
  "use strict";

  var path;
  var data;
  var container = {width: 700, height: 300};
  var margins = {top: 10, right: 20, bottom: 60, left: 50}
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
    var selection = chart.selectAll("circle.view").data(series());

    selection.enter()
      .append("circle")
      .attr("class", "view")
    ;

    selection.exit().remove();
      
   selection
      .attr("cy", function(d){ return view_scale()(d.views);})
      .attr("cx", function(d){ return count_scale()(d.count);})
      .attr("r", 4);
  }
  
  function draw_line() {
    var selection = chart.selectAll("path.view").data(series());

    var line = d3.svg.line()
      .x(function(d){return count_scale()(d.count)})
      .y(function(d){return view_scale()(d.views)})
    ;

    selection.enter()
      .append("svg:path")      
      .attr("class", "view")
    ;

    selection.exit().remove();

    selection
      .attr("d", line(series()))
      
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


  function add_x_axis() {
    function add_label() {
      chart.select(".x.axis")
        .append("text")
        .text("weekdays since launch")
        .attr("y", 40)
        .attr("x", 150)
    }
    chart.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + chart_dim().height + ")")
      .call(count_axis())
    ;
    add_label();
  }
  function add_y_axis() {
    function view_axis() {
      return d3.svg.axis()
        .scale(view_scale())
        .tickValues([100,500,2000, 5000, 10000])
        .orient("left")
      ;
    }
    function add_label() {
      chart.select(".y.axis")
        .append("text")
        .attr("text-anchor", "middle")
        .text("unique page views (sqrt scale)")
        .attr("transform", "rotate(-90, 0, 0)")
        .attr("x", -container.height/2)
        .attr("y", -70)
      ;
    }
    
    chart.append("g")
      .attr("class", "y axis")
      .attr("transform", "translate(" + margins.left + ",0)")
      .call(view_axis())
    ;
    add_label();
  }

  function layout_chart_container() {
    chart = d3.select(".top-chart")
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
  
  function add_title() {
    chart.append("text")
      .attr("text-anchor", "end")
      .attr('class', 'title')
      .attr('x', container.width/2)
      .attr('y', 40)
  }
  function update_title() {
    chart.select('text.title')
      .text(path)
  }

  function view_extent() {
    return fixed_view_extent();
  }

  function fixed_view_extent() {
    return d3.extent([0,10000]);
  }

  // y-axis based on number of page views
  // not used at moment, but maybe later
  function variable_view_extent() {
    return d3.extent([0, d3.max(series(), function(d){return d.views})]);
  }

  function view_scale() {
    return d3.scale.sqrt()
      .domain(view_extent())
      .range([chart_dim().height, margins.top])
      .nice()
    ;
  }
  
  self.render_container = function() {
    layout_chart_container();
    add_x_axis();
    add_y_axis();
    add_title();
    return self;
  }



  self.draw = function() {
    draw_line();
    draw_points();
    update_title();
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

  self.show = function(arg) {
    self.path(arg).draw();
  }

  function self() {
    return self;
  }

  return self;
};
