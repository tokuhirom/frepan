var FF_DEBUG = {};

if (!console) { console = { log: function () { } }; }

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
        if (typeof window.__MYLINGUAL != 'object') {
            window.__MYLINGUAL = {};
        }
        window.__MYLINGUAL.updateStatus = function () {}; // display completed message
        window.__MYLINGUAL.debugAlert = function (msg) { /* display debug message */ };
        var lang;
        var m;
        if( typeof localStorage == "object" ){
            lang = localStorage[ "lang" ];
        }
        if( ( m = location.hash.match( /[#&]lang=(\w+)/ ) ) && m[ 1 ] ){
            lang = m[ 1 ];
        }
        if( !lang ){
            lang = navigator.language;
        }
        var scr = document.createElement('script');
        scr.setAttribute("id", "mylingual-core");
        scr.setAttribute("src", "http://mylingual.net/userjs/mylingual-core.js?lang=" + lang);
        document.body.appendChild(scr);
        if( typeof localStorage == "object" ){
            localStorage[ "lang" ] = lang;
        }
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
    // top page
    dispatcher('^/$', function () {
        var page = 1;
        var didScroll = false;
        var in_request = false;
        var finished = false;

        $(window).scroll(function () {
            didScroll = true;
        });
        setInterval(function () {
            if (didScroll) {
                var remain = $(document).height() - $(document).scrollTop() - $(window).height()
                if (remain < 500 && in_request==false && !finished) {
                    in_request = true;
                    $.ajax({
                        type: 'get',
                        cache: false,
                        data: { page: ++page },
                        url: location.href,
                        success: function (html) {
                            in_request = false;
                            var elements = $('.modules li', html);
                            if (elements.length == 0) {
                                finished = true;
                            }
                            $('.modules').append( elements );
                            $('html,body').animate({scrollTop: $(window).scrollTop() + 10 + 'px'}, 800, function () { in_request=false; });
                        },
                        error: function () { /* nop */ }
                    });
                    console.log("remains");
                }
                didScroll = false;
            }
        }, 250);
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
