FROM imolein/luarocks:5.4
RUN luarocks install luatbot
RUN luarocks install luasocket
RUN luarocks install penlight
RUN luarocks install luaposix
RUN luarocks install dkjson
ARG BOTDIR=/root/bot
WORKDIR $BOTDIR
ARG BOT=bot.lua
CMD [ "lua",  "$BOTDIR/$BOT" ]
