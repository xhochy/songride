$(document).ready(function() {
    $('#lastfmusername-form').submit(function(event) {
        event.preventDefault();
        document.location.href = '/lastfm/' + $('#lastfmusername').val();
    });
});

function drawLastFMPie(obj) {
    var width = 350;
    var height = 350;
    var radius = Math.min(width, height) / 2;
    var arc = d3.svg.arc().outerRadius(radius - 10).innerRadius(0);
    var pie = d3.layout.pie().sort(null).value(function(d) { return d.count });
    var data = $.map(obj, function (value, key) { return {"country": key, "count": value}; });
    var sum = _.reduce(data, function(memo, x) { return memo+x.count; }, 0);
    console.log(sum);
    var max = _.reduce(data, function(memo, x) { return Math.max(memo, x.count); }, 0);
    var svg = d3.select("#graphs").append("svg").attr("width", width).attr("height", height).append("g")
        .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");
    var g = svg.selectAll(".arc").data(pie(data)).enter().append("g").attr("class", "arc");
    g.append("path").attr("d", arc).style("fill", function(d) { return d3.rgb(128 + 127*d.data.count/sum*(sum/max), 215, 50) });
    g.append("text").attr("transform", function(d) { return "translate(" + arc.centroid(d) + ")"; })
      .attr("dy", ".35em").style("text-anchor", "middle").text(function(d) { return d.data.country; });
}
