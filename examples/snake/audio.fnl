(var eat-source nil)
(var death-source nil)

(fn make-tone [duration frequency]
  (let [sample-rate 44100
        sample-count (math.floor (* sample-rate duration))
        sound-data (love.sound.newSoundData sample-count sample-rate 16 1)]
    (for [i 0 (- sample-count 1)]
      (let [t (/ i sample-rate)
            sample (* 0.3 (math.sin (* 2 math.pi frequency t)))]
        (sound-data:setSample i sample)))
    (love.audio.newSource sound-data "static")))

(fn play-source [source-ref]
  (when source-ref
    (: source-ref :stop)
    (: source-ref :play)))

(fn play-eat []
  (when (not eat-source)
    (set eat-source (make-tone 0.12 880)))
  (play-source eat-source))

(fn play-death []
  (when (not death-source)
    (set death-source (make-tone 0.6 180)))
  (play-source death-source))

{:play-eat play-eat
 :play-death play-death}
