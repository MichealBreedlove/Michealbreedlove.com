// Copy canonical URL to clipboard (with fallback)
function copyPageLink(btn) {
    var canonical = document.querySelector('link[rel="canonical"]');
    var url = canonical ? canonical.href : window.location.href;

    function showCopied() {
        var orig = btn.innerHTML;
        btn.innerHTML = '<i class="bi bi-check2 me-1"></i>Copied';
        btn.classList.add('copied');
        setTimeout(function () {
            btn.innerHTML = orig;
            btn.classList.remove('copied');
        }, 2000);
    }

    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(url).then(showCopied).catch(function () {
            window.prompt('Copy this link:', url);
        });
    } else {
        window.prompt('Copy this link:', url);
    }
}
