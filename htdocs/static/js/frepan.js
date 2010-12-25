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
