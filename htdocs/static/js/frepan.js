var FF_DEBUG = {};
$(function () {
    // run on every page
    (function () {
        var ajaxManager = $.manageAjax.create('search', {
            queue: 'clear', 
            cacheResponse: false,
            abortOld: true
        });
        
        $('#search_query').focus().keyup(function () {
            var query = $(this).val();
            if (query && query.length > 2) {
                ajaxManager.add({
                    success: function(html) {
                        require(["/static/js/jquery.highlight-3.js"], function () {
                            var elem = $("#Content").html(html);
                            var ary = query.split(/\s+/);
                            for (var i=0; i<ary.length; i++) {
                                var term = ary[i];
                                if (term.match(/\S/)) { // work around for fucking highlight library issue
                                    $('#Content').highlight(term);
                                }
                            }
                        });
                    },
                    url: '/search',
                    data: {ajax: 1, q: query},
                    error: function () {
                        $("#Content").text("sorry. error occurred at searching...");
                    }
                });
            }
        });

        if (window.history.pushState) {
            var ajax_part_load = function (url, pushit) {
                $.ajax({
                    url: url,
                    data: {slide: 1},
                    type: 'GET',
                    cache: false,
                    dataType: 'html',
                    success: function (src) {
                        var title = $('title', src).text();
                        if (pushit) {
                            history.pushState({path:url}, title, url);
                        } else {
                            history.replaceState({path:url}, title, url);
                        }

                        // document.title=title;
                        $('#Content').replaceWith($('#Content', src)).scrollTop();
                        dispatcher(url);
                    }
                });
            };
            $('#Content a').live('click', function (event) {
                if (event.altKey || event.shiftKey || event.metaKey || event.ctrlKey) {
                    return true; // open in other tabs
                }
                var e = $(this);
                var href = e.attr('href');
                if (
                    href.match(/^https?:\/\//) // absolute uri
                    || href.match(/^\/src\//)  // source page
                ) {
                    return true;
                }
                ajax_part_load(href, true);
                return false;
            });
            window.addEventListener('popstate', function(event) {
                if (event && event.state) {
                    ajax_part_load(event.state.path, false);
                    return false;
                } else {
                    return true;
                }
            }, false);
        }

        // mylingual
        var lang = navigator.language;
        var m = location.hash.match(/[#&]lang=(\w+)/);
        if (m) lang = m[1];
        $(document.body).add($(document.createElement('script')).attr('src', "http://mylingual.net/userjs/mylingual-core.js?lang=" + lang));
    })();

    // dist page
    dispatcher('^/~.+/.+/', function () {
        prettyPrint();
        $('#i_use_this_form').ajaxForm(function (html) {
            $('.IUseThisContainer').html(html).effect("highlight", {}, 1000);
            return false;
        });
    });
    dispatcher('^/src/', function () {
        prettyPrint();
    });

    // http://tech.kayac.com/archive/javascript-url-dispatcher.html
    function dispatcher (path, func) {
        dispatcher.path_func = dispatcher.path_func || []
        if (func) return dispatcher.path_func.push([path, func]);
        for(var i = 0, l = dispatcher.path_func.length; i < l; ++i) {
            var func = dispatcher.path_func[i];
            var match = path.match(func[0]);
            match && func[1](match);
        };
    };
    dispatcher(location.pathname);
});
