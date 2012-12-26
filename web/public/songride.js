$(document).ready(function() {
    $('#lastfmusername-form').submit(function(event) {
        event.preventDefault();
        document.location.href = '/lastfm/' + $('#lastfmusername').val();
    });
});

function drawLastFMPie(obj) {
    var xs = _.map(obj, function(value, key, list) { return value; });
    var legend_ys = _.map(obj, function(value, key, list) { return "%%.%% " + key; });
    var r = Raphael("raphael", 400, 350);
    var pie = r.piechart(175, 175, 100, xs, {
        legend: legend_ys
    });
    pie.hover(function() {
        this.sector.stop();
        this.sector.scale(1.1, 1.1, this.cx, this.cy);
        if (this.label) {
            this.label[0].stop();
            this.label[0].attr({ r: 7.5 });
            this.label[1].attr({ "font-weight": 800 });
        }
    }, function() {
        this.sector.animate({ transform: 's1 1 ' + this.cx + ' ' + this.cy }, 500, "bounce");
        if (this.label) {
            this.label[0].animate({ r: 5 }, 500, "bounce");
            this.label[1].attr({ "font-weight": 400 });
        }
    });
}
