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
  (systems.step game state dt audio.play-eat audio.play-death))

(fn love.draw []
  (ui.render game state))

(fn love.keypressed [key]
  (case key
    "escape" (systems.toggle-pause state)
    "r" (reset-game!)
    _ (systems.apply-direction state (systems.direction-for-key key))))
