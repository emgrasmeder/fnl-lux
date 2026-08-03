(local BOB-AMPLITUDE 2)

(fn bob-offset [phase]
  (* BOB-AMPLITUDE (math.sin (or phase 0))))

(fn render-creep! [x y radius phase]
  (love.graphics.setColor 0.85 0.2 0.25 1)
  (love.graphics.circle "fill" x (+ y (bob-offset phase)) radius))

{:BOB-AMPLITUDE BOB-AMPLITUDE
 :bob-offset bob-offset
 :render-creep! render-creep!}
