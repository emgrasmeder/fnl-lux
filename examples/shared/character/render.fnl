(local walk (require :shared.character.walk))

(fn render-stick-figure [feet-x feet-y height phase move-sign]
  (let [leg-len (* height 0.22)
        body-len (* height 0.28)
        arm-len (* height 0.2)
        head-r (* height 0.12)
        shoulder-y (- (. (walk.foot-positions feet-x feet-y height phase move-sign) :hip-y) body-len)
        head-cy (- shoulder-y head-r)
        arm-spread (* arm-len 0.85)
        feet (walk.foot-positions feet-x feet-y height phase move-sign)
        hip-y (. feet :hip-y)
        [left-x left-y] (. feet :left)
        [right-x right-y] (. feet :right)]
    (love.graphics.line left-x left-y feet-x hip-y)
    (love.graphics.line right-x right-y feet-x hip-y)
    (love.graphics.line feet-x hip-y feet-x shoulder-y)
    (love.graphics.line feet-x shoulder-y (- feet-x arm-spread) (+ shoulder-y (* body-len 0.35)))
    (love.graphics.line feet-x shoulder-y (+ feet-x arm-spread) (+ shoulder-y (* body-len 0.35)))
    (love.graphics.circle "line" feet-x head-cy head-r)))

{:render-stick-figure render-stick-figure}
