FROM docker.io/finanalyst/raku-cro-rrr-base AS base

# install deps in stage that does not depend on copy
RUN zef install -/test "Git::Log"
RUN zef install -/test "JSON::Fast::Hyper"
#RUN zef install -/test "Elucid8::Build"
RUN mkdir e-build
WORKDIR e-build
COPY lib/ ./lib
COPY bin/ ./bin
COPY resources/ ./resources
ADD META6.json .
RUN zef -/test install .
RUN mkdir /elucid8
WORKDIR /elucid8
COPY  New_Website/ .
RUN zef install . -/test
RUN gather-sources -v
RUN gather-sources
# RUN elucid8-build

#FROM docker.io/caddy AS server

#COPY --from=base /elucid8/publication /website

#COPY ./Caddyfile /etc/Caddyfile

#CMD caddy run --config /etc/Caddyfile --adapter caddyfile