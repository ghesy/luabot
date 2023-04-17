FROM imolein/luarocks:5.4
RUN luarocks install luatbot
RUN luarocks install luasocket
RUN luarocks install penlight
RUN luarocks install luaposix
RUN luarocks install dkjson
RUN mkdir /etc/bot
CMD lua /etc/bot/bot.lua
