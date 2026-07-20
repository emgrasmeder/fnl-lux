(var beep-source nil)

(fn play-beep []
  (when (not beep-source)
    (let [sample-rate 44100
          duration 0.15
          frequency 440
          sample-count (math.floor (* sample-rate duration))
          sound-data (love.sound.newSoundData sample-count sample-rate 16 1)]
      (for [i 0 (- sample-count 1)]
        (let [t (/ i sample-rate)
              sample (* 0.3 (math.sin (* 2 math.pi frequency t)))]
          (sound-data:setSample i sample)))
      (set beep-source (love.audio.newSource sound-data "static"))))
  (: beep-source :stop)
  (: beep-source :play))

{:play-beep play-beep}
