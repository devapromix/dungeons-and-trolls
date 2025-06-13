local volume = {}

function volume.exec(command_parts)
	if #command_parts < 2 then
		output.add("Please specify a volume level from 0 to 10 (e.g., 'volume 5').\n")
	else
		local vol = tonumber(command_parts[2])
		local v = config.audio.volume
		if vol and vol >= 0 and vol <= 10 then
			if vol > 0 and config.audio.volume == 0 then
				output.add("Music: on.\n")
			end
			music.setVolume(vol / 10)
			if vol == 0 then
				music.stop()
			elseif vol >= 1 then
				music.play_random()
			end
			if config.audio.volume > 0 and vol > 0 then
				output.add("Volume set to " .. vol .. ".\n")
			else
				output.add("Music: off.\n")
			end
		else
			output.add("Invalid volume level. Please use a number from 0 to 10.\n")
		end
	end
end

return volume