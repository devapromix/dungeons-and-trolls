local volume = {}

function volume.exec(vol)
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

return volume