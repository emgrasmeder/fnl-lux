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

(fn make-lazy-player [duration frequency]
  (var source nil)
  (fn []
    (when (not source)
      (set source (make-tone duration frequency)))
    (play-source source)))

{:make-tone make-tone
 :play-source play-source
 :make-lazy-player make-lazy-player}
