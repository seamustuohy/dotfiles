javascript: void (d = document);
void (el = d.getElementsByTagName('link'));
void (g = false);
void (feeds = "");
void (clipboard = "");
for (i = 0; i < el.length; i++) {
    if (el[i].getAttribute('rel').indexOf('alternate') != -1) {
        ty = el[i].getAttribute('type');
        if (ty.indexOf('application/rss+xml') != -1 || ty.indexOf('text/xml') != -1 || ty.indexOf('application/atom+xml') != -1) {
            g = true;
            h = el[i].getAttribute('href');
            cur = window.location.origin;
            if (h.startsWith('/')) {
                h = cur + h;
            };
            feeds = feeds + h + '\n';
            clipboard = clipboard + h + " | ";
        }
    }
}
navigator.clipboard.writeText(clipboard).then(
    function (result) {
        void(feeds = "RSS Feeds: (All saved to clipboard)\n" + feeds);
        void (window.alert(feeds));
        return feeds;
    });
if (!g) {
    window.alert('Could%20not%20find%20the%20RSS%20Feed');
}
