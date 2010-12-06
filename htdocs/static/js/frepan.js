$(function () {
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
});
