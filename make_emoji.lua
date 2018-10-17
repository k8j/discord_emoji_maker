#!/usr/bin/env lua
local argparse = require "argparse"

local function round(x)
   return math.floor(x + 0.5)
end

local function exec(cmd, ...)
   assert(os.execute(cmd:format(...)))
end

local parser = argparse("rotgif", "What am I doing with my life...")
parser:option("-i --input"):count("1")
parser:option("-o --output"):count("1")
parser:option("-r --resize"):default("32"):convert(tonumber)
parser:option("-d --delay"):default("3x100")
parser:option("-s --step"):default("15"):convert(tonumber)
parser:option("-a --angle"):default("a")
parser:option("-m --move")

local args = parser:parse()

local wd = args.input .. "-rotgif-wd"

exec("rm -rf '%s'", wd)
exec("mkdir -p '%s'", wd)

local get_angle = assert(load(("local a = ...; return %s;"):format(args.angle)))

local get_shift

if args.move then
   get_shift = assert(load(("local a = ...; return %s;"):format(args.move)))
end

local frames_arg_parts = {}

for a = 0, 359, args.step do
   io.stdout:write(("\rRotation %d/360..."):format(a + 1))
   io.stdout:flush()
   local frame = ("%s/rot%d.png"):format(wd, a)
   table.insert(frames_arg_parts, "'" .. frame .. "'")
   exec("convert -resize %dx%d -rotate %d -background 'rgba(0,0,0,0)' +repage -gravity center -crop '%dx%d+0+0' +repage '%s' '%s'",
      args.resize, args.resize, round(get_angle(a)), args.resize, args.resize, args.input, frame)

   if args.move then
      local shift = round(get_shift(a))
      local left_crop
      local right_crop

      if shift >= 0 then
         left_crop = ("%dx%d+%d+0"):format(shift, args.resize, args.resize - shift)
         right_crop = ("%dx%d+0+0"):format(args.resize - shift, args.resize)
      else
         left_crop = ("%dx%d+%d+0"):format(args.resize + shift, args.resize, -shift)
         right_crop = ("%dx%d+0+0"):format(-shift, args.resize)
      end

      local left = ("%s/left%d.png"):format(wd, a)
      local right = ("%s/right%d.png"):format(wd, a)

      exec("convert -crop '%s' +repage '%s' '%s'", left_crop, frame, left)
      exec("convert -crop '%s' +repage '%s' '%s'", right_crop, frame, right)
      exec("convert +append '%s' '%s' '%s'", left, right, frame)
   end
end

io.stdout:write("\nCombine...\n")

local frames_arg = table.concat(frames_arg_parts, " ")

exec("convert -set dispose background -layers optimize -delay '%s' %s '%s'", args.delay, frames_arg, args.output)
exec("wc -c '%s'", args.output)
exec("rm -rf '%s'", wd)
