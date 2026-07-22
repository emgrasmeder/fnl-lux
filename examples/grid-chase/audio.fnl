(local audio-shared (require :shared.audio))

(local play-catch (audio-shared.make-lazy-player 0.2 523))

{:play-catch play-catch}
