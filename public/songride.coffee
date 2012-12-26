$ ->
    $('#lastfmusername-form').submit (event) ->
        event.preventDefault()
        document.location.href = '/lastfm/' + $('#lastfmusername').val()

window.drawLastFMPie = (obj) ->
    xs = _.map obj, (value, key, list) -> value
    legend_ys = _.map obj, (value, key, list) ->
        code = key
        if worldmap.names[key]?
            code = worldmap.names[key]
        "%%.%% " + code
    r = Raphael("raphael-pie", 500, 350)
    pie = r.piechart 175, 175, 100, xs,
        legend: legend_ys
    mouseover = () ->
        this.sector.stop()
        this.sector.scale(1.1, 1.1, this.cx, this.cy)
        if this.label
            this.label[0].stop()
            this.label[0].attr r: 7.5
            this.label[1].attr "font-weight": 800
    mouseout = () ->
        this.sector.animate({ transform: 's1 1 ' + this.cx + ' ' + this.cy }, 500, "bounce")
        if this.label
            this.label[0].animate r: 5 , 500, "bounce"
            this.label[1].attr "font-weight": 400
    pie.hover mouseover, mouseout

window.drawLastFMMap = (obj) ->
    sum = _.reduce obj, ((memo, value) -> memo + value), 0
    max = _.reduce obj, ((memo, value) -> Math.max(memo, value)), 0
    r = Raphael("raphael-world", 1000, 400)
    r.rect(0, 0, 1000, 400, 10).attr stroke: "none", fill: "0-#9bb7cb-#adc8da"
    r.setStart()
    _.each worldmap.shapes, (value, key, list) ->
        fill = "#f0efeb"
        if obj[key]?
            fill = Raphael.hsb((1 - (obj[key] / sum) / (max / sum)) / 4, .75, 1)
            console.log(fill)
        r.path(value).attr({stroke: "#ccc6ae", fill: fill, "stroke-opacity": 0.25})
    world = r.setFinish()

 $ ->
     if window.statsdata?
         window.drawLastFMPie(window.statsdata)
         window.drawLastFMMap(window.statsdata)
