(local world-mod (require :world))
(local systems (require :systems))
(local ui (require :ui))
(local audio (require :audio))

(var menu nil)
(var state {:focused-index 1})

(fn action-callbacks []
  {:play audio.play-beep
   :exit (fn [] (love.event.quit))})

(fn love.load []
  (set menu (world-mod.create-menu-world))
  (set state {:focused-index 1}))

(fn love.draw []
  (ui.render-menu menu state.focused-index))

(fn love.mousepressed [mx my button]
  (when (= button 1)
    (systems.handle-click menu (action-callbacks) mx my)))

(fn love.keypressed [key]
  (systems.handle-key menu state (action-callbacks) key))
