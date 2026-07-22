(local world-mod (require :world))
(local systems (require :systems))
(local ui (require :ui))
(local audio (require :audio))

(var game nil)
(var state nil)

(fn reset-game! []
  (math.randomseed (os.time))
  (set game (world-mod.create-game-world))
  (set state (systems.initial-state game)))

(fn love.load []
  (reset-game!))

(fn love.update [dt]
  (systems.step game state dt audio.play-catch))

(fn love.draw []
  (ui.render game))

(fn love.keypressed [key]
  (when (= key "escape")
    (love.event.quit)))
