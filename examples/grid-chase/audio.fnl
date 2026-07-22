(var catch-source nil)

(fn play-catch []
  (when (not catch-source)
    (let [sample-rate 44100
          duration 0.2
          frequency 523
          sample-count (math.floor (* sample-rate duration))
          sound-data (love.sound.newSoundData sample-count sample-rate 16 1)]
      (for [i 0 (- sample-count 1)]
        (let [t (/ i sample-rate)
              sample (* 0.3 (math.sin (* 2 math.pi frequency t)))]
          (sound-data:setSample i sample)))
      (set catch-source (love.audio.newSource sound-data "static"))))
  (: catch-source :stop)
  (: catch-source :play))

{:play-catch play-catch}
