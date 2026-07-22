(local audio-shared (require :shared.audio))

(local play-eat (audio-shared.make-lazy-player 0.12 880))
(local play-death (audio-shared.make-lazy-player 0.6 180))

{:play-eat play-eat
 :play-death play-death}
