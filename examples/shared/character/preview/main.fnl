(local character-render (require :shared.character.render))
(local walk (require :shared.character.walk))

(local FIGURE-H 36)
(local FEET-PAD 10)
(local MOVE-SPEED 220)
(local WALK-STEP-PX 12)
(local WALK-VX-EPSILON 5)

(var walk-state nil)

(fn key-held? [key]
  (let [is-down (when (and _G.love _G.love.keyboard)
                   (. _G.love.keyboard :isDown))]
    (and is-down (is-down key))))

(fn horizontal-vx []
  (var vx 0)
  (when (or (key-held? "left") (key-held? "a"))
    (set vx (- vx MOVE-SPEED)))
  (when (or (key-held? "right") (key-held? "d"))
    (set vx (+ vx MOVE-SPEED)))
  vx)

(fn love.load []
  (love.graphics.setDefaultFilter "nearest" "nearest")
  (set walk-state (walk.initial-walk-state)))

(fn love.update [dt]
  (set walk-state (walk.advance-walk-state walk-state (horizontal-vx) true dt
                                           WALK-STEP-PX WALK-VX-EPSILON)))

(fn love.draw []
  (let [w (love.graphics.getWidth)
        h (love.graphics.getHeight)
        feet-x (/ w 2)
        feet-y (- h FEET-PAD)
        vx (horizontal-vx)
        move-sign (if (> (math.abs vx) WALK-VX-EPSILON)
                      (walk.sign vx)
                      (. walk-state :last-sign))
        phase (. walk-state :phase)]
    (love.graphics.clear 0.08 0.08 0.1 1)
    (love.graphics.setColor 1 1 1 1)
    (character-render.render-stick-figure feet-x feet-y FIGURE-H phase move-sign)
    (love.graphics.setColor 0.75 0.75 0.8 1)
    (love.graphics.print "A/D or arrows: walk   Esc: quit" 8 8)))

(fn love.keypressed [key]
  (when (= key "escape")
    (love.event.quit)))
