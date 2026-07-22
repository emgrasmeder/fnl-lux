(local audio-shared (require :shared.audio))

(local play-beep (audio-shared.make-lazy-player 0.15 440))

{:play-beep play-beep}
