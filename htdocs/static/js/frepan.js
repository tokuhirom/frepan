$(function () {
    // run on every page
    (function () {
        $('.gravatar_container').each(function (i, elem) {
            elem = $(elem);
            elem.html(
                $(document.createElement('img'))
                    .attr('src' , "http://www.gravatar.com/avatar/" + CybozuLabs.MD5.calc(elem.attr('email')) + "?d=http://st.pimg.net/tucs/img/who.png")
                    .attr('width', 80)
                    .attr('height', 80)
                    .attr('alt', $(elem).attr('email'))
            );
        });

        $('#search_query').focus().keyup(function () {
            var query = $(this).val();
            if (query && query.length > 2) {
                $.ajax({
                    url: "/search",
                    data: {ajax: 1, q: query},
                    cache: false,
                    success: function (html) {
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
                    error: function () {
                        alert("error occurred");
                    }
                });
            }
        });
    })();

    // dist page
    dispatcher('^/~.+/.+/', function () {
        require(['/static/prettify/prettify.js'], function () {
            $('pre').addClass('prettyprint').addClass('lang-perl');
            prettyPrint();
        });
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
