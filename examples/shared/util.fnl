(fn shuffle! [list]
  (for [i (# list) 2 -1]
    (let [j (math.random i)]
      (let [tmp (. list i)]
        (tset list i (. list j))
        (tset list j tmp))))
  list)

(fn positions-equal? [a b]
  (and a b (= (. a :row) (. b :row)) (= (. a :col) (. b :col))))

(fn point-in-rect? [mx my x y w h]
  (and (>= mx x) (< mx (+ x w))
       (>= my y) (< my (+ y h))))

{:shuffle! shuffle!
 :positions-equal? positions-equal?
 :point-in-rect? point-in-rect?}
