
set -x
for font in $(find "${HOME}/dotfiles/config/fonts/" -maxdepth 1 ! -path "${HOME}/dotfiles/config/fonts/" -type d ); do \
    cd $font ;\
    mkfontscale ;\
    # ls -lah
    # xset +fp $font ;\
    done;
# xset fp rehash
# for dir in /font/dir1/ /font/dir2/; do xset +fp $dir; done && xset fp rehash
set +x
